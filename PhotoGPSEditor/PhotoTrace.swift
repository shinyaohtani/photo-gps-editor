import Foundation
import MapKit

final class PhotoTrail {
    private unowned let store: PhotoSession
    private let blend: PhotoBlend = PhotoBlend()
    private lazy var scope: TrailScope = TrailScope(store: store)
    private lazy var undo: TrailUndo = TrailUndo(store: store)

    init(store: PhotoSession) {
        self.store = store
    }

    func interpolationReferencePhotoIDs(for selectedIDs: Set<UUID>) -> Set<UUID> {
        let targets: [PhotoItem] = store.allPhotos.filter {
            selectedIDs.contains($0.id) && $0.source == .target
        }
        return blend.referenceIDs(in: store.referencePhotos, targets: targets)
    }

    func interpolateGPS() {
        let refs: [PhotoItem] = references()
        guard !refs.isEmpty else {
            store.statusMessage = "No reference photos with GPS"
            return
        }
        let targets: [PhotoItem] = scope.targets()
        let isSelected: Bool = scope.hasSelection()
        guard !targets.isEmpty else {
            store.statusMessage = statusText(isSelected: isSelected)
            return
        }
        undo.registerInterpolation(targets)
        if isSelected { scope.reset(targets) }
        let count: Int = blend.fill(targets: targets, with: refs)
        store.editFlow.finishInterpolation(count: count, isReinterpolatingSelection: isSelected)
    }

    func commitMove(originalCoords: [UUID: CLLocationCoordinate2D]) {
        undo.registerMove(originalCoords)
    }

    private func references() -> [PhotoItem] {
        store.referencePhotos.filter(\.hasOriginalGPS).sorted { $0.timestamp < $1.timestamp }
    }

    private func statusText(isSelected: Bool) -> String {
        isSelected ? "No selected Canon photos to interpolate" : "No Canon photos without GPS"
    }
}
