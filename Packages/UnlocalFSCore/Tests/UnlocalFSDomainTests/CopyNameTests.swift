import Testing
import UnlocalFSDomain

@Suite struct CopyNameTests {
    @Test(arguments: [
        ("report.pdf", 1, "report copy.pdf"),
        ("report.pdf", 2, "report copy 2.pdf"),
        ("archive.tar.gz", 1, "archive.tar copy.gz"),
        (".env", 1, ".env copy"),
        ("README", 3, "README copy 3")
    ])
    func copyNameSplitsOffOnlyTheLastExtension(original: String, attempt: Int, expected: String) {
        #expect(CopyName(of: original).attempt(attempt) == expected)
    }
}
