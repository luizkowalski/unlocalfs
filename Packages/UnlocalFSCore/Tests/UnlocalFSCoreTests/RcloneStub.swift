import Foundation

func writeRcloneStub(_ script: String, to url: URL) throws {
    try "#!/bin/sh\nif [ \"$1\" = 'obscure' ]; then cat >/dev/null; fi\n\(script)".write(to: url, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
}
