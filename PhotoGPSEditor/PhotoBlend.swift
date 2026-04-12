import Foundation
import MapKit

final class PhotoBlend {
    func referenceIDs(in photos: [PhotoItem], targets: [PhotoItem]) -> Set<UUID> {
        let refs: [PhotoItem] = references(from: photos)
        guard !refs.isEmpty else { return [] }

        var ids: Set<UUID> = []
        for target: PhotoItem in targets {
            let marks: (prev: PhotoItem?, next: PhotoItem?) = marks(for: target, in: refs)
            if let prev: PhotoItem = marks.prev {
                ids.insert(prev.id)
            }
            if let next: PhotoItem = marks.next {
                ids.insert(next.id)
            }
        }
        return ids
    }

    func fill(targets: [PhotoItem], with photos: [PhotoItem]) -> Int {
        let refs: [PhotoItem] = references(from: photos)
        var count: Int = 0
        for target: PhotoItem in targets {
            target.coordinate = coord(for: target, refs: refs)
            count += 1
        }
        return count
    }

    private func references(from photos: [PhotoItem]) -> [PhotoItem] {
        photos.filter(\.hasOriginalGPS).sorted { $0.timestamp < $1.timestamp }
    }

    private func marks(for target: PhotoItem, in refs: [PhotoItem]) -> (prev: PhotoItem?, next: PhotoItem?) {
        let prev: PhotoItem? = refs.last { $0.timestamp <= target.timestamp }
        let next: PhotoItem? = refs.first { $0.timestamp > target.timestamp }
        return (prev, next)
    }

    private func coord(for target: PhotoItem, refs: [PhotoItem]) -> CLLocationCoordinate2D {
        let marks: (prev: PhotoItem?, next: PhotoItem?) = marks(for: target, in: refs)

        if let prev: PhotoItem = marks.prev, let next: PhotoItem = marks.next {
            let span: Double = next.timestamp.timeIntervalSince(prev.timestamp)
            let elapsed: Double = target.timestamp.timeIntervalSince(prev.timestamp)
            let rate: Double = span > 0 ? elapsed / span : 0.5
            return CLLocationCoordinate2D(
                latitude: prev.coordinate.latitude + rate * (next.coordinate.latitude - prev.coordinate.latitude),
                longitude: prev.coordinate.longitude + rate * (next.coordinate.longitude - prev.coordinate.longitude)
            )
        }

        if let prev: PhotoItem = marks.prev { return prev.coordinate }
        if let next: PhotoItem = marks.next { return next.coordinate }
        return target.coordinate
    }
}
