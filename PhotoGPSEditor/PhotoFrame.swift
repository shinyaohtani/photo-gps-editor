import Foundation
import AppKit
import ImageIO
import AVFoundation

final class PhotoFrame {
    private let thumbs: NSCache<NSString, NSImage>
    private let previews: NSCache<NSString, NSImage>

    init() {
        thumbs = NSCache<NSString, NSImage>()
        previews = NSCache<NSString, NSImage>()
        thumbs.countLimit = 256
        thumbs.totalCostLimit = 64 * 1024 * 1024
        previews.countLimit = 8
        previews.totalCostLimit = 160 * 1024 * 1024
    }

    func thumbnail(for photo: PhotoItem, maxSize: CGFloat) -> NSImage? {
        let key: NSString = NSString(string: photo.filename)
        if let image: NSImage = thumbs.object(forKey: key) { return image }
        guard let image: NSImage = image(for: photo, maxSize: maxSize, forceThumb: false) else { return nil }
        thumbs.setObject(image, forKey: key, cost: image.cacheCost)
        return image
    }

    func preview(for photo: PhotoItem, maxSize: CGFloat) -> NSImage? {
        let name: String = "\(photo.filename)#\(Int(maxSize.rounded()))"
        let key: NSString = NSString(string: name)
        if let image: NSImage = previews.object(forKey: key) { return image }
        guard let image: NSImage = image(for: photo, maxSize: maxSize, forceThumb: true) else { return nil }
        previews.setObject(image, forKey: key, cost: image.cacheCost)
        return image
    }

    private func image(for photo: PhotoItem, maxSize: CGFloat, forceThumb: Bool) -> NSImage? {
        guard let path: String = photo.filePath else { return nil }
        let fileURL: URL = URL(fileURLWithPath: path)
        if ["mp4", "mov", "m4v"].contains(fileURL.pathExtension.lowercased()) {
            return videoImage(at: fileURL, maxSize: maxSize)
        }
        return stillImage(at: fileURL, maxSize: maxSize, forceThumb: forceThumb)
    }

    private func stillImage(at fileURL: URL, maxSize: CGFloat, forceThumb: Bool) -> NSImage? {
        guard let source: CGImageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailFromImageAlways: forceThumb,
            kCGImageSourceThumbnailMaxPixelSize: maxSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cg: CGImage = CGImageSourceCreateThumbnailAtIndex(source, 0, opts as CFDictionary) else {
            return nil
        }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }

    private func videoImage(at fileURL: URL, maxSize: CGFloat) -> NSImage? {
        let asset: AVAsset = AVAsset(url: fileURL)
        let gen: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: maxSize, height: maxSize)
        let sec: Double = asset.duration.seconds > 1 ? min(1, asset.duration.seconds * 0.25) : 0
        let time: CMTime = CMTime(seconds: sec, preferredTimescale: 600)
        guard let cg: CGImage = try? gen.copyCGImage(at: time, actualTime: nil) else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }
}

private extension NSImage {
    var cacheCost: Int { (representations.first as? NSBitmapImageRep).map { $0.bytesPerRow * $0.pixelsHigh } ?? 0 }
}
