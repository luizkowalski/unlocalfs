import AppKit

extension NSApplication {
    func bringToFront() {
        setActivationPolicy(.regular)
        activate()
    }
}
