import AppKit

final class PreviewPanel {
    private var photoID: UUID?
    private var anchorID: UUID?
    private var anchorRect: NSRect?
    private var pending: DispatchWorkItem?
    private let frame: PreviewFrame = PreviewFrame()
    private let track: PreviewZone = PreviewZone()

    var isSuspended: Bool = false {
        didSet {
            if isSuspended { hide() }
        }
    }

    var isVisible: Bool { frame.isVisible }

    func show(photo: PhotoItem, store: PhotoSession, anchorView: NSView) {
        guard !isSuspended else { return }
        anchorID = photo.id
        anchorRect = anchorView.window?.convertToScreen(anchorView.convert(anchorView.bounds, to: nil))
        track.ensure { [weak self] in self?.reevaluate() }
        if photoID == photo.id, isVisible { return }

        pending?.cancel()
        let work: DispatchWorkItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard anchorID == photo.id else { return }
            guard frame.update(photo: photo, store: store) else { return }
            photoID = photo.id
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: work)
    }

    func move(delta: Int, store: PhotoSession) {
        let photos: [PhotoItem] = store.allPhotos
            .filter { $0.filePath != nil }
            .sorted { $0.timestamp < $1.timestamp }
        guard let photoID,
              let idx: Int = photos.firstIndex(where: { $0.id == photoID })
        else { return }
        let nextIdx: Int = idx + delta
        guard photos.indices.contains(nextIdx) else { return }
        if frame.update(photo: photos[nextIdx], store: store) {
            self.photoID = photos[nextIdx].id
        }
    }

    func reevaluate() {
        guard isVisible else { return }
        let mousePos: NSPoint = track.mousePos()
        if !track.isInside(mousePos: mousePos, anchorRect: anchorRect, panel: frame.currentPanel) {
            hide()
        }
    }

    func hide(for photoID: UUID? = nil) {
        guard photoID == nil || photoID == anchorID || photoID == self.photoID else { return }
        pending?.cancel()
        pending = nil
        frame.hide()
        self.photoID = nil
        anchorID = nil
        anchorRect = nil
        track.remove()
    }
}
