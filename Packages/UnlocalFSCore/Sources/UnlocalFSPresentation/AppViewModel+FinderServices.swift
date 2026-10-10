import Foundation
import UnlocalFSDomain

extension AppViewModel {
    public func copyShareLinks(for files: [URL], expiry: ShareLinkExpiry) async {
        do {
            let links = try await shareFiles.execute(files, expiry: expiry)
            desktop.copyShareLinks(links)
            desktop.notify(
                title: String(localized: .linksCopied(links.count)),
                body: String(localized: .anyoneCanDownload(expiry.title)), fallbackToAlert: false
            )
        } catch let error as FileActionError {
            desktop.notify(title: String(localized: .couldNotCopyLink(error.file.lastPathComponent)), body: error.localizedDescription, fallbackToAlert: true)
        } catch {
            desktop.notify(title: String(localized: .couldNotCopyShareLinks), body: error.localizedDescription, fallbackToAlert: true)
        }
    }

    public func duplicateOnServer(_ files: [URL]) async {
        do {
            let copies = try await duplicateFiles.execute(files)
            desktop.notify(
                title: String(localized: .filesDuplicated(copies.count)),
                body: ListFormatter.localizedString(byJoining: copies.map { ($0 as NSString).lastPathComponent }), fallbackToAlert: false
            )
        } catch let error as FileActionError {
            desktop.notify(title: String(localized: .couldNotDuplicate(error.file.lastPathComponent)), body: error.localizedDescription, fallbackToAlert: true)
        } catch {
            desktop.notify(title: String(localized: .couldNotDuplicateFiles), body: error.localizedDescription, fallbackToAlert: true)
        }
    }
}
