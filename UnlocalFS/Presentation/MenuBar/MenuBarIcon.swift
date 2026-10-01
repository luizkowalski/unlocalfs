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
        case .syncing: Self.syncing(angle: angle)
        }
    }

    private static func drive(badge: NSColor, template: Bool) -> NSImage {
        let image = NSImage(systemSymbolName: "externaldrive.badge.icloud", accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: 16, weight: .regular).applying(.init(paletteColors: [badge, .labelColor])))!
        image.isTemplate = template
        return image
    }

    private static func syncing(angle: Double) -> NSImage {
        let drive = drive(badge: .clear, template: false)
        let arrows = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: 7.5, weight: .bold).applying(.init(paletteColors: [.systemYellow])))!
        return NSImage(size: drive.size, flipped: false) { rect in
            drive.draw(in: rect)
            let rotation = NSAffineTransform()
            rotation.translateX(by: 6.2, yBy: 6.25)
            rotation.rotate(byDegrees: angle)
            rotation.concat()
            arrows.draw(in: NSRect(x: -arrows.size.width / 2, y: -arrows.size.height / 2, width: arrows.size.width, height: arrows.size.height))
            return true
        }
    }
}
