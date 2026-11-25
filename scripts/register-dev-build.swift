#!/usr/bin/env swift
import Foundation

let environment = ProcessInfo.processInfo.environment
guard environment["CONFIGURATION"] == "Debug" else { exit(0) }

let pluginkit = "/usr/bin/pluginkit"
let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
let app = URL(fileURLWithPath: environment["TARGET_BUILD_DIR"]!)
    .appending(path: environment["FULL_PRODUCT_NAME"]!)
    .resolvingSymlinksInPath()
let finder = app.appending(path: "Contents/PlugIns/UnlocalFSFinder.appex")
let identifier = Bundle(url: finder)!.bundleIdentifier!

@discardableResult
func run(_ executable: String, _ arguments: String...) throws -> String {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = output
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return String(decoding: data, as: UTF8.self)
}

let registered = try run(pluginkit, "-m", "-A", "-D", "-v", "-i", identifier)
    .split(separator: "\n")
    .compactMap { $0.split(separator: "\t").last.map(String.init) }
    .filter { $0.hasSuffix(".appex") }
    .map { URL(fileURLWithPath: $0).resolvingSymlinksInPath() }

for copy in registered where copy != finder {
    try run(pluginkit, "-r", copy.path)
    try run(lsregister, "-u", copy.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path)
}

try run(lsregister, "-f", app.path)
try run(pluginkit, "-a", finder.path)
try run(pluginkit, "-e", "use", "-i", identifier)
