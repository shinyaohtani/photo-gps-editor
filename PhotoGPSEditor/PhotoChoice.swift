import Foundation

final class PhotoChoice {
    private unowned let store: PhotoSession

    init(store: PhotoSession) {
        self.store = store
    }

    func selectFromList(_ id: UUID) {
        store.selectedPhotoIDs = [id]
        store.focusPhotoID = id
        store.selectionVersion += 1
    }

    func selectFromMap(_ id: UUID) {
        store.selectedPhotoIDs = [id]
        store.selectionVersion += 1
    }

    func setSelection(_ ids: Set<UUID>) {
        store.selectedPhotoIDs = ids
        store.selectionVersion += 1
    }

    func updateSelection(_ id: UUID) {
        if store.selectedPhotoIDs.contains(id) {
            store.selectedPhotoIDs.remove(id)
        } else {
            store.selectedPhotoIDs.insert(id)
        }
        store.selectionVersion += 1
    }

    func clear() {
        store.selectedPhotoIDs.removeAll()
        store.selectionVersion += 1
    }
}
