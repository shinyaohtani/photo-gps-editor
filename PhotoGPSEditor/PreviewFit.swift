import AppKit

final class PreviewFit {
    func screen() -> NSScreen? {
        NSScreen.main ?? NSApp.mainWindow?.screen
    }

    func maxSize(on screen: NSScreen) -> NSSize {
        let frame: NSRect = screen.visibleFrame
        return NSSize(width: frame.width * 0.9, height: frame.height * 0.9)
    }

    func maxPixels(for size: NSSize) -> CGFloat {
        max(size.width, size.height) * 2
    }

    func fitted(imageSize: NSSize, maxSize: NSSize) -> NSSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return maxSize }
        let scale: CGFloat = min(maxSize.width / imageSize.width, maxSize.height / imageSize.height)
        return NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}
