import Darwin
import Foundation
import UnlocalFSDomain

enum ControlSocket {
    static func post(_ socket: URL, _ method: String, body: Data, timeout: Duration) async throws -> Data {
        let request = Data("POST /\(method) HTTP/1.1\r\nHost: localhost\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\n\r\n".utf8) + body
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(with: Result { try exchange(socket.path, request, timeout: timeout) })
            }
        }
    }

    private static func exchange(_ path: String, _ request: Data, timeout: Duration) throws -> Data {
        var address = sockaddr_un()
        let bytes = Array(path.utf8)
        guard bytes.count < MemoryLayout.size(ofValue: address.sun_path) else { throw failure(ENAMETOOLONG) }
        address.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: bytes) }
        let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw failure(errno) }
        defer { close(descriptor) }
        var wait = timeval(tv_sec: Int(timeout.components.seconds), tv_usec: 0)
        var noSignal: Int32 = 1
        setsockopt(descriptor, SOL_SOCKET, SO_RCVTIMEO, &wait, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(descriptor, SOL_SOCKET, SO_SNDTIMEO, &wait, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, socklen_t(MemoryLayout<Int32>.size))
        let connected = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
        }
        guard connected == 0 else { throw failure(errno) }
        var sent = 0
        while sent < request.count {
            let count = request[sent...].withUnsafeBytes { write(descriptor, $0.baseAddress, $0.count) }
            guard count > 0 else { throw failure(errno) }
            sent += count
        }
        var received = Data()
        var buffer = [UInt8](repeating: 0, count: 1 << 16)
        while true {
            if let body = try reply(in: received) { return body }
            let count = read(descriptor, &buffer, buffer.count)
            guard count > 0 else { throw count == 0 ? AppError(String(localized: .commandFailed)) : failure(errno) }
            received.append(contentsOf: buffer[..<count])
        }
    }

    private static func reply(in data: Data) throws -> Data? {
        guard let headerEnd = data.firstRange(of: Data("\r\n\r\n".utf8)) else { return nil }
        let lines = String(decoding: data[..<headerEnd.lowerBound], as: UTF8.self).components(separatedBy: "\r\n")
        let headers = Dictionary(lines.dropFirst().compactMap { line -> (String, String)? in
            guard let colon = line.firstIndex(of: ":") else { return nil }
            return (line[..<colon].lowercased(), line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces))
        }) { _, last in last }
        let content = data[headerEnd.upperBound...]
        let body: Data
        if let length = headers["content-length"].flatMap({ Int($0) }) {
            guard content.count >= length else { return nil }
            body = Data(content.prefix(length))
        } else if headers["transfer-encoding"]?.lowercased() == "chunked", let chunks = chunks(content) {
            body = chunks
        } else {
            return nil
        }
        guard lines.first?.split(separator: " ").dropFirst().first == "200" else {
            let message = (try? JSONDecoder().decode(ControlError.self, from: body))?.error
            throw AppError(message ?? String(localized: .commandFailed))
        }
        return body
    }

    private static func chunks(_ content: Data) -> Data? {
        var body = Data()
        var rest = content[...]
        while let lineEnd = rest.firstRange(of: Data("\r\n".utf8)) {
            guard let size = Int(String(decoding: rest[..<lineEnd.lowerBound], as: UTF8.self), radix: 16) else { return nil }
            if size == 0 { return body }
            guard rest.distance(from: lineEnd.upperBound, to: rest.endIndex) >= size + 2 else { return nil }
            let chunkEnd = rest.index(lineEnd.upperBound, offsetBy: size)
            body += rest[lineEnd.upperBound..<chunkEnd]
            rest = rest[rest.index(chunkEnd, offsetBy: 2)...]
        }
        return nil
    }

    private static func failure(_ code: Int32) -> AppError {
        code == EAGAIN ? AppError(String(localized: .commandTimedOut)) : AppError(String(cString: strerror(code)))
    }
}

private struct ControlError: Decodable {
    let error: String
}
