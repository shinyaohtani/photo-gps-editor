import SwiftUI
import MapKit

final class SelectionPlane: NSView {
    let mapView: MKMapView
    let store: PhotoSession

    private let rectBand: RectBand
    private let moveDrag: MoveDrag
    private let hitMap: HitMap
    private let choicePop: ChoicePop = ChoicePop()
    private var clicked: PhotoItem?

    var preview: PreviewPanel?

    init(mapView: MKMapView, store: PhotoSession) {
        self.mapView = mapView
        self.store = store
        rectBand = RectBand()
        moveDrag = MoveDrag()
        hitMap = HitMap(mapView: mapView, store: store)
        super.init(frame: .zero)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override var acceptsFirstResponder: Bool { true }
    override var undoManager: UndoManager? { store.undoManager }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if NSEvent.modifierFlags.contains(.command) && !moveDrag.isDragging { return nil }
        if rectBand.isActive || moveDrag.isDragging { return self }
        let local: NSPoint = convert(point, from: superview)
        return hitMap.nearest(to: local, in: self) == nil ? self : self
    }

    override func scrollWheel(with event: NSEvent) { mapView.scrollWheel(with: event) }
    override func magnify(with event: NSEvent) { mapView.magnify(with: event) }
    override func rotate(with event: NSEvent) { mapView.rotate(with: event) }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point: NSPoint = convert(event.locationInWindow, from: nil)
        clicked = nil
        preview?.hide()

        guard let photo: PhotoItem = hitMap.nearest(to: point, in: self) else {
            rectBand.begin(at: point, additive: event.modifierFlags.contains(.shift), store: store)
            return
        }
        if event.modifierFlags.contains(.shift) {
            store.choice.updateSelection(photo.id)
            return
        }

        clicked = photo
        moveDrag.prepare(at: point)
        if event.modifierFlags.contains(.option), photo.source == .target {
            moveDrag.begin(photo: photo, store: store, preview: preview)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let point: NSPoint = convert(event.locationInWindow, from: nil)
        if rectBand.update(to: point, view: self) { return }
        if rectBand.beginIfNeeded(at: point, move: moveDrag, store: store, view: self) {
            clicked = nil
            return
        }
        moveDrag.update(to: point, mapView: mapView, view: self, store: store)
    }

    override func mouseUp(with event: NSEvent) {
        if rectBand.finish(additive: event.modifierFlags.contains(.shift), hit: hitMap, store: store, view: self) {
            clicked = nil
            return
        }
        if moveDrag.finish(store: store) { return }
        if let clicked {
            store.choice.selectFromMap(clicked.id)
            mapView.selectAnnotation(clicked, animated: true)
        }
        moveDrag.reset(preview: preview)
        clicked = nil
    }

    override func rightMouseDown(with event: NSEvent) {
        let point: NSPoint = convert(event.locationInWindow, from: nil)
        let photos: [PhotoItem] = hitMap.photos(near: point, threshold: 25, in: self)
        guard !photos.isEmpty else { return }
        choicePop.show(photos: photos, at: point, in: self, store: store)
    }

    override func rightMouseUp(with event: NSEvent) {}

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        rectBand.draw()
    }
}

final class RectBand {
    var start: NSPoint?
    var rect: NSRect?

    var isActive: Bool { start != nil }

    func begin(at point: NSPoint, additive: Bool, store: PhotoSession) {
        if !additive { store.choice.clear() }
        start = point
        rect = nil
    }

    func update(to point: NSPoint, view: NSView) -> Bool {
        guard let start else { return false }
        rect = NSRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )
        view.needsDisplay = true
        return true
    }

    func beginIfNeeded(at point: NSPoint, move: MoveDrag, store: PhotoSession, view: NSView) -> Bool {
        guard let start: NSPoint = move.start, !move.isMove else { return false }
        guard hypot(point.x - start.x, point.y - start.y) >= 4 else { return true }
        begin(at: start, additive: false, store: store)
        rect = NSRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )
        move.start = nil
        view.needsDisplay = true
        return true
    }

    func finish(additive: Bool, hit: HitMap, store: PhotoSession, view: NSView) -> Bool {
        guard let rect else { return false }
        let ids: Set<UUID> = hit.selectedIDs(in: rect, additive: additive, view: view)
        store.choice.setSelection(ids)
        self.rect = nil
        start = nil
        view.needsDisplay = true
        return true
    }

    func draw() {
        guard let rect else { return }
        NSColor.systemBlue.withAlphaComponent(0.15).setFill()
        NSBezierPath(rect: rect).fill()
        NSColor.systemBlue.withAlphaComponent(0.6).setStroke()
        let path: NSBezierPath = NSBezierPath(rect: rect)
        path.lineWidth = 1.5
        path.stroke()
    }
}

final class MoveDrag {
    var start: NSPoint?
    var coords: [UUID: CLLocationCoordinate2D] = [:]
    var isDragging: Bool = false
    var isMove: Bool = false
    private var isReady: Bool = false

    func prepare(at point: NSPoint) {
        start = point
        isReady = false
        isMove = false
    }

    func begin(photo: PhotoItem, store: PhotoSession, preview: PreviewPanel?) {
        isMove = true
        preview?.isSuspended = true
        if !store.selectedPhotoIDs.contains(photo.id) {
            store.choice.selectFromMap(photo.id)
        }
        isDragging = true
        coords = store.allPhotos.reduce(into: [:]) { result, photo in
            guard store.selectedPhotoIDs.contains(photo.id), photo.source == .target else { return }
            result[photo.id] = photo.coordinate
        }
    }

