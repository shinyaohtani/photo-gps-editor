import Foundation
import MapKit
import AppKit
import Observation

@Observable
class PhotoSession {
    var referencePhotos: [PhotoItem] = []
    var targetPhotos: [PhotoItem] = []
    var allPhotos: [PhotoItem] = []
    var selectedPhotoIDs: Set<UUID> = []
    var selectionVersion: Int = 0

    /// リスト→地図でズームしたい時だけ使う
    var focusPhotoID: UUID?

    var filterMode: FilterMode = .all
    var canonTimezoneID: String = "Asia/Tokyo"
    var mapUpdateTrigger: Int = 0
    var statusMessage: String = ""
    var isLoading: Bool = false
    var isLoadingReference: Bool = false
    var isLoadingTarget: Bool = false

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case selected = "Selected"
        case noGPS = "No GPS"
    }

    let undoManager: UndoManager = {
        let um = UndoManager()
        um.levelsOfUndo = 0
        return um
    }()

    var canonTimezone: TimeZone {
        TimeZone(identifier: canonTimezoneID) ?? TimeZone(identifier: "Asia/Tokyo")!
    }

    // MARK: - Helpers

    @ObservationIgnored lazy var choice: PhotoChoice = PhotoChoice(store: self)
    @ObservationIgnored lazy var input: PhotoInput = PhotoInput(store: self)
    @ObservationIgnored lazy var trail: PhotoTrail = PhotoTrail(store: self)
    @ObservationIgnored lazy var film: PhotoFilm = PhotoFilm()
    @ObservationIgnored lazy var stamp: GPSStamp = GPSStamp()
    @ObservationIgnored lazy var loadFlow: LoadFlow = LoadFlow(store: self)
    @ObservationIgnored lazy var editFlow: EditFlow = EditFlow(store: self)

    func rebuildAllPhotos() {
        allPhotos = referencePhotos + targetPhotos
        mapUpdateTrigger += 1
    }

    func beginLoading(_ message: String) {
        isLoading = true
        statusMessage = message
    }

    func finishLoading(_ message: String) {
        statusMessage = message
        isLoading = false
    }

    func restore(_ coords: [(UUID, CLLocationCoordinate2D)]) {
        for (id, coord): (UUID, CLLocationCoordinate2D) in coords {
            guard let photo: PhotoItem = allPhotos.first(where: { $0.id == id }) else { continue }
            photo.coordinate = coord
        }
    }
}
