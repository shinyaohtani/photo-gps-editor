import Foundation
import MapKit

final class TrailScope {
    private unowned let store: PhotoSession

    init(store: PhotoSession) {
        self.store = store
    }

    func targets() -> [PhotoItem] {
        let ids: Set<UUID> = selectedTargetIDs()
        if ids.isEmpty { return store.targetPhotos.filter { !$0.hasOriginalGPS } }
        return store.targetPhotos.filter { ids.contains($0.id) }
    }

    func selectedTargetIDs() -> Set<UUID> {
        store.selectedPhotoIDs.intersection(Set(store.targetPhotos.map(\.id)))
    }

    func hasSelection() -> Bool {
        !selectedTargetIDs().isEmpty
    }

    func reset(_ photos: [PhotoItem]) {
        for photo: PhotoItem in photos {
            photo.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
    }
}
