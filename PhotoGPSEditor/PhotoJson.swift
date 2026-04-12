import Foundation
import MapKit

final class PhotoJson {
    func photos(at url: URL) throws -> [PhotoItem] {
        try rows(at: url).compactMap(photo(from:)).sorted { $0.timestamp < $1.timestamp }
    }

    private func rows(at url: URL) throws -> [[String: Any]] {
        let data: Data = try Data(contentsOf: url)
        guard let json: [String: Any] = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows: [[String: Any]] = json["photos"] as? [[String: Any]]
        else { throw CocoaError(.coderInvalidValue) }
        return rows
    }

    private func photo(from row: [String: Any]) -> PhotoItem? {
        guard let lat: Double = row["latitude"] as? Double,
              let lon: Double = row["longitude"] as? Double,
              let fileName: String = row["filename"] as? String,
              let dateText: String = row["creationDate"] as? String,
              let date: Date = date(from: dateText)
        else { return nil }
        let coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        return PhotoItem(filename: fileName, timestamp: date, coordinate: coord, hasOriginalGPS: true, originalCoordinate: coord, source: .reference)
    }

    private func date(from text: String) -> Date? {
        let plain: ISO8601DateFormatter = ISO8601DateFormatter()
        let frac: ISO8601DateFormatter = ISO8601DateFormatter()
        frac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return frac.date(from: text) ?? plain.date(from: text)
    }
}
