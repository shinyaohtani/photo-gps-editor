# Implementation Report

このレポートは、現在の `PhotoGPSEditor` 実装について、各型の責務とメソッド構成を簡潔に把握するためのものです。

- メソッド数は現在のソースから見た簡易カウントです。
- メソッド行数は、宣言行から対応する閉じ括弧までの行数です。
- 1 行 computed property や Apple 側プロトコル実装の一部は、簡易カウント上 0 件または省略になる場合があります。

## Session / Toolbar

### `PhotoSession`
- 責務: 編集中セッション全体の状態保持。写真集合、選択状態、ロード状態、補助オブジェクト群を持つ。
- メソッド数: 0
- メソッド: なし

### `FilterMode`
- 責務: サイドバーの表示対象切り替え。
- メソッド数: 0
- メソッド: なし

### `ContentView`
- 責務: 画面全体の SwiftUI 構成。ツールバー、サイドバー、地図の組み立て。
- メソッド数: 3
- メソッド:
  - `toolbarItems`: 45 行
  - `sidebar`: 83 行
  - `prepare`: 9 行

### `ToolbarNote`
- 責務: ツールバー各操作の詳細 tooltip 文言生成。
- メソッド数: 5
- メソッド:
  - `loadJSONHelp`: 6 行
  - `loadCanonHelp`: 6 行
  - `timezoneHelp`: 3 行
  - `interpolateHelp`: 15 行
  - `saveEXIFHelp`: 10 行

### `SourcePanel`
- 責務: 読み込み元選択 UI。JSON と Canon フォルダの open panel、および自動ロード。
- メソッド数: 3
- メソッド:
  - `openJSON`: 7 行
  - `openCanonFolder`: 8 行
  - `autoLoad`: 10 行

### `PhotoScope`
- 責務: サイドバー表示対象の絞り込み。
- メソッド数: 4
- メソッド:
  - `filteredPhotos`: 10 行
  - `allPhotos`: 3 行
  - `selectedPhotos`: 3 行
  - `noGPSPhotos`: 3 行

### `PhotoRow`
- 責務: サイドバー 1 行分の表示。
- メソッド数: 4
- メソッド:
  - `body`: 10 行
  - `thumb`: 16 行
  - `detail`: 14 行
  - `coord`: 13 行

## Loading / Parsing

### `PhotoInput`
- 責務: 参照 JSON と Canon 側データの非同期読み込み開始。
- メソッド数: 4
- メソッド:
  - `loadReferencePhotos`: 12 行
  - `loadTargetPhotos`: 11 行
  - `finishReferenceLoad`: 3 行
  - `finishTargetLoad`: 3 行

### `PhotoJson`
- 責務: 参照 JSON を `PhotoItem` 配列へ変換。
- メソッド数: 4
- メソッド:
  - `photos`: 3 行
  - `rows`: 7 行
  - `photo`: 10 行
  - `date`: 6 行

### `PhotoCanon`
- 責務: Canon 側ディレクトリから対象ファイル群を `PhotoItem` 配列へ変換。
- メソッド数: 4
- メソッド:
  - `photos`: 6 行
  - `files`: 3 行
  - `photo`: 13 行
  - `supports`: 3 行

### `LoadFlow`
- 責務: 読み込み完了後のセッション状態反映。
- メソッド数: 2
- メソッド:
  - `finishReferenceLoading`: 5 行
  - `finishTargetLoading`: 6 行

## Map / Selection

### `PhotoMap`
- 責務: AppKit 地図ビューの SwiftUI ラッパー。
- メソッド数: 0
- メソッド: なし

### `UndoPane`
- 責務: 地図に UndoManager を提供する AppKit コンテナ。
- メソッド数: 0
- メソッド: なし

### `MapBox`
- 責務: 地図コンテナの生成とレイアウト構築。
- メソッド数: 4
- メソッド:
  - `makeBox`: 6 行
  - `configure(mapView:...)`: 7 行
  - `configure(plane:...)`: 4 行
  - `activate`: 12 行

