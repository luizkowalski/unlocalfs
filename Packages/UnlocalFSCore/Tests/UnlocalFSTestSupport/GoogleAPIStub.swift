import Foundation

public let driveAccounts = ["ya29.saved-access": "account-1", "ya29.new": "account-1", "ya29.other-account": "account-2"]

public let otherAccountTokenJSON = #"{"access_token":"ya29.other-account","token_type":"Bearer","refresh_token":"1//other-refresh","expiry":"2026-11-12T02:00:00Z"}"#

public enum GoogleAPIStub {
    private static let installed: Void = { URLProtocol.registerClass(DriveAboutProtocol.self) }()

    public static func install() { _ = installed }
}

private final class DriveAboutProtocol: URLProtocol {
    override static func canInit(with request: URLRequest) -> Bool { request.url?.host == "www.googleapis.com" }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let token = request.value(forHTTPHeaderField: "Authorization")?.replacingOccurrences(of: "Bearer ", with: "") ?? ""
        let account = driveAccounts[token]
        let body = account.map { #"{"user":{"permissionId":"\#($0)"}}"# } ?? #"{"error":{"code":401}}"#
        let response = HTTPURLResponse(url: request.url!, statusCode: account == nil ? 401 : 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
