import Foundation
import MapKit

final class MapScene {
    private unowned let store: PhotoSession

    init(store: PhotoSession) {
        self.store = store
    }

    func visiblePhotos() -> [PhotoItem] {
        store.allPhotos.filter { $0.source == .reference || $0.hasValidCoordinate }
    }

    func referenceIDs(for selectedIDs: Set<UUID>) -> Set<UUID> {
        store.trail.interpolationReferencePhotoIDs(for: selectedIDs)
    }

    func syncAnnotations(on mapView: MKMapView, photos: [PhotoItem]) {
        let curIDs: Set<UUID> = Set(mapView.annotations.compactMap { ($0 as? PhotoItem)?.id })
        let nextIDs: Set<UUID> = Set(photos.map(\.id))
        let remove: [MKAnnotation] = mapView.annotations.filter {
            guard let photo: PhotoItem = $0 as? PhotoItem else { return false }
            return !nextIDs.contains(photo.id)
        }
        let add: [PhotoItem] = photos.filter { !curIDs.contains($0.id) }
        if !remove.isEmpty { mapView.removeAnnotations(remove) }
        if !add.isEmpty { mapView.addAnnotations(add) }
        guard !add.isEmpty, curIDs.isEmpty || add.contains(where: { $0.source == .target }) else { return }
        var rect: MKMapRect = .null
        for photo: PhotoItem in photos where photo.hasValidCoordinate {
            let point: MKMapPoint = MKMapPoint(photo.coordinate)
            rect = rect.union(MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1)))
        }
        guard !rect.isNull else { return }
        mapView.setVisibleMapRect(rect, edgePadding: NSEdgeInsets(top: 60, left: 60, bottom: 60, right: 60), animated: true)
    }

    func syncPins(on mapView: MKMapView, photos: [PhotoItem], selectedIDs: Set<UUID>, referenceIDs: Set<UUID>) {
        for photo: PhotoItem in photos {
            guard let pin: PinDot = mapView.view(for: photo) as? PinDot else { continue }
            pin.apply(photo: photo, isSelected: selectedIDs.contains(photo.id), isRef: referenceIDs.contains(photo.id))
        }
    }

    func focus(on mapView: MKMapView) {
        guard let focusPhotoID: UUID = store.focusPhotoID,
              let photo: PhotoItem = store.allPhotos.first(where: { $0.id == focusPhotoID }),
              photo.hasValidCoordinate
        else { return }
        let region: MKCoordinateRegion = MKCoordinateRegion(center: photo.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
        DispatchQueue.main.async { self.store.focusPhotoID = nil }
    }
}
