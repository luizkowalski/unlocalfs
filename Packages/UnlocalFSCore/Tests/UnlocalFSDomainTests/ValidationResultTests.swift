import Testing
import UnlocalFSDomain

@Suite struct ValidationResultTests {
    @Test func validResultsAllowTheCallerToContinue() throws {
        let result = ArticleDraft(title: "News", wordCount: 100).validate()
        #expect(result.isValid)
        #expect(result.issues.isEmpty)
        #expect(result.fieldErrors.isEmpty)
        try result.requireValid()
    }

    @Test func anotherModelReportsItsOwnFieldsAndFirstMessages() {
        let result = ArticleDraft(title: "", wordCount: 0).validate()
        #expect(!result.isValid)
        #expect(result.issues == [
            .init(field: .title, message: "Title is required"),
            .init(field: .title, message: "Title needs at least three characters"),
            .init(field: .body, message: "Body needs words")
        ])
        #expect(result.fieldErrors == [.title: "Title is required", .body: "Body needs words"])
    }

    @Test func invalidResultsThrowAllMessagesInOrder() {
        let result = ArticleDraft(title: "", wordCount: 0).validate()
        #expect { try result.requireValid() } throws: { error in
            (error as? AppError)?.errorDescription == "Title is required\nTitle needs at least three characters\nBody needs words"
        }
    }
}

private enum ArticleField: Hashable, Sendable {
    case title, body
}

private struct ArticleDraft {
    let title: String
    let wordCount: Int

    func validate() -> ValidationResult<ArticleField> {
        var result = ValidationResult<ArticleField>()
        result.check(!title.isEmpty, field: .title, message: "Title is required")
        result.check(title.count >= 3, field: .title, message: "Title needs at least three characters")
        result.check(wordCount > 0, field: .body, message: "Body needs words")
        return result
    }
}
