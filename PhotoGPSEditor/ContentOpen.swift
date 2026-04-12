import Foundation
import UniformTypeIdentifiers
import AppKit

final class SourcePanel {
    static let jsonPathKey = "lastJSONPath"
    static let canonPathKey = "lastCanonFolderPath"

    private unowned let store: PhotoSession
    var onPathsChanged: ((_ json: String?, _ canon: String?) -> Void)?

    init(store: PhotoSession) {
        self.store = store
    }

    func openJSON() {
        let panel: NSOpenPanel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        if panel.runModal() == .OK, let url: URL = panel.url {
            loadJSON(url)
        }
    }

    func openCanonFolder() {
        let panel: NSOpenPanel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url: URL = panel.url {
            loadCanon(url)
        }
    }

    func loadJSON(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: Self.jsonPathKey)
        onPathsChanged?(url.path, nil)
        store.input.loadReferencePhotos(from: url)
    }

    func loadCanon(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: Self.canonPathKey)
        onPathsChanged?(nil, url.path)
        store.input.loadTargetPhotos(from: url)
    }
}
