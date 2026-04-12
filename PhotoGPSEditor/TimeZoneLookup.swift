import CoreLocation

/// GPS 座標からタイムゾーンを取得する。CLGeocoder を使い、0.5 度グリッドでキャッシュする。
final class TimeZoneLookup {
    private var cache: [String: TimeZone] = [:]
    private let geocoder = CLGeocoder()

    /// 同期的にタイムゾーンを返す。バックグラウンドスレッドから呼ぶこと。
    func timezone(for coord: CLLocationCoordinate2D) -> TimeZone? {
        let key = "\(Int(coord.latitude * 2))_\(Int(coord.longitude * 2))"
        if let cached = cache[key] { return cached }

        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let semaphore = DispatchSemaphore(value: 0)
        var result: TimeZone?

        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            result = placemarks?.first?.timeZone
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 10)
        if let tz = result { cache[key] = tz }
        return result
    }
}
