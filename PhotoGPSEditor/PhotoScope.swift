import Foundation

final class PhotoScope {
    private unowned let store: PhotoSession

    init(store: PhotoSession) {
        self.store = store
    }

    func filteredPhotos() -> [PhotoItem] {
        switch store.filterMode {
        case .all:
            return allPhotos()
        case .selected:
            return selectedPhotos()
        case .noGPS:
            return noGPSPhotos()
        }
    }

    private func allPhotos() -> [PhotoItem] {
        store.targetPhotos
    }

    private func selectedPhotos() -> [PhotoItem] {
        store.targetPhotos.filter { store.selectedPhotoIDs.contains($0.id) }
    }

    private func noGPSPhotos() -> [PhotoItem] {
        store.targetPhotos.filter { !$0.hasValidCoordinate }
    }
}
