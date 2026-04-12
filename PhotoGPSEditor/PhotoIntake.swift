import Foundation
import MapKit

final class PhotoInput {
    private unowned let store: PhotoSession
    private let json: PhotoJson = PhotoJson()
    private let canon: PhotoCanon = PhotoCanon()

    init(store: PhotoSession) {
        self.store = store
    }

    func loadReferencePhotos(from url: URL) {
        store.isLoadingReference = true
        store.beginLoading("Loading reference photos…")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                let photos: [PhotoItem] = try self.json.photos(at: url)
                DispatchQueue.main.async { self.finishReferenceLoad(photos) }
            } catch {
                DispatchQueue.main.async { self.store.finishLoading("Error: \(error.localizedDescription)") }
            }
        }
    }

    func loadTargetPhotos(from directoryURL: URL) {
        store.isLoadingTarget = true
        store.beginLoading("Loading Canon photos…")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            guard let photos: [PhotoItem] = self.canon.photos(in: directoryURL, timezone: self.store.canonTimezone) else {
                DispatchQueue.main.async { self.store.finishLoading("Cannot read directory") }
                return
            }
            DispatchQueue.main.async { self.finishTargetLoad(photos) }
        }
    }

    private func finishReferenceLoad(_ photos: [PhotoItem]) {
        store.loadFlow.finishReferenceLoading(photos)
    }

    private func finishTargetLoad(_ photos: [PhotoItem]) {
        store.loadFlow.finishTargetLoading(photos)
    }
}
