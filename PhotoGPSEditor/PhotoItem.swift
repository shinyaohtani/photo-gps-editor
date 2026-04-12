import Foundation
import MapKit

/// 1枚の写真を表すモデル。MKAnnotation 準拠で地図ピンとして直接使用可能。
class PhotoItem: NSObject, MKAnnotation, Identifiable {
    let id = UUID()
    let filename: String
    let filePath: String?
    let timestamp: Date

    /// KVO 対応: MKMapView が座標変更を自動検知してピンを移動する
    @objc dynamic var coordinate: CLLocationCoordinate2D

    var hasOriginalGPS: Bool
    var originalCoordinate: CLLocationCoordinate2D?
    let source: Source

    enum Source: String {
        case reference // iPhone (GPS あり)
        case target    // Canon  (GPS なし → 補間で付与)
    }

    var title: String? { filename }

    var subtitle: String? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        fmt.timeZone = .current
        return fmt.string(from: timestamp)
    }

    init(filename: String,
         filePath: String? = nil,
         timestamp: Date,
         coordinate: CLLocationCoordinate2D,
         hasOriginalGPS: Bool,
         originalCoordinate: CLLocationCoordinate2D? = nil,
         source: Source) {
        self.filename = filename
        self.filePath = filePath
        self.timestamp = timestamp
        self.coordinate = coordinate
        self.hasOriginalGPS = hasOriginalGPS
        self.originalCoordinate = originalCoordinate
        self.source = source
        super.init()
    }

    /// 有効な GPS 座標を持っているか（0,0 は無効とみなす）
    var hasValidCoordinate: Bool {
        coordinate.latitude != 0 || coordinate.longitude != 0
    }
}
