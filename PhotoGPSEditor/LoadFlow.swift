import Foundation

final class LoadFlow {
    private unowned let store: PhotoSession

    init(store: PhotoSession) {
        self.store = store
    }

    func finishReferenceLoading(_ photos: [PhotoItem]) {
        store.referencePhotos = photos
        store.rebuildAllPhotos()
        store.isLoadingReference = false
        store.finishLoading("Reference: \(photos.count) photos loaded")
    }

    func finishTargetLoading(_ photos: [PhotoItem]) {
        store.targetPhotos = photos
        store.rebuildAllPhotos()
        store.isLoadingTarget = false
        let withGPS: Int = photos.filter(\.hasOriginalGPS).count
        store.finishLoading("Canon: \(photos.count) photos loaded (\(withGPS) with existing GPS)")
    }
}