    func update(to point: NSPoint, mapView: MKMapView, view: NSView, store: PhotoSession) {
        guard isDragging, let start else { return }
        if !isReady {
            guard hypot(point.x - start.x, point.y - start.y) >= 4 else { return }
            isReady = true
        }
        let coord: CLLocationCoordinate2D = mapView.convert(point, toCoordinateFrom: view)
        for (id, _) in coords {
            guard let photo: PhotoItem = store.allPhotos.first(where: { $0.id == id }) else { continue }
            photo.coordinate = coord
        }
    }

    func finish(store: PhotoSession) -> Bool {
        guard isDragging, isReady else { return false }
        store.trail.commitMove(originalCoords: coords)
        return true
    }

    func reset(preview: PreviewPanel?) {
        isDragging = false
        isReady = false
        isMove = false
        preview?.isSuspended = false
        start = nil
        coords = [:]
    }
}

final class HitMap {
    private weak var mapView: MKMapView?
    private unowned let store: PhotoSession

    init(mapView: MKMapView, store: PhotoSession) {
        self.mapView = mapView
        self.store = store
    }

    /// 選択対象として最も近い target 写真を返す。reference は選択できない。
    func nearest(to point: NSPoint, in view: NSView) -> PhotoItem? {
        photos(near: point, threshold: 15, in: view)
            .filter { $0.source == .target }
            .min { lhs, rhs in
                let lhsPoint: NSPoint = screenPoint(for: lhs, in: view)
                let rhsPoint: NSPoint = screenPoint(for: rhs, in: view)
                let lhsDist: CGFloat = hypot(lhsPoint.x - point.x, lhsPoint.y - point.y)
                let rhsDist: CGFloat = hypot(rhsPoint.x - point.x, rhsPoint.y - point.y)
                return lhsDist < rhsDist
            }
    }

    /// 閾値内の全写真を返す（右クリックポップオーバー用は reference も含む）
    func photos(near point: NSPoint, threshold: CGFloat, in view: NSView) -> [PhotoItem] {
        store.allPhotos.filter { photo in
            guard photo.hasValidCoordinate || photo.source == .reference else { return false }
            let pinPoint: NSPoint = screenPoint(for: photo, in: view)
            return hypot(pinPoint.x - point.x, pinPoint.y - point.y) < threshold
        }
    }

    /// 矩形内の target 写真だけを選択対象にする。reference は除外。
    func selectedIDs(in rect: NSRect, additive: Bool, view: NSView) -> Set<UUID> {
        var ids: Set<UUID> = additive ? store.selectedPhotoIDs : []
        for photo: PhotoItem in store.allPhotos where photo.source == .target && photo.hasValidCoordinate {
            if rect.contains(screenPoint(for: photo, in: view)) { ids.insert(photo.id) }
        }
        return ids
    }

    private func screenPoint(for photo: PhotoItem, in view: NSView?) -> NSPoint {
        mapView?.convert(photo.coordinate, toPointTo: view) ?? .zero
    }
}

final class ChoicePop {
    private var popover: NSPopover?

    func show(photos: [PhotoItem], at point: NSPoint, in view: NSView, store: PhotoSession) {
        close()
        let popover: NSPopover = popoverBox(photos: photos, store: store)
        self.popover = popover
        popover.show(
            relativeTo: anchorRect(at: point),
            of: view,
            preferredEdge: .maxY
        )
    }

    func close() {
        popover?.close()
    }

    private func popoverBox(photos: [PhotoItem], store: PhotoSession) -> NSPopover {
        let popover: NSPopover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = contentSize(count: photos.count)
        popover.contentViewController = NSHostingController(rootView: PhotoChoiceView(photos: photos, store: store))
        return popover
    }

    private func contentSize(count: Int) -> NSSize {
        NSSize(width: 320, height: min(CGFloat(count) * 48 + 20, 500))
    }

    private func anchorRect(at point: NSPoint) -> NSRect {
        NSRect(origin: point, size: NSSize(width: 1, height: 1))
    }
}

struct PhotoChoiceView: View {
    let photos: [PhotoItem]
    var store: PhotoSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Divider()
            rows
        }
        .padding(.vertical, 8)
    }

    private var header: some View {
        Text("\(photos.count) photos at this location")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
    }

    private var rows: some View {
        ForEach(photos) { photo in
            Toggle(isOn: toggle(for: photo)) {
                HStack(spacing: 6) {
                    if let thumb: NSImage = store.film.thumbnail(for: photo) {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipped()
                            .cornerRadius(3)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(photo.filename)
                            .font(.system(.caption, design: .monospaced))
                        Text(photo.subtitle ?? "")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toggleStyle(.checkbox)
            .padding(.horizontal, 10)
        }
    }

    private func toggle(for photo: PhotoItem) -> Binding<Bool> {
        Binding(
            get: { store.selectedPhotoIDs.contains(photo.id) },
            set: { isOn in updateSelection(photo: photo, isOn: isOn) }
        )
    }

    private func updateSelection(photo: PhotoItem, isOn: Bool) {
        if isOn {
            store.choice.setSelection(store.selectedPhotoIDs.union([photo.id]))
        } else {
            store.choice.setSelection(store.selectedPhotoIDs.subtracting([photo.id]))
        }
    }
}
