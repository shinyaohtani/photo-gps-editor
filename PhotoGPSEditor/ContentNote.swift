import Foundation

final class ToolbarNote {
    private unowned let store: PhotoSession

    init(store: PhotoSession) {
        self.store = store
    }

    func loadJSONHelp() -> String {
        if store.referencePhotos.isEmpty {
            return "Load JSON\niPhone 側の位置情報付き写真 JSON を読み込みます。\n補間の基準になる参照写真をまだ読み込んでいないときに使います。"
        }
        return "Reload JSON\n参照写真 JSON を読み込み直します。\niPhone 側の記録を差し替えたいときや、別日の移動ログで基準を更新したいときに使います。"
    }

    func loadCanonHelp() -> String {
        if store.targetPhotos.isEmpty {
            return "Load Canon Folder\nCanon 側の写真フォルダを読み込みます。\nGPS をこれから補間したい対象写真をまだ開いていないときに使います。"
        }
        return "Reload Canon Folder\nCanon 側の対象フォルダを読み込み直します。\n別フォルダへ切り替えたいときや、追加撮影分を反映したいときに使います。"
    }

    func timezoneHelp() -> String {
        "Canon Time Zone\nCanon 写真の撮影時刻をどのタイムゾーンとして解釈するかを指定します。\n補間結果が時間ずれしそうなときや、海外旅行分を扱うときに先に合わせてください。\n現在: \(store.canonTimezoneID)"
    }

    func interpolateHelp() -> String {
        if store.referencePhotos.isEmpty && store.targetPhotos.isEmpty {
            return "Interpolate GPS\niPhone の位置記録と Canon の撮影時刻を突き合わせて GPS を推定します。\nまず参照 JSON と Canon フォルダの両方を読み込んでから使います。"
        }
        if store.referencePhotos.isEmpty {
            return "Interpolate GPS\niPhone の位置記録が未読み込みのため実行できません。\nCanon 写真に GPS を付けたいときは、先に JSON を読み込んで基準点を用意してください。"
        }
        if store.targetPhotos.isEmpty {
            return "Interpolate GPS\nCanon 側の対象写真が未読み込みのため実行できません。\nGPS を付けたい写真フォルダを開いたあとに使います。"
        }
        if !store.selectedPhotoIDs.isEmpty {
            return "Re-Interpolate Selected\n選択中の Canon 写真だけを対象に、現在の GPS をいったん無視して時刻ベースで再計算します。\n一部の写真だけ補間し直したいときや、手修正前の位置へ戻して再調整したいときに使います。"
        }
        return "Interpolate GPS\niPhone の位置記録を使って、GPS がまだ無い Canon 写真の位置を推定します。\nCanon 写真に位置情報がなく、撮影時刻ベースで一括補完したいときに使います。"
    }

    func saveEXIFHelp() -> String {
        let count: Int = store.targetPhotos.filter { store.stamp.needsWrite($0) }.count
        if store.targetPhotos.isEmpty {
            return "Save GPS to EXIF\n補間または手修正した GPS を Canon 写真へ書き戻します。\nまず保存対象の Canon フォルダを読み込んでから使います。"
        }
        if count == 0 {
            return "Save GPS to EXIF\nCanon 写真は読み込まれていますが、未保存の GPS 変更はありません。\n「GPS無し→あり」または「既存 GPS から変更あり」の写真があるときに使います。"
        }
        return "Save GPS to EXIF\n変更がある Canon 写真 \(count) 枚へだけ EXIF を書き込みます。\n「GPS無し→あり」または「既存 GPS から変更あり」の結果をファイル本体へ保存したいときに使います。"
    }

    func removeGPSHelp() -> String {
        let withGPS: Int = store.targetPhotos.filter {
            store.selectedPhotoIDs.contains($0.id) && $0.hasValidCoordinate
        }.count
        if withGPS == 0 {
            return "Remove GPS\n選択中の Canon 写真から GPS を削除します。\nGPS 付きの Canon 写真を先に選択してください。"
        }
        return "Remove GPS\n選択中の Canon 写真 \(withGPS) 枚から GPS とタイムゾーン情報を削除します。\n元のファイルが上書きされます。"
    }
}
