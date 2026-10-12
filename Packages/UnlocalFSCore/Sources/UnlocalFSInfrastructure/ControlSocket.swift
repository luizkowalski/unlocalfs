import Darwin
import Foundation
import UnlocalFSDomain

enum ControlSocket {
    static func post(_ socket: URL, _ method: String, body: Data, timeout: Duration) async throws -> Data {
        let request = request(method, body: body)
        let deadline = ContinuousClock.now + timeout
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(with: Result {
                    let connection = try UnixConnection(to: socket.path, deadline: deadline)
                    defer { connection.close() }
                    try connection.send(request)
                    return try replyBody(of: connection.readToEnd())
                })
            }
        }
    }

    private static func request(_ method: String, body: Data) -> Data {
        let head = [
            "POST /\(method) HTTP/1.0",
            "Host: localhost",
            "Content-Type: application/json",
            "Content-Length: \(body.count)",
            "", "",
        ].joined(separator: "\r\n")
        return Data(head.utf8) + body
    }

    private static func replyBody(of reply: Data) throws -> Data {
        guard let headEnd = reply.firstRange(of: Data("\r\n\r\n".utf8)) else { throw AppError(String(localized: .commandFailed)) }
        let statusLine = String(decoding: reply[..<headEnd.lowerBound], as: UTF8.self).prefix { $0 != "\r" }
        let body = Data(reply[headEnd.upperBound...])
        guard statusLine.split(separator: " ").dropFirst().first == "200" else { throw rcloneError(in: body) }
        return body
    }

    private static func rcloneError(in body: Data) -> AppError {
        let message = (try? JSONDecoder().decode(RcloneError.self, from: body))?.error
        return AppError(message ?? String(localized: .commandFailed))
    }
}

private struct RcloneError: Decodable {
    let error: String
}

private struct UnixConnection {
    private let descriptor: Int32
    private let deadline: ContinuousClock.Instant

    init(to path: String, deadline: ContinuousClock.Instant) throws {
        var address = sockaddr_un()
        let pathBytes = Array(path.utf8)
        guard pathBytes.count < MemoryLayout.size(ofValue: address.sun_path) else { throw Self.error(ENAMETOOLONG) }
        address.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: pathBytes) }

        descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw Self.error(errno) }
        self.deadline = deadline
        setOption(SO_NOSIGPIPE, Int32(1))

        do {
            try limit(SO_SNDTIMEO)
            let result = withUnsafePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
            }
            guard result == 0 else { throw Self.error(errno) }
        } catch {
            close()
            throw error
        }
    }

    func send(_ data: Data) throws {
        var sent = 0
        while sent < data.count {
            try limit(SO_SNDTIMEO)
            let count = data[sent...].withUnsafeBytes { write(descriptor, $0.baseAddress, $0.count) }
            guard count > 0 else { throw Self.error(errno) }
            sent += count
        }
    }

    func readToEnd() throws -> Data {
        var received = Data()
        var buffer = [UInt8](repeating: 0, count: 1 << 16)
        while true {
            try limit(SO_RCVTIMEO)
            let count = read(descriptor, &buffer, buffer.count)
            if count == 0 { return received }
            guard count > 0 else { throw Self.error(errno) }
            received.append(contentsOf: buffer[..<count])
        }
    }

    func close() { Darwin.close(descriptor) }

    private func limit(_ option: Int32) throws {
        let left = deadline - .now
        guard left > .zero else { throw Self.timedOut }
        let microseconds = max(1, Int((left / .microseconds(1)).rounded(.up)))
        setOption(option, timeval(tv_sec: microseconds / 1_000_000, tv_usec: Int32(microseconds % 1_000_000)))
    }

    private func setOption(_ option: Int32, _ value: some BitwiseCopyable) {
        withUnsafeBytes(of: value) { _ = setsockopt(descriptor, SOL_SOCKET, option, $0.baseAddress, socklen_t($0.count)) }
    }

    private static var timedOut: AppError { AppError(String(localized: .commandTimedOut)) }

    private static func error(_ code: Int32) -> AppError {
        code == EAGAIN ? timedOut : AppError(String(cString: strerror(code)))
    }
}
