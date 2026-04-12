import Foundation
import MapKit

final class PhotoCanon {
    private let clock: PhotoClock = PhotoClock()
    private let point: PhotoPoint = PhotoPoint()

    func photos(in directoryURL: URL, timezone: TimeZone) -> [PhotoItem]? {
        files(in: directoryURL)?
            .filter(supports(_:))
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { photo(at: $0, timezone: timezone) }
    }

    private func files(in directoryURL: URL) -> [URL]? {
        try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
    }

    private func photo(at fileURL: URL, timezone: TimeZone) -> PhotoItem? {
        guard let date: Date = clock.photoDate(at: fileURL, timezone: timezone) else { return nil }
        let originalCoordinate: CLLocationCoordinate2D? = point.photoCoord(at: fileURL)
        return PhotoItem(
            filename: fileURL.lastPathComponent,
            filePath: fileURL.path,
            timestamp: date,
            coordinate: originalCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
            hasOriginalGPS: originalCoordinate != nil,
            originalCoordinate: originalCoordinate,
            source: .target
        )
    }

    private func supports(_ fileURL: URL) -> Bool {
        ["jpg", "jpeg", "mp4", "mov"].contains(fileURL.pathExtension.lowercased())
    }
}
