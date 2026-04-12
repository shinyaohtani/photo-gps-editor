import Foundation
import ImageIO

final class PhotoClock {
    func photoDate(at fileURL: URL, timezone: TimeZone) -> Date? {
        if isImage(fileURL) {
            return imageDate(at: fileURL, timezone: timezone)
        }
        return videoDate(at: fileURL, timezone: timezone)
    }

    private func imageDate(at fileURL: URL, timezone: TimeZone) -> Date? {
        guard let source: CGImageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let props: [String: Any] = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let exif: [String: Any] = props[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let dateText: String = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String
        else { return nil }
        return format(in: timezone).date(from: dateText)
    }

    private func videoDate(at fileURL: URL, timezone: TimeZone) -> Date? {
        let proc: Process = Process()
        proc.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/exiftool")
        proc.arguments = ["-DateTimeOriginal", "-s3", fileURL.path]
        let pipe: Pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()

        let text: String? = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty else { return nil }
        return format(in: timezone).date(from: text)
    }

    private func isImage(_ fileURL: URL) -> Bool {
        ["jpg", "jpeg", "heic", "png", "tiff"].contains(fileURL.pathExtension.lowercased())
    }

    private func format(in timezone: TimeZone) -> DateFormatter {
        let format: DateFormatter = DateFormatter()
        format.dateFormat = "yyyy:MM:dd HH:mm:ss"
        format.timeZone = timezone
        return format
    }
}
