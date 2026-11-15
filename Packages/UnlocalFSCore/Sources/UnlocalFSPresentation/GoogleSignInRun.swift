import Observation
import UnlocalFSDomain

@MainActor @Observable final class GoogleSignInRun {
    private var task: Task<String, any Error>?
    private let drives: any DriveGateway

    init(drives: any DriveGateway) {
        self.drives = drives
    }

    var isRunning: Bool { task != nil }

    func token() async -> Result<String, any Error>? {
        guard task == nil else { return nil }
        let task = Task { [drives] in try await drives.signInWithGoogle() }
        self.task = task
        let result = await task.result
        guard self.task == task else { return nil }
        self.task = nil
        return result
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
