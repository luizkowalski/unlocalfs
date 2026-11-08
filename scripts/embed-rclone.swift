import Foundation

let environment = ProcessInfo.processInfo.environment
let fetch = Process()
let output = Pipe()
fetch.executableURL = URL(filePath: environment["PROJECT_DIR"]!).appending(path: "scripts/fetch-rclone.swift")
fetch.standardOutput = output
try fetch.run()
let rclone = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).trimmingCharacters(in: .newlines)
fetch.waitUntilExit()
if fetch.terminationStatus != 0 { exit(fetch.terminationStatus) }

let helpers = URL(filePath: environment["TARGET_BUILD_DIR"]!).appending(path: environment["CONTENTS_FOLDER_PATH"]!).appending(path: "Helpers")
let helper = helpers.appending(path: "rclone")
try FileManager.default.createDirectory(at: helpers, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: helper)
try FileManager.default.copyItem(at: URL(filePath: rclone), to: helper)

let identity = environment["EXPANDED_CODE_SIGN_IDENTITY"]!
let timestamp = identity == "-" ? [] : ["--timestamp"]
let sign = try Process.run(URL(filePath: "/usr/bin/codesign"), arguments: ["--force", "--sign", identity, "--options", "runtime"] + timestamp + [helper.path])
sign.waitUntilExit()
exit(sign.terminationStatus)
