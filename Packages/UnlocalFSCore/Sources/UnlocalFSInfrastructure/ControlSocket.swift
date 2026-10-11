import Darwin
import Foundation
import UnlocalFSDomain

enum ControlSocket {
    static func post(_ socket: URL, _ method: String, body: Data, timeout: Duration) async throws -> Data {
        let head = [
            "POST /\(method) HTTP/1.1",
            "Host: localhost",
            "Content-Type: application/json",
            "Content-Length: \(body.count)",
            "", ""
        ].joined(separator: "\r\n")
        let request = Data(head.utf8) + body
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(with: Result {
                    let descriptor = try openConnection(to: socket.path, timeout: timeout)
                    defer { close(descriptor) }
                    try sendAll(request, to: descriptor)
                    return try readReply(from: descriptor)
                })
            }
        }
    }

    private static func openConnection(to path: String, timeout: Duration) throws -> Int32 {
        var address = sockaddr_un()
        let pathBytes = Array(path.utf8)
        guard pathBytes.count < MemoryLayout.size(ofValue: address.sun_path) else { throw posixError(ENAMETOOLONG) }
        address.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: pathBytes) }

        let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw posixError(errno) }
        var wait = timeval(tv_sec: Int(timeout.components.seconds), tv_usec: 0)
        var noSignal: Int32 = 1
        setsockopt(descriptor, SOL_SOCKET, SO_RCVTIMEO, &wait, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(descriptor, SOL_SOCKET, SO_SNDTIMEO, &wait, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, socklen_t(MemoryLayout<Int32>.size))

        let result = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
        }
        guard result == 0 else {
            let error = posixError(errno)
            close(descriptor)
            throw error
        }
        return descriptor
    }

    private static func sendAll(_ data: Data, to descriptor: Int32) throws {
        var sent = 0
        while sent < data.count {
            let count = data[sent...].withUnsafeBytes { write(descriptor, $0.baseAddress, $0.count) }
            guard count > 0 else { throw posixError(errno) }
            sent += count
        }
    }

    private static func readReply(from descriptor: Int32) throws -> Data {
        var received = Data()
        var buffer = [UInt8](repeating: 0, count: 1 << 16)
        while true {
            if let reply = HTTPReply(parsing: received) {
                guard reply.status == 200 else { throw rcloneError(in: reply.body) }
                return reply.body
            }
            let count = read(descriptor, &buffer, buffer.count)
            guard count > 0 else { throw count == 0 ? AppError(String(localized: .commandFailed)) : posixError(errno) }
            received.append(contentsOf: buffer[..<count])
        }
    }

    private static func rcloneError(in body: Data) -> AppError {
        let message = (try? JSONDecoder().decode(RcloneError.self, from: body))?.error
        return AppError(message ?? String(localized: .commandFailed))
    }

    private static func posixError(_ code: Int32) -> AppError {
        code == EAGAIN ? AppError(String(localized: .commandTimedOut)) : AppError(String(cString: strerror(code)))
    }
}

private struct HTTPReply {
    private static let lineBreak = Data("\r\n".utf8)
    private static let headEnd = Data("\r\n\r\n".utf8)

    let status: Int
    let body: Data

    init?(parsing data: Data) {
        guard let headEnd = data.firstRange(of: Self.headEnd) else { return nil }
        let lines = String(decoding: data[..<headEnd.lowerBound], as: UTF8.self).components(separatedBy: "\r\n")
        let headers = Self.headers(in: lines.dropFirst())
        let content = data[headEnd.upperBound...]

        guard let status = lines.first?.split(separator: " ").dropFirst().first.flatMap({ Int($0) }) else { return nil }
        if let length = headers["content-length"].flatMap({ Int($0) }) {
            guard content.count >= length else { return nil }
            body = Data(content.prefix(length))
        } else if headers["transfer-encoding"]?.lowercased() == "chunked", let joined = Self.joinChunks(content) {
            body = joined
        } else {
            return nil
        }
        self.status = status
    }

    private static func headers(in lines: ArraySlice<String>) -> [String: String] {
        var headers: [String: String] = [:]
        for line in lines {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let name = line[..<colon].lowercased()
            headers[name] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }
        return headers
    }

    private static func joinChunks(_ content: Data) -> Data? {
        var body = Data()
        var rest = content[...]
        while let sizeEnd = rest.firstRange(of: lineBreak) {
            guard let size = Int(String(decoding: rest[..<sizeEnd.lowerBound], as: UTF8.self), radix: 16) else { return nil }
            if size == 0 { return body }
            let chunkStart = sizeEnd.upperBound
            guard rest.distance(from: chunkStart, to: rest.endIndex) >= size + lineBreak.count else { return nil }
            let chunkEnd = rest.index(chunkStart, offsetBy: size)
            body += rest[chunkStart..<chunkEnd]
            rest = rest[rest.index(chunkEnd, offsetBy: lineBreak.count)...]
        }
        return nil
    }
}

private struct RcloneError: Decodable {
    let error: String
}
