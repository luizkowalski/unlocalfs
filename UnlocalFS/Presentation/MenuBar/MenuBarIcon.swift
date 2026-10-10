import AppKit
import SwiftUI
import UnlocalFSPresentation

struct MenuBarIcon: View {
    let activity: AppViewModel.Activity
    @State private var angle = 0.0

    var body: some View {
        Image(nsImage: image)
            .accessibilityLabel("UnlocalFS")
            .task(id: activity) {
                guard activity == .syncing else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(80))
                    angle -= 30
                }
            }
    }

    private var image: NSImage {
        switch activity {
        case .idle: Self.drive(badge: .labelColor, template: true)
        case .connected: Self.drive(badge: .systemGreen, template: false)
        case .syncing: Self.drive(overlay: "arrow.triangle.2.circlepath", color: .systemYellow, angle: angle)
        case .downloading: Self.drive(overlay: "arrow.down", color: .systemBlue)
        }
    }

    private static func drive(badge: NSColor, template: Bool) -> NSImage {
        let image = NSImage(systemSymbolName: "externaldrive.badge.icloud", accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: 16, weight: .regular).applying(.init(paletteColors: [badge, .labelColor])))!
        image.isTemplate = template
        return image
    }

    private static func drive(overlay symbol: String, color: NSColor, angle: Double = 0) -> NSImage {
        let drive = drive(badge: .clear, template: false)
        let overlay = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: 7.5, weight: .bold).applying(.init(paletteColors: [color])))!
        return NSImage(size: drive.size, flipped: false) { rect in
            drive.draw(in: rect)
            let rotation = NSAffineTransform()
            rotation.translateX(by: 6.2, yBy: 6.25)
            rotation.rotate(byDegrees: angle)
            rotation.concat()
            overlay.draw(in: NSRect(x: -overlay.size.width / 2, y: -overlay.size.height / 2, width: overlay.size.width, height: overlay.size.height))
            return true
        }
    }
}
