import Foundation
import Synchronization

public final class VersionedBucket: Sendable {
    private struct State {
        var objects: [String]
        var requests: [Data] = []
        var output = "{}"
    }

    private let state: Mutex<State>
    private let queue: String
    private let versioning: String

    public init(_ objects: [String], queue: String = "", versioning: String = "Enabled") {
        state = Mutex(State(objects: objects))
        self.versioning = versioning
        self.queue = queue.isEmpty ? "" : #"{"name":"\#(queue)","id":1,"size":3,"expiry":1,"tries":0,"uploading":false}"#
    }

    public var requests: [[String: Any]] {
        state.withLock { $0.requests }.map { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] ?? [:] }
    }

    public var respond: ControlServer.Respond {
        { [self] request in
            let destination = request.parameter("dstRemote")
            return state.withLock { state in
                state.requests.append(request.body)
                switch request.method {
                case "operations/list":
                    let items = state.objects.map { #"{"Path":"\#($0)","Size":3,"ModTime":"2026-11-02T14:03:01.123000000Z","IsDir":false}"# }
                    state.output = #"{"list":[\#(items.joined(separator: ",")),{"Path":"sub","Size":-1,"ModTime":"2026-11-02T14:03:01Z","IsDir":true}]}"#
                    return #"{"jobid":1}"#
                case "operations/copyfile":
                    if let destination, !state.objects.contains(destination) { state.objects.append(destination) }
                    state.output = "{}"
                    return #"{"jobid":2}"#
                case "job/status":
                    return #"{"finished":true,"success":true,"error":"","output":\#(state.output)}"#
                case "vfs/queue":
                    return #"{"queue":[\#(queue)]}"#
                case "backend/command":
                    return #"{"result":"\#(versioning)"}"#
                case "operations/stat":
                    return #"{"item":null}"#
                default:
                    return "{}"
                }
            }
        }
    }
}