### `MapScene`
- 責務: 地図上の表示写真、注釈同期、フォーカス制御。
- メソッド数: 5
- メソッド:
  - `visiblePhotos`: 3 行
  - `referenceIDs`: 3 行
  - `syncAnnotations`: 19 行
  - `syncPins`: 6 行
  - `focus`: 9 行

### `MapGuide`
- 責務: 地図 delegate とキーボード・ホバー入力の仲介。
- メソッド数: 6
- メソッド:
  - `mapView`: 18 行
  - `referenceIDs`: 3 行
  - `handleUndo`: 16 行
  - `handlePreview`: 16 行
  - `handleHover`: 12 行
  - `updateSuspension`: 4 行

### `SelectionPlane`
- 責務: 地図上の矩形選択、ドラッグ移動、右クリック選択 UI の親ビュー。
- メソッド数: 10
- メソッド:
  - `hitTest`: 6 行
  - `scrollWheel`: 1 行
  - `magnify`: 1 行
  - `rotate`: 1 行
  - `mouseDown`: 21 行
  - `mouseDragged`: 9 行
  - `mouseUp`: 13 行
  - `rightMouseDown`: 6 行
  - `rightMouseUp`: 1 行
  - `draw`: 4 行

### `RectBand`
- 責務: 矩形選択の開始・更新・確定・描画。
- メソッド数: 6
- メソッド:
  - `isActive`: 1 行
  - `begin`: 5 行
  - `update`: 11 行
  - `beginIfNeeded`: 14 行
  - `finish`: 9 行
  - `draw`: 9 行

### `MoveDrag`
- 責務: Option+Drag による選択写真の移動。
- メソッド数: 5
- メソッド:
  - `prepare`: 5 行
  - `begin`: 12 行
  - `update`: 12 行
  - `finish`: 5 行
  - `reset`: 8 行

### `HitMap`
- 責務: 地図上の近傍ピン検出と矩形内ピン抽出。
- メソッド数: 4
- メソッド:
  - `nearest`: 9 行
  - `photos`: 7 行
  - `selectedIDs`: 7 行
  - `screenPoint`: 3 行

### `ChoicePop`
- 責務: 同一点写真群の選択用 popover 構築。
- メソッド数: 5
- メソッド:
  - `show`: 10 行
  - `close`: 3 行
  - `popoverBox`: 7 行
  - `contentSize`: 3 行
  - `anchorRect`: 3 行

### `PhotoChoiceView`
- 責務: popover 内の写真一覧とチェックボックス UI。
- メソッド数: 4
- メソッド:
  - `header`: 6 行
  - `rows`: 25 行
  - `toggle`: 6 行
  - `updateSelection`: 7 行

### `PinKey`
- 責務: MapKit 注釈ビューの reuse ID 保持。
- メソッド数: 0
- メソッド: なし

### `PinDot`
- 責務: 地図上ピンの見た目とホバー通知。
- メソッド数: 8
- メソッド:
  - `updateTrackingAreas`: 12 行
  - `mouseEntered`: 5 行
  - `mouseExited`: 5 行
  - `apply`: 10 行
  - `resize`: 7 行
  - `applyReference`: 7 行
  - `applyTarget`: 5 行
  - `applyStyle`: 5 行

## Preview / Media

### `PreviewPanel`
- 責務: 画像プレビューの表示状態、遅延表示、キーボード移動、再評価。
- メソッド数: 6
- メソッド:
  - `isSuspended`: 5 行
  - `isVisible`: 1 行
  - `show`: 17 行
  - `move`: 13 行
  - `reevaluate`: 7 行
  - `hide`: 10 行

### `PreviewFrame`
- 責務: 実際の NSPanel と画像ビューの生成・更新。
- メソッド数: 6
- メソッド:
  - `isVisible`: 1 行
  - `currentPanel`: 1 行
  - `panelBox`: 24 行
  - `update`: 13 行
  - `hide`: 4 行
  - `display`: 7 行

