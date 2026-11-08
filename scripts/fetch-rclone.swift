#!/usr/bin/env swift
import CryptoKit
import Foundation

struct FetchError: Error, CustomStringConvertible {
    let description: String
}

func run(_ executable: String, _ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = FileHandle.standardError
    try process.run()
    process.waitUntilExit()
    if process.terminationStatus != 0 {
        exit(process.terminationStatus)
    }
}

do {
    let files = FileManager.default
    let root = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
        .deletingLastPathComponent().deletingLastPathComponent()
    let project = try String(contentsOf: root.appending(path: "project.yml"), encoding: .utf8)

    func setting(_ key: String) throws -> String {
        for line in project.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, parts[0] == key, let value = parts[1].split(whereSeparator: \.isWhitespace).first {
                return String(value)
            }
        }
        throw FetchError(description: "Missing \(key) in project.yml")
    }

    let version = try setting("RCLONE_VERSION")
    let checksum = try setting("RCLONE_SHA256_ARM64")
    let name = "rclone-v\(version)-osx-arm64"
    let cache = root.appending(path: ".build/rclone/\(version)")
    let binary = cache.appending(path: "\(name)/rclone")

    if !files.isExecutableFile(atPath: binary.path) {
        try files.createDirectory(at: cache, withIntermediateDirectories: true)
        let archive = cache.appending(path: "\(name).zip")
        try run("/usr/bin/curl", [
            "-fsSL", "--retry", "3", "--retry-all-errors",
            "https://github.com/rclone/rclone/releases/download/v\(version)/\(name).zip", "-o", archive.path,
        ])
        let digest = try SHA256.hash(data: Data(contentsOf: archive)).map { String(format: "%02x", $0) }.joined()
        guard digest == checksum else {
            throw FetchError(description: "Checksum mismatch for \(archive.path)")
        }
        try run("/usr/bin/ditto", ["-x", "-k", archive.path, cache.path])
        try files.removeItem(at: archive)
    }

    print(binary.path)
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(1)
}
