import Foundation
import MapKit

final class EditFlow {
    private unowned let store: PhotoSession

    init(store: PhotoSession) {
        self.store = store
    }

    func finishInterpolation(count: Int, isReinterpolatingSelection: Bool) {
        store.mapUpdateTrigger += 1
        store.statusMessage = isReinterpolatingSelection
            ? "Re-interpolated GPS for \(count) selected Canon photos"
            : "Interpolated GPS for \(count) Canon photos without existing GPS"
    }

    func registerMoveRedo(_ coords: [UUID: CLLocationCoordinate2D]) {
        store.undoManager.registerUndo(withTarget: store) { store in
            store.restore(coords.map { ($0.key, $0.value) })
            store.mapUpdateTrigger += 1
            store.statusMessage = "Redo: move \(coords.count) photos"
        }
        store.undoManager.setActionName("Move Photos")
    }
}
