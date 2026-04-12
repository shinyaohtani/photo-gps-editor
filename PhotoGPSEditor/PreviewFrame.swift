import AppKit

final class PreviewFrame {
    private var panel: NSPanel?
    private var imageView: NSImageView?
    private let fit: PreviewFit = PreviewFit()

    var isVisible: Bool { panel?.isVisible == true }
    var currentPanel: NSPanel? { panel }

    func panelBox() -> NSPanel {
        if let panel { return panel }
        let panel: NSPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = NSColor.black.withAlphaComponent(0.92)
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true

        let imageView: NSImageView = NSImageView(frame: panel.contentView?.bounds ?? .zero)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(imageView)
        self.panel = panel
        self.imageView = imageView
        return panel
    }

    func update(photo: PhotoItem, store: PhotoSession) -> Bool {
        guard let screen: NSScreen = fit.screen() else { return false }
        let panel: NSPanel = panelBox()
        let frame: NSRect = screen.visibleFrame
        let maxSize: NSSize = fit.maxSize(on: screen)
        let maxPixels: CGFloat = fit.maxPixels(for: maxSize)
        guard let image: NSImage = store.film.previewImage(for: photo, maxPixelSize: maxPixels) else {
            return false
        }
        let size: NSSize = fit.fitted(imageSize: image.size, maxSize: maxSize)
        display(image: image, size: size, on: panel, within: frame)
        return true
    }

    func hide() {
        panel?.orderOut(nil)
        imageView?.image = nil
    }

    private func display(image: NSImage, size: NSSize, on panel: NSPanel, within frame: NSRect) {
        let origin: NSPoint = NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        imageView?.image = image
        imageView?.frame = NSRect(origin: .zero, size: size)
        panel.orderFrontRegardless()
    }
}
