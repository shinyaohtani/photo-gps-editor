import SwiftUI
import MapKit

final class UndoPane: NSView {
    var customUndoManager: UndoManager?

    override var undoManager: UndoManager? { customUndoManager }
    override var acceptsFirstResponder: Bool { true }
}

struct PhotoMap: NSViewRepresentable {
    private let pinKey: PinKey = PinKey()
    private let boxNote: MapBox = MapBox()

    var store: PhotoSession
    var photoCount: Int
    var selectedIDs: Set<UUID>
    var mapUpdateTrigger: Int
    var focusPhotoID: UUID?
    var selectionVersion: Int

    func makeNSView(context: Context) -> NSView {
        let mapView: MKMapView = MKMapView()
        let plane: SelectionPlane = SelectionPlane(mapView: mapView, store: store)
        let box: UndoPane = boxNote.makeBox(undoManager: store.undoManager)
        boxNote.configure(mapView: mapView, context: context, pinKey: pinKey)
        boxNote.configure(plane: plane, context: context)
        box.addSubview(mapView)
        mapView.addSubview(plane)
        boxNote.activate(box: box, mapView: mapView, plane: plane)
        context.coordinator.mapView = mapView
        return box
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let mapView: MKMapView = context.coordinator.mapView else { return }
        let scene: MapScene = MapScene(store: store)
        let photos: [PhotoItem] = scene.visiblePhotos()
        let refs: Set<UUID> = scene.referenceIDs(for: selectedIDs)
        scene.syncAnnotations(on: mapView, photos: photos)
        scene.syncPins(on: mapView, photos: photos, selectedIDs: selectedIDs, referenceIDs: refs)
        scene.focus(on: mapView)
    }

    func makeCoordinator() -> MapGuide {
        MapGuide(store: store, pinKey: pinKey)
    }
}

final class MapGuide: NSObject, MKMapViewDelegate {
    var store: PhotoSession
    let pinKey: PinKey
    weak var mapView: MKMapView?
    private var keyMonitor: Any?
    private var flagMonitor: Any?
    let preview: PreviewPanel = PreviewPanel()

    init(store: PhotoSession, pinKey: PinKey) {
        self.store = store
        self.pinKey = pinKey
        super.init()
        // プレビュー用キーと Undo を 1 つのモニタで処理する。
        // 別々のモニタだと、一方が nil を返してもう一方がイベントを返し、
        // AppKit が未処理と判定して警告音を鳴らす。
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            // handlePreview が nil を返したらキーを消費済み
            guard let passthrough = self.handlePreview(event) else { return nil }
            return self.handleUndo(passthrough)
        }
        flagMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.updateSuspension(event) ?? event
        }
    }

    deinit {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let flagMonitor { NSEvent.removeMonitor(flagMonitor) }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        guard let photo: PhotoItem = annotation as? PhotoItem else { return nil }
        let pin: PinDot = mapView.dequeueReusableAnnotationView(
            withIdentifier: pinKey.reuseID,
            for: annotation
        ) as! PinDot
        pin.isDraggable = false
        pin.canShowCallout = false
        pin.apply(
            photo: photo,
            isSelected: store.selectedPhotoIDs.contains(photo.id),
            isRef: referenceIDs.contains(photo.id)
        )
        pin.onHover = { [weak self] photo, pin, isHover in
            self?.handleHover(photo: photo, pin: pin, isHover: isHover)
        }
        return pin
    }

    private var referenceIDs: Set<UUID> {
        store.trail.interpolationReferencePhotoIDs(for: store.selectedPhotoIDs)
    }

    private func handleUndo(_ event: NSEvent) -> NSEvent? {
        guard event.modifierFlags.contains(.command),
              event.charactersIgnoringModifiers == "z"
        else { return event }
        if event.modifierFlags.contains(.shift), store.undoManager.canRedo {
            store.undoManager.redo()
            store.mapUpdateTrigger += 1
            return nil
        }
        if store.undoManager.canUndo {
            store.undoManager.undo()
            store.mapUpdateTrigger += 1
            return nil
        }
        return event
    }

    private func handlePreview(_ event: NSEvent) -> NSEvent? {
        guard preview.isVisible else { return event }
        switch event.keyCode {
        case 53:
            preview.hide()
            return nil
        case 123, 126:
            preview.move(delta: -1, store: store)
            return nil
        case 124, 125:
            preview.move(delta: 1, store: store)
            return nil
        default:
            return event
        }
    }

    private func handleHover(photo: PhotoItem, pin: PinDot, isHover: Bool) {
        if NSEvent.modifierFlags.contains(.option) {
            preview.hide()
            return
        }
        guard !preview.isSuspended else { return }
        if isHover {
            preview.show(photo: photo, store: store, anchorView: pin)
        } else {
            preview.reevaluate()
        }
    }

    private func updateSuspension(_ event: NSEvent) -> NSEvent {
        preview.isSuspended = event.modifierFlags.contains(.option)
        return event
    }
}
