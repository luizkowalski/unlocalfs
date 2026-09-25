import Foundation
import Testing
import UnlocalFSCore

@Suite(.enabled(if: ProcessInfo.processInfo.environment["UNLOCALFS_TEST_KEYCHAIN"] == "1", "Set UNLOCALFS_TEST_KEYCHAIN=1 to run"))
struct KeychainTests {
    @Test func credentialsCanBeSavedUpdatedReadAndDeleted() throws {
        let keychain = Keychain(service: "app.unlocalfs.tests.\(UUID().uuidString)")
        let id = UUID()
        defer { try? keychain.delete(id) }
        #expect(try keychain.read(id) == nil)
        try keychain.save(Credentials(accessKey: "test-key", secretKey: "first-secret"), for: id)
        let updated = Credentials(accessKey: "test-key", secretKey: "new-secret", sessionToken: "test-session")
        try keychain.save(updated, for: id)
        #expect(try keychain.read(id) == updated)
        try keychain.delete(id)
        #expect(try keychain.read(id) == nil)
    }
}
