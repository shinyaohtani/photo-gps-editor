import AppKit
import Foundation

final class PhotoFilm {
    private let frame: PhotoFrame = PhotoFrame()

    func thumbnail(for photo: PhotoItem, maxSize: CGFloat = 80) -> NSImage? {
        frame.thumbnail(for: photo, maxSize: maxSize)
    }

    func previewImage(for photo: PhotoItem, maxPixelSize: CGFloat) -> NSImage? {
        frame.preview(for: photo, maxSize: maxPixelSize)
    }
}
