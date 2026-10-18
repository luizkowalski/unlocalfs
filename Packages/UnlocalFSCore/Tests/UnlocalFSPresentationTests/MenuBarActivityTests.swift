import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite struct MenuBarActivityTests {
    @Test func menuBarShowsUploadsBeforeDownloads() async throws {
        let fixture = try ViewModelFixture()
        defer { fixture.remove() }
        let connection = Connection.s3()
        try fixture.serve(connection, queued: 1, downloading: true)
        let app = fixture.app()

        await app.refresh()
        #expect(app.activity == .uploading)

        try fixture.serve(connection, downloading: true)
        await app.refresh()
        #expect(app.activity == .downloading)

        try fixture.serve(connection)
        await app.refresh()
        #expect(app.activity == .idle)
    }
}
