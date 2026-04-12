import SwiftUI
import UniformTypeIdentifiers

struct WelcomeView: View {
    var store: PhotoSession
    var onOpenJSON: () -> Void
    var onOpenCanon: () -> Void
    var onLoadJSON: (URL) -> Void
    var onLoadCanon: (URL) -> Void

    @State private var jsonTargeted = false
    @State private var canonTargeted = false

    private var hasReference: Bool { !store.referencePhotos.isEmpty }
    private var hasTarget: Bool { !store.targetPhotos.isEmpty }
    private var exiftoolAvailable: Bool {
        FileManager.default.isExecutableFile(atPath: "/opt/homebrew/bin/exiftool")
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            header
            dropZones
                .padding(.top, 28)
            Spacer()
            warnings
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "map")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("Photo GPS Editor")
                .font(.title2)
                .fontWeight(.semibold)
            Text("GPS のない写真に、別カメラの位置情報から GPS を付けるツールです")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Drop Zones

    private var dropZones: some View {
        HStack(spacing: 20) {
            jsonZone
            canonZone
        }
        .frame(maxWidth: 700)
        .padding(.horizontal, 40)
    }

    private var jsonZone: some View {
        let lastPath = UserDefaults.standard.string(forKey: SourcePanel.jsonPathKey)
        let missing = lastPath != nil && !FileManager.default.fileExists(atPath: lastPath!)
        return DropZoneBox(
            icon: "doc.text",
            title: "iPhone の位置記録 JSON",
            subtitle: hasReference ? nil : "位置情報付き写真の記録です",
            action: hasReference ? "別のファイルを選択" : "クリックまたはドロップ",
            state: zoneState(loaded: hasReference, lastPath: lastPath, missing: missing),
            loadedMessage: hasReference ? "\(store.referencePhotos.count) 枚の参照写真" : nil,
            loadedPath: hasReference ? lastPath : nil,
            missingPath: missing && !hasReference ? lastPath : nil,
            isTargeted: jsonTargeted,
            isLoading: store.isLoadingReference
        )
        .onTapGesture { onOpenJSON() }
        .onDrop(of: [.fileURL], isTargeted: $jsonTargeted) { providers in
            handleDrop(providers: providers, isJSON: true)
        }
    }

    private var canonZone: some View {
        let lastPath = UserDefaults.standard.string(forKey: SourcePanel.canonPathKey)
        let missing = lastPath != nil && !FileManager.default.fileExists(atPath: lastPath!)
        return DropZoneBox(
            icon: "folder",
            title: "Canon 写真フォルダ",
            subtitle: hasTarget ? nil : "GPS を付けたい写真のフォルダです",
            action: hasTarget ? "別のフォルダを選択" : "クリックまたはドロップ",
            state: zoneState(loaded: hasTarget, lastPath: lastPath, missing: missing),
            loadedMessage: hasTarget ? "\(store.targetPhotos.count) 枚の対象写真" : nil,
            loadedPath: hasTarget ? lastPath : nil,
            missingPath: missing && !hasTarget ? lastPath : nil,
            isTargeted: canonTargeted,
            isLoading: store.isLoadingTarget
        )
        .onTapGesture { onOpenCanon() }
        .onDrop(of: [.fileURL], isTargeted: $canonTargeted) { providers in
            handleDrop(providers: providers, isJSON: false)
        }
    }

    // MARK: - Warnings

    private var warnings: some View {
        VStack(spacing: 8) {
            if !exiftoolAvailable {
                warningBanner(
                    "exiftool が見つかりません。GPS の保存にはターミナルで brew install exiftool を実行してください。"
                )
            }
            if !store.statusMessage.isEmpty {
                Text(store.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }

    private func warningBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(10)
        .frame(maxWidth: 600)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.3)))
    }

    // MARK: - Helpers

    private func zoneState(loaded: Bool, lastPath: String?, missing: Bool) -> DropZoneState {
        if loaded { return .loaded }
        if missing { return .missing }
        if lastPath != nil { return .previousPath }
        return .empty
    }

    private func handleDrop(providers: [NSItemProvider], isJSON: Bool) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil)
            else { return }
            DispatchQueue.main.async {
                if isJSON {
                    UserDefaults.standard.set(url.path, forKey: SourcePanel.jsonPathKey)
                    onLoadJSON(url)
                } else {
                    UserDefaults.standard.set(url.path, forKey: SourcePanel.canonPathKey)
                    onLoadCanon(url)
                }
            }
        }
        return true
    }
}

// MARK: - Drop Zone State

enum DropZoneState {
    case empty
    case previousPath
    case missing
    case loaded
}

// MARK: - Drop Zone Box

struct DropZoneBox: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: String
    let state: DropZoneState
    let loadedMessage: String?
    let loadedPath: String?
    let missingPath: String?
    let isTargeted: Bool
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 12) {
            if state == .loaded {
                loadedContent
            } else if isLoading {
                loadingContent
            } else {
                emptyContent
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding(20)
        .background(background)
        .overlay(border)
    }

    private var emptyContent: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(isTargeted ? .accentColor : .secondary)
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            if state == .missing, let path = missingPath {
                VStack(spacing: 4) {
                    Text(URL(fileURLWithPath: path).lastPathComponent)
                        .font(.caption)
                        .strikethrough()
                        .foregroundColor(.secondary)
                    Text("見つかりません")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            Text(action)
                .font(.caption)
                .foregroundColor(.accentColor)
        }
    }

    private var loadedContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.green)
            if let message = loadedMessage {
                Text(message)
                    .font(.headline)
            }
            if let path = loadedPath {
                Text(URL(fileURLWithPath: path).lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Text(action)
                .font(.caption)
                .foregroundColor(.accentColor)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.regular)
            Text("読み込み中…")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isTargeted
                  ? Color.accentColor.opacity(0.08)
                  : Color(nsColor: .controlBackgroundColor))
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: state == .loaded ? [] : [6, 4])
            )
    }
}
