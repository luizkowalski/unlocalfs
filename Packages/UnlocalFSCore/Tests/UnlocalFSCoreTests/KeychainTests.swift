import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@Suite
struct KeychainTests {
    @Test func credentialsCanBeSavedUpdatedReadAndDeleted() throws {
        let keychain = Keychain(service: "app.unlocalfs.tests.\(UUID().uuidString)")
        let id = UUID()
        defer { try? keychain.delete(id) }
        #expect(try keychain.read(id) == nil)
        try keychain.save(Credentials(accessKey: "test-key", secretKey: "first-secret"), for: id)
        var updated = Credentials(accessKey: "test-key", secretKey: "new-secret", sessionToken: "test-session", encryptionPassword: "test-password")
        updated.obscuredEncryptionPassword = "obscured-password"
        try keychain.save(updated, for: id)
        #expect(try keychain.read(id) == updated)
        try keychain.delete(id)
        #expect(try keychain.read(id) == nil)
    }
}
