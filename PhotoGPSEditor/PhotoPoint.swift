import Foundation
import MapKit
import ImageIO

final class PhotoPoint {
    func photoCoord(at fileURL: URL) -> CLLocationCoordinate2D? {
        if isImage(fileURL) {
            return imageCoord(at: fileURL)
        }
        return videoCoord(at: fileURL)
    }

    private func imageCoord(at fileURL: URL) -> CLLocationCoordinate2D? {
        guard let source: CGImageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let props: [String: Any] = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let gps: [String: Any] = props[kCGImagePropertyGPSDictionary as String] as? [String: Any],
              let rawLat: Double = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let rawLon: Double = gps[kCGImagePropertyGPSLongitude as String] as? Double
        else { return nil }

        let latRef: String? = (gps[kCGImagePropertyGPSLatitudeRef as String] as? String)?.uppercased()
        let lonRef: String? = (gps[kCGImagePropertyGPSLongitudeRef as String] as? String)?.uppercased()
        let lat: Double = latRef == "S" ? -rawLat : rawLat
        let lon: Double = lonRef == "W" ? -rawLon : rawLon
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func videoCoord(at fileURL: URL) -> CLLocationCoordinate2D? {
        let proc: Process = Process()
        proc.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/exiftool")
        proc.arguments = ["-GPSLatitude", "-GPSLongitude", "-n", "-s3", fileURL.path]
        let pipe: Pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()

        let text: String? = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty else { return nil }
        let rows: [String] = rows(from: text)
        guard rows.count >= 2,
              let lat: Double = Double(rows[0]),
              let lon: Double = Double(rows[1])
        else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func isImage(_ fileURL: URL) -> Bool {
        ["jpg", "jpeg", "heic", "png", "tiff"].contains(fileURL.pathExtension.lowercased())
    }

    private func rows(from text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
