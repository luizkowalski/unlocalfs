import Darwin
import Foundation

public struct ControlRequest: Sendable {
    public let method: String
    public let body: Data

    public func parameter(_ name: String) -> String? {
        ((try? JSONSerialization.jsonObject(with: body)) as? [String: Any])?[name] as? String
    }
}

public struct ControlFailure: Error {
    let message: String

    public init(_ message: String) { self.message = message }
}

public final class ControlServer: Sendable {
    public typealias Respond = @Sendable (ControlRequest) async throws -> String
    private let source: any DispatchSourceRead

    public init(at socket: URL, respond: @escaping Respond) throws {
        var address = sockaddr_un()
        let path = Array(socket.path.utf8)
        guard path.count < MemoryLayout.size(ofValue: address.sun_path) else { throw POSIXError(.ENAMETOOLONG) }
        address.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: path) }
        unlink(socket.path)
        let listener = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(listener, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
        }
        guard bound == 0, listen(listener, 16) == 0 else {
            let error = POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            close(listener)
            throw error
        }
        source = DispatchSource.makeReadSource(fileDescriptor: listener, queue: DispatchQueue(label: "ControlServer"))
        source.setEventHandler {
            let client = accept(listener, nil, nil)
            guard client >= 0 else { return }
            var noSignal: Int32 = 1
            setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, socklen_t(MemoryLayout<Int32>.size))
            DispatchQueue.global().async {
                guard let request = Self.readRequest(client) else {
                    close(client)
                    return
                }
                Task {
                    let response = await Self.response(to: request, respond)
                    DispatchQueue.global().async { Self.finish(client, response) }
                }
            }
        }
        source.setCancelHandler { close(listener) }
        source.resume()
    }

    public func stop() { source.cancel() }

    private static func readRequest(_ client: Int32) -> ControlRequest? {
        var received = Data()
        var buffer = [UInt8](repeating: 0, count: 1 << 16)
        while true {
            if let request = request(in: received) { return request }
            let count = read(client, &buffer, buffer.count)
            guard count > 0 else { return nil }
            received.append(contentsOf: buffer[..<count])
        }
    }

    private static func request(in data: Data) -> ControlRequest? {
        guard let headerEnd = data.firstRange(of: Data("\r\n\r\n".utf8)) else { return nil }
        let lines = String(decoding: data[..<headerEnd.lowerBound], as: UTF8.self).components(separatedBy: "\r\n")
        let length = lines.first { $0.lowercased().hasPrefix("content-length:") }.flatMap { Int($0.dropFirst(15).trimmingCharacters(in: .whitespaces)) } ?? 0
        let body = data[headerEnd.upperBound...]
        guard body.count >= length, let target = lines.first?.split(separator: " ").dropFirst().first else { return nil }
        return ControlRequest(method: String(target.dropFirst()), body: Data(body.prefix(length)))
    }

    private static func response(to request: ControlRequest, _ respond: Respond) async -> [UInt8] {
        let status: String, body: String
        do {
            (status, body) = ("200 OK", try await respond(request))
        } catch {
            let message = (error as? ControlFailure)?.message ?? error.localizedDescription
            let json = try? JSONSerialization.data(withJSONObject: ["error": message, "status": 500])
            (status, body) = ("500 Internal Server Error", String(decoding: json ?? Data(), as: UTF8.self))
        }
        var response = Array("HTTP/1.1 \(status)\r\nContent-Type: application/json\r\nTransfer-Encoding: chunked\r\n\r\n".utf8)
        let bytes = Array(body.utf8)
        for start in stride(from: 0, to: bytes.count, by: 1024) {
            let chunk = bytes[start..<min(start + 1024, bytes.count)]
            response += Array("\(String(chunk.count, radix: 16))\r\n".utf8) + chunk + Array("\r\n".utf8)
        }
        return response + Array("0\r\n\r\n".utf8)
    }

    private static func finish(_ client: Int32, _ response: [UInt8]) {
        defer { close(client) }
        var sent = 0
        while sent < response.count {
            let count = response[sent...].withUnsafeBytes { write(client, $0.baseAddress, $0.count) }
            guard count > 0 else { return }
            sent += count
        }
        var buffer = [UInt8](repeating: 0, count: 1024)
        while read(client, &buffer, buffer.count) > 0 {}
    }
}
