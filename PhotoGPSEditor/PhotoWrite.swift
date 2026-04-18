import Foundation
import MapKit

final class GPSStamp {
    private let tzLookup = TimeZoneLookup()

    func saveGPSToEXIF(in store: PhotoSession) {
        store.beginLoading("Saving GPS…")
        DispatchQueue.global(qos: .userInitiated).async { [weak store] in
            guard let store else { return }
            let saved: Int = self.save(photos: store.targetPhotos, cameraTimezone: store.canonTimezone)
            DispatchQueue.main.async {
                store.statusMessage = "Saved GPS for \(saved) photos"
                store.isLoading = false
            }
        }
    }

    func removeGPS(from photos: [PhotoItem], in store: PhotoSession) {
        store.beginLoading("Removing GPS…")
        DispatchQueue.global(qos: .userInitiated).async { [weak store] in
            guard let store else { return }
            var removed: Int = 0
            for photo: PhotoItem in photos {
                guard photo.hasValidCoordinate, let path: String = photo.filePath else { continue }
                let proc: Process = Process()
                proc.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/exiftool")
                proc.arguments = ["-gps:all=", "-overwrite_original", path]
                try? proc.run()
                proc.waitUntilExit()
                guard proc.terminationStatus == 0 else { continue }
                DispatchQueue.main.async {
                    photo.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                    photo.hasOriginalGPS = false
                    photo.originalCoordinate = nil
                }
                removed += 1
            }
            DispatchQueue.main.async {
                store.mapUpdateTrigger += 1
                store.finishLoading("Removed GPS from \(removed) photos")
            }
        }
    }

    func needsWrite(_ photo: PhotoItem) -> Bool {
        guard photo.source == .target, photo.hasValidCoordinate else { return false }
        guard let orig: CLLocationCoordinate2D = photo.originalCoordinate else { return true }
        return !same(photo.coordinate, orig)
    }

    func save(photos: [PhotoItem], cameraTimezone: TimeZone) -> Int {
        var saved: Int = 0
        for photo: PhotoItem in photos where needsWrite(photo) {
            guard write(photo, cameraTimezone: cameraTimezone) else { continue }
            photo.originalCoordinate = photo.coordinate
            photo.hasOriginalGPS = photo.hasValidCoordinate
            saved += 1
        }
        return saved
    }

    private func write(_ photo: PhotoItem, cameraTimezone: TimeZone) -> Bool {
        guard let path: String = photo.filePath else { return false }
        var args: [String] = gpsArgs(for: photo.coordinate)

        // その土地のタイムゾーンを取得し、時刻を変換
        if let localTZ: TimeZone = tzLookup.timezone(for: photo.coordinate) {
            let timeArgs: [String] = timezoneArgs(for: photo.timestamp, timezone: localTZ)
            args.append(contentsOf: timeArgs)
        }

        args.append(contentsOf: ["-overwrite_original", path])
        let proc: Process = Process()
        proc.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/exiftool")
        proc.arguments = args
        try? proc.run()
        proc.waitUntilExit()
        return proc.terminationStatus == 0
    }

    /// GPS 座標の exiftool 引数
    private func gpsArgs(for coord: CLLocationCoordinate2D) -> [String] {
        [
            "-GPSLatitude=\(abs(coord.latitude))",
            "-GPSLatitudeRef=\(coord.latitude >= 0 ? "N" : "S")",
            "-GPSLongitude=\(abs(coord.longitude))",
            "-GPSLongitudeRef=\(coord.longitude >= 0 ? "E" : "W")"
        ]
    }

    /// タイムゾーン変換の exiftool 引数。
    /// photo.timestamp (UTC) をその土地のローカル時刻に変換し、OffsetTime を付与する。
    private func timezoneArgs(for timestamp: Date, timezone: TimeZone) -> [String] {
        let offset: Int = timezone.secondsFromGMT(for: timestamp)
        let offsetHours: Int = offset / 3600
        let offsetMinutes: Int = abs(offset % 3600) / 60
        let offsetString: String = String(format: "%+03d:%02d", offsetHours, offsetMinutes)

        let localFmt: DateFormatter = DateFormatter()
        localFmt.dateFormat = "yyyy:MM:dd HH:mm:ss"
        localFmt.timeZone = timezone
        let localTimeString: String = localFmt.string(from: timestamp)

        let utcDateFmt: DateFormatter = DateFormatter()
        utcDateFmt.dateFormat = "yyyy:MM:dd"
        utcDateFmt.timeZone = TimeZone(identifier: "UTC")
        let utcDateString: String = utcDateFmt.string(from: timestamp)

        let utcTimeFmt: DateFormatter = DateFormatter()
        utcTimeFmt.dateFormat = "HH:mm:ss"
        utcTimeFmt.timeZone = TimeZone(identifier: "UTC")
        let utcTimeString: String = utcTimeFmt.string(from: timestamp)

        return [
            "-AllDates=\(localTimeString)",
            "-OffsetTime=\(offsetString)",
            "-OffsetTimeOriginal=\(offsetString)",
            "-OffsetTimeDigitized=\(offsetString)",
            "-GPSDateStamp=\(utcDateString)",
            "-GPSTimeStamp=\(utcTimeString)"
        ]
    }

    private func same(_ lhs: CLLocationCoordinate2D, _ rhs: CLLocationCoordinate2D) -> Bool {
        let eps: Double = 0.0000001
        return abs(lhs.latitude - rhs.latitude) <= eps &&
            abs(lhs.longitude - rhs.longitude) <= eps
    }
}
