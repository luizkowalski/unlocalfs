#!/usr/bin/env swift
import CryptoKit
import Foundation

func run(_ executable: String, _ arguments: String...) throws {
    let process = try Process.run(URL(filePath: executable), arguments: arguments)
    process.waitUntilExit()
    if process.terminationStatus != 0 { exit(process.terminationStatus) }
}

let root = URL(filePath: CommandLine.arguments[0]).standardizedFileURL.deletingLastPathComponent().deletingLastPathComponent()
let project = try String(contentsOf: root.appending(path: "project.yml"), encoding: .utf8)
let version = project.firstMatch(of: #/RCLONE_VERSION: (\S+)/#)!.1
let checksum = project.firstMatch(of: #/RCLONE_SHA256_ARM64: (\S+)/#)!.1
let name = "rclone-v\(version)-osx-arm64"
let cache = root.appending(path: ".build/rclone/\(version)")
let binary = cache.appending(path: "\(name)/rclone")

if !FileManager.default.isExecutableFile(atPath: binary.path) {
    try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
    let archive = cache.appending(path: "\(name).zip")
    try run("/usr/bin/curl", "-fsSL", "--retry", "3", "--retry-all-errors", "https://github.com/rclone/rclone/releases/download/v\(version)/\(name).zip", "-o", archive.path)
    let digest = try SHA256.hash(data: Data(contentsOf: archive)).map { String(format: "%02x", $0) }.joined()
    guard digest == checksum else {
        FileHandle.standardError.write(Data("Checksum mismatch for \(archive.path)\n".utf8))
        exit(1)
    }
    try run("/usr/bin/ditto", "-x", "-k", archive.path, cache.path)
    try FileManager.default.removeItem(at: archive)
}

print(binary.path)
