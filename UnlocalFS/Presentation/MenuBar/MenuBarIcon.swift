import AppKit
import SwiftUI
import UnlocalFSPresentation

struct MenuBarIcon: View {
    let activity: AppViewModel.Activity
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var angle = 0.0

    var body: some View {
        Image(nsImage: image)
            .accessibilityLabel("UnlocalFS")
            .accessibilityValue(accessibilityValue)
            .task(id: animatesUploads) {
                guard animatesUploads else { return }
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(for: .milliseconds(250))
                    } catch { return }
                    angle -= 30
                }
            }
    }

    private var animatesUploads: Bool { activity == .uploading && !reduceMotion }

    private var image: NSImage {
        switch activity {
        case .idle: Self.drive("externaldrive.badge.icloud")
        case .connected: Self.drive("externaldrive.fill.badge.icloud")
        case .uploading: Self.drive(overlay: "arrow.triangle.2.circlepath", angle: angle)
        case .downloading: Self.drive(overlay: "arrow.down")
        }
    }

    private var accessibilityValue: Text {
        switch activity {
        case .idle: Text("No drives connected")
        case .connected: Text("Connected")
        case .uploading: Text("Uploading")
        case .downloading: Text("Downloading")
        }
    }

    private static func drive(_ symbol: String, badge: NSColor = .labelColor) -> NSImage {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: 16, weight: .regular).applying(.init(paletteColors: [badge, .labelColor])))!
        image.isTemplate = true
        return image
    }

    private static func drive(overlay symbol: String, angle: Double = 0) -> NSImage {
        let drive = drive("externaldrive.fill.badge.icloud", badge: .clear)
        let overlay = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: 7.5, weight: .bold))!
        let image = NSImage(size: drive.size, flipped: false) { rect in
            drive.draw(in: rect)
            let rotation = NSAffineTransform()
            rotation.translateX(by: 6.2, yBy: 6.25)
            rotation.rotate(byDegrees: angle)
            rotation.concat()
            overlay.draw(in: NSRect(x: -overlay.size.width / 2, y: -overlay.size.height / 2, width: overlay.size.width, height: overlay.size.height))
            return true
        }
        image.isTemplate = true
        return image
    }
}
