import Foundation
import UnlocalFSDomain
import Subprocess
import System

public enum Command {
    public static func run(
        _ executable: URL, _ arguments: [String], input: String = "", environment: [String: String]? = nil, timeout: Duration = .seconds(30)
    ) async throws -> Data {
        try await withThrowingTaskGroup { group in
            group.addTask { try await execute(executable, arguments, input: input, environment: environment) }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw AppError("The command timed out. Try again.")
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    private static func execute(_ executable: URL, _ arguments: [String], input: String, environment: [String: String]?) async throws -> Data {
        var options = PlatformOptions()
        options.teardownSequence = [.gracefulShutDown(allowedDurationToNextStep: .seconds(1))]
        let result = try await Subprocess.run(
            .path(FilePath(executable.path)),
            arguments: Arguments(arguments),
            environment: environment.map { .custom(Dictionary(uniqueKeysWithValues: $0.map { (Environment.Key(stringLiteral: $0), $1) })) } ?? .inherit,
            platformOptions: options,
            input: .string(input),
            output: .data(limit: 1 << 20),
            error: .combinedWithOutput
        )
        guard result.terminationStatus.isSuccess else {
            let message = String(decoding: result.standardOutput, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            throw AppError(message.isEmpty ? "The command failed. Try again." : message)
        }
        return result.standardOutput
    }
}