### `PreviewZone`
- 責務: マウス監視と、アンカー/パネル内判定。
- メソッド数: 5
- メソッド:
  - `ensure`: 7 行
  - `remove`: 6 行
  - `isInside`: 5 行
  - `mousePos`: 3 行
  - `panelRect`: 3 行

### `PreviewFit`
- 責務: プレビュー表示サイズの計算。
- メソッド数: 4
- メソッド:
  - `screen`: 3 行
  - `maxSize`: 4 行
  - `maxPixels`: 3 行
  - `fitted`: 5 行

### `PhotoFilm`
- 責務: サムネイルとプレビュー画像の取得窓口。
- メソッド数: 2
- メソッド:
  - `thumbnail`: 3 行
  - `previewImage`: 3 行

### `PhotoFrame`
- 責務: サムネイル/プレビュー画像のキャッシュと静止画・動画フレーム抽出。
- メソッド数: 6
- メソッド:
  - `thumbnail`: 7 行
  - `preview`: 8 行
  - `image`: 8 行
  - `stillImage`: 13 行
  - `videoImage`: 10 行
  - `cacheCost`: 1 行

## GPS / Time / Coordinate

### `PhotoTrail`
- 責務: 補間対象の決定、GPS 補間本体、移動コミット。
- メソッド数: 5
- メソッド:
  - `interpolationReferencePhotoIDs`: 6 行
  - `interpolateGPS`: 17 行
  - `commitMove`: 3 行
  - `references`: 3 行
  - `statusText`: 3 行

### `TrailScope`
- 責務: 補間対象 Canon 写真の範囲決定。
- メソッド数: 4
- メソッド:
  - `targets`: 5 行
  - `selectedTargetIDs`: 3 行
  - `hasSelection`: 3 行
  - `reset`: 5 行

### `TrailUndo`
- 責務: 補間と移動に対する Undo/Redo 登録。
- メソッド数: 4
- メソッド:
  - `registerInterpolation`: 9 行
  - `registerMove`: 11 行
  - `currentCoords`: 6 行
  - `pairs`: 3 行

### `EditFlow`
- 責務: 補間完了と移動 redo のセッション反映。
- メソッド数: 2
- メソッド:
  - `finishInterpolation`: 6 行
  - `registerMoveRedo`: 8 行

### `PhotoBlend`
- 責務: 時刻ベースの補間計算。
- メソッド数: 5
- メソッド:
  - `referenceIDs`: 16 行
  - `fill`: 9 行
  - `references`: 3 行
  - `marks`: 5 行
  - `coord`: 17 行

### `GPSStamp`
- 責務: GPS 書き込み対象判定と EXIF 書き込み。
- メソッド数: 6
- メソッド:
  - `saveGPSToEXIF`: 11 行
  - `needsWrite`: 5 行
  - `save`: 10 行
  - `write`: 9 行
  - `gpsArgs`: 8 行
  - `same`: 5 行

### `PhotoClock`
- 責務: 画像/動画の撮影日時抽出。
- メソッド数: 5
- メソッド:
  - `photoDate`: 6 行
  - `imageDate`: 8 行
  - `videoDate`: 16 行
  - `isImage`: 3 行
  - `format`: 6 行

### `PhotoPoint`
- 責務: 画像/動画の既存 GPS 抽出。
- メソッド数: 5
- メソッド:
  - `photoCoord`: 6 行
  - `imageCoord`: 14 行
  - `videoCoord`: 21 行
  - `isImage`: 3 行
  - `rows`: 6 行

## Photo Models

### `PhotoItem`
- 責務: 写真 1 件のモデル。MapKit annotation と表示用基本情報を保持。
- メソッド数: 0
- メソッド: なし

### `Source`
- 責務: 写真の出自。参照写真か対象写真かを表す。
- メソッド数: 0
- メソッド: なし

## App Entry

### `PhotoGPSEditorApp`
- 責務: アプリ起動と `PhotoSession` の注入。
- メソッド数: 0
- メソッド: なし
