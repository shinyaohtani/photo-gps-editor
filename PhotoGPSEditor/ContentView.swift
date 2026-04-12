import SwiftUI

struct ContentView: View {
    @Bindable var store: PhotoSession
    var onPathsChanged: ((_ json: String?, _ canon: String?) -> Void)?
    @State private var note: ToolbarNote?
    @State private var panel: SourcePanel?
    @State private var scope: PhotoScope?
    @State private var showSaveConfirmation = false
    @State private var showRemoveGPSConfirmation = false

    private var isReady: Bool {
        !store.referencePhotos.isEmpty && !store.targetPhotos.isEmpty
    }

    var body: some View {
        Group {
            if isReady {
                HSplitView {
                    sidebar
                        .frame(minWidth: 280, maxWidth: 350)

                    PhotoMap(
                        store: store,
                        photoCount: store.allPhotos.count,
                        selectedIDs: store.selectedPhotoIDs,
                        mapUpdateTrigger: store.mapUpdateTrigger,
                        focusPhotoID: store.focusPhotoID,
                        selectionVersion: store.selectionVersion
                    )
                }
            } else {
                let p = panel ?? SourcePanel(store: store)
                WelcomeView(
                    store: store,
                    onOpenJSON: { p.openJSON() },
                    onOpenCanon: { p.openCanonFolder() },
                    onLoadJSON: { url in p.loadJSON(url) },
                    onLoadCanon: { url in p.loadCanon(url) }
                )
            }
        }
        .toolbar { toolbarItems }
        .onAppear { prepare() }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        let note: ToolbarNote = note ?? ToolbarNote(store: store)
        let panel: SourcePanel = panel ?? SourcePanel(store: store)
        ToolbarItemGroup {
            Button {
                panel.openJSON()
            } label: {
                Label("Load JSON", systemImage: "doc.badge.plus")
            }
            .help(note.loadJSONHelp())

            Button {
                panel.openCanonFolder()
            } label: {
                Label("Load Canon", systemImage: "folder.badge.plus")
            }
            .help(note.loadCanonHelp())

            Divider()

            Picker("TZ", selection: $store.canonTimezoneID) {
                Text("JST +9").tag("Asia/Tokyo")
                Text("CET +1").tag("Europe/Rome")
                Text("UTC").tag("UTC")
            }
            .frame(width: 100)
            .help(note.timezoneHelp())

            Button {
                store.trail.interpolateGPS()
            } label: {
                Label("Interpolate", systemImage: "location.magnifyingglass")
            }
            .help(note.interpolateHelp())
            .disabled(store.referencePhotos.isEmpty || store.targetPhotos.isEmpty)

            Button {
                showSaveConfirmation = true
            } label: {
                Label("Save EXIF", systemImage: "square.and.arrow.down")
            }
            .help(note.saveEXIFHelp())
            .disabled(store.targetPhotos.isEmpty)
            .alert("GPS を保存", isPresented: $showSaveConfirmation) {
                Button("保存", role: .destructive) {
                    store.stamp.saveGPSToEXIF(in: store)
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                let count = store.targetPhotos.filter { store.stamp.needsWrite($0) }.count
                Text("\(count) 枚の Canon 写真に GPS を書き込みます。その土地のタイムゾーンで時刻も変換されます。元のファイルが上書きされます。")
            }

            Divider()

            Button {
                showRemoveGPSConfirmation = true
            } label: {
                Label("Remove GPS", systemImage: "location.slash")
            }
            .help(note.removeGPSHelp())
            .disabled(store.selectedPhotoIDs.isEmpty)
            .alert("GPS を削除", isPresented: $showRemoveGPSConfirmation) {
                Button("削除", role: .destructive) {
                    let photos = store.targetPhotos.filter {
                        store.selectedPhotoIDs.contains($0.id) && $0.hasValidCoordinate
                    }
                    store.stamp.removeGPS(from: photos, in: store)
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                let count = store.targetPhotos.filter {
                    store.selectedPhotoIDs.contains($0.id) && $0.hasValidCoordinate
                }.count
                Text("選択中の Canon 写真 \(count) 枚から GPS とタイムゾーン情報を削除します。元のファイルが上書きされます。")
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        let scope: PhotoScope = scope ?? PhotoScope(store: store)
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("\(store.referencePhotos.count) ref", systemImage: "iphone")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                    Label("\(store.targetPhotos.count) canon", systemImage: "camera")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                HStack {
                    Text("\(store.selectedPhotoIDs.count) selected")
                        .font(.caption)
                    Spacer()
                    if !store.selectedPhotoIDs.isEmpty {
                        Button("Clear") {
                            store.choice.clear()
                        }
                        .controlSize(.mini)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(store.selectedPhotoIDs.count) selected")
                .accessibilityIdentifier("selectedCount")

                Picker("", selection: $store.filterMode) {
                    Text("All (\(store.targetPhotos.count))")
                        .tag(PhotoSession.FilterMode.all)
                    Text("Selected (\(store.selectedPhotoIDs.count))")
                        .tag(PhotoSession.FilterMode.selected)
                    let noGPS = store.targetPhotos.filter { !$0.hasValidCoordinate }.count
                    Text("No GPS (\(noGPS))")
                        .tag(PhotoSession.FilterMode.noGPS)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)

                if !store.statusMessage.isEmpty {
                    Text(store.statusMessage)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if store.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(10)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(scope.filteredPhotos()) { photo in
                            let isSelected = store.selectedPhotoIDs.contains(photo.id)
                            PhotoRow(photo: photo, isSelected: isSelected, store: store)
                                .id(photo.id)
                                .accessibilityIdentifier("photoRow_\(photo.filename)")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    isSelected
                                        ? Color.accentColor.opacity(0.2)
                                        : Color.clear
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.choice.selectFromList(photo.id)
                                }
                        }
                    }
                }
                .onChange(of: store.selectionVersion) { _, _ in
                    guard let firstID = store.selectedPhotoIDs.first else { return }
                    proxy.scrollTo(firstID, anchor: .center)
                }
            }
        }
        .accessibilityIdentifier("sidebar")
    }

    private func prepare() {
        if note == nil { note = ToolbarNote(store: store) }
        if panel == nil {
            let panel: SourcePanel = SourcePanel(store: store)
            panel.onPathsChanged = onPathsChanged
            self.panel = panel
        }
        if scope == nil { scope = PhotoScope(store: store) }
    }
}
