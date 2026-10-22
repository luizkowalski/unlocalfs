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
                        try await Task.sleep(for: .milliseconds(80))
                    } catch { return }
                    angle -= 30
                }
            }
    }

    private var animatesUploads: Bool { activity == .uploading && !reduceMotion }

    private var image: NSImage {
        switch activity {
        case .idle: Self.idleDrive
        case .connected: Self.connectedDrive
        case .uploading: Self.rotatingDrive(angle: angle)
        case .downloading: Self.downloadingDrive
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

    private static let idleDrive = drive(badge: .labelColor, template: true)
    private static let connectedDrive = drive(badge: .systemGreen, template: false)
    private static let downloadingDrive = drive(badge: .systemBlue, template: false)
    private static let rotatingDriveBase = drive(badge: .clear, template: false)
    private static let rotatingDriveOverlay = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)!
        .withSymbolConfiguration(.init(pointSize: 7.5, weight: .bold).applying(.init(paletteColors: [NSColor.systemYellow])))!

    private static func drive(badge: NSColor, template: Bool) -> NSImage {
        let image = NSImage(systemSymbolName: "externaldrive.badge.icloud", accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: 16, weight: .regular).applying(.init(paletteColors: [badge, .labelColor])))!
        image.isTemplate = template
        return image
    }

    private static func rotatingDrive(angle: Double) -> NSImage {
        NSImage(size: rotatingDriveBase.size, flipped: false) { rect in
            rotatingDriveBase.draw(in: rect)
            let rotation = NSAffineTransform()
            rotation.translateX(by: 6.2, yBy: 6.25)
            rotation.rotate(byDegrees: angle)
            rotation.concat()
            rotatingDriveOverlay.draw(in: NSRect(
                x: -rotatingDriveOverlay.size.width / 2, y: -rotatingDriveOverlay.size.height / 2,
                width: rotatingDriveOverlay.size.width, height: rotatingDriveOverlay.size.height
            ))
            return true
        }
    }
}
