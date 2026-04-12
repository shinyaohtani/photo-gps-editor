import SwiftUI

@main
struct PhotoGPSEditorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentRoot()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.titleBar)
    }
}

struct ContentRoot: View {
    @State private var store = PhotoSession()

    /// 各ウィンドウが自分のパスを @SceneStorage で保持する。
    /// macOS がウィンドウを復元した時、ここに前回のパスが入っている。
    @SceneStorage("jsonPath") private var jsonPath: String = ""
    @SceneStorage("canonPath") private var canonPath: String = ""
    @State private var didRestore = false

    var body: some View {
        ContentView(store: store, onPathsChanged: savePaths)
            .onAppear { restoreIfNeeded() }
    }

    private func restoreIfNeeded() {
        guard !didRestore else { return }
        didRestore = true
        let fm = FileManager.default
        if !jsonPath.isEmpty, fm.fileExists(atPath: jsonPath) {
            store.input.loadReferencePhotos(from: URL(fileURLWithPath: jsonPath))
        }
        if !canonPath.isEmpty, fm.fileExists(atPath: canonPath) {
            store.input.loadTargetPhotos(from: URL(fileURLWithPath: canonPath))
        }
    }

    private func savePaths(json: String?, canon: String?) {
        if let json { jsonPath = json }
        if let canon { canonPath = canon }
    }
}
