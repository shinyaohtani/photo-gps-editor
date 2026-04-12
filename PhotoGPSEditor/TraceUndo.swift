import Foundation
import MapKit

final class TrailUndo {
    private unowned let store: PhotoSession

    init(store: PhotoSession) {
        self.store = store
    }

    func registerInterpolation(_ photos: [PhotoItem]) {
        let snapshot: [(UUID, CLLocationCoordinate2D)] = pairs(from: currentCoords(for: Set(photos.map(\.id))))
        store.undoManager.registerUndo(withTarget: store) { store in
            store.restore(snapshot)
            store.mapUpdateTrigger += 1
            store.statusMessage = "Undo: interpolation"
        }
        store.undoManager.setActionName("Interpolate GPS")
    }

    func registerMove(_ originalCoords: [UUID: CLLocationCoordinate2D]) {
        guard !originalCoords.isEmpty else { return }
        let newCoords: [UUID: CLLocationCoordinate2D] = currentCoords(for: Set(originalCoords.keys))
        store.undoManager.registerUndo(withTarget: store) { store in
            store.restore(self.pairs(from: originalCoords))
            store.mapUpdateTrigger += 1
            store.statusMessage = "Undo: move \(originalCoords.count) photos"
            store.editFlow.registerMoveRedo(newCoords)
        }
        store.undoManager.setActionName("Move Photos")
    }

    private func currentCoords(for ids: Set<UUID>) -> [UUID: CLLocationCoordinate2D] {
        store.allPhotos.reduce(into: [:]) { result, photo in
            guard ids.contains(photo.id) else { return }
            result[photo.id] = photo.coordinate
        }
    }

    private func pairs(from coords: [UUID: CLLocationCoordinate2D]) -> [(UUID, CLLocationCoordinate2D)] {
        coords.map { ($0.key, $0.value) }
    }
}
