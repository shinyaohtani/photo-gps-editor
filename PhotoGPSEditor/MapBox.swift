import AppKit
import MapKit

final class MapBox {
    func makeBox(undoManager: UndoManager) -> UndoPane {
        let box: UndoPane = UndoPane()
        box.customUndoManager = undoManager
        box.setAccessibilityIdentifier("mapContainer")
        return box
    }

    func configure(mapView: MKMapView, context: PhotoMap.Context, pinKey: PinKey) {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.setAccessibilityIdentifier("mainMap")
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.register(PinDot.self, forAnnotationViewWithReuseIdentifier: pinKey.reuseID)
    }

    func configure(plane: SelectionPlane, context: PhotoMap.Context) {
        plane.translatesAutoresizingMaskIntoConstraints = false
        plane.preview = context.coordinator.preview
    }

    func activate(box: UndoPane, mapView: MKMapView, plane: SelectionPlane) {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: box.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            plane.topAnchor.constraint(equalTo: mapView.topAnchor),
            plane.bottomAnchor.constraint(equalTo: mapView.bottomAnchor),
            plane.leadingAnchor.constraint(equalTo: mapView.leadingAnchor),
            plane.trailingAnchor.constraint(equalTo: mapView.trailingAnchor)
        ])
    }
}
