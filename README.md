# Plain

macOS 向けのシンプルな TODO アプリ。今日と明日にフォーカス。Widget でメニューバー外からも操作できる。

> **α 配布中**。本体は機能するが UX は荒い。フィードバック歓迎。

## 入手方法

### A. ソースからビルド（推奨）

Widget を含めて確実に動かすにはこちらを推奨します。

#### 必要なもの
- macOS 15 (Sequoia) 以上
- Xcode 16.3 以上
- Apple ID（**無料アカウントで OK**、Developer Program は不要）

#### 手順

```bash
git clone https://github.com/MACHII-Kaisei/plain.git
cd plain
open Plain.xcodeproj
```

Xcode で:

1. **左ペインで `Plain` プロジェクトを選択 → `TARGETS`**
2. 以下の2ターゲットそれぞれで **Signing & Capabilities タブ → Team** を**自分の Apple ID（Personal Team）** に設定
   - `Plain`
   - `PlainWidgetExtension`
3. **Product → Archive**
4. Organizer で **Distribute App → Copy App** → 任意の場所に書き出し
5. 出力された `Plain.app` を `/Applications` にドラッグ
6. 初回起動: 右クリック → 「開く」
7. 通知センター → ウィジェット編集から Plain を追加

#### CLI（任意）

ターミナルからタスクを操作したい場合は、Swift Package を別ビルド:

```bash
cd PlainCLI
swift build -c release
cp .build/release/plain ~/.local/bin/   # PATH 上の任意の場所へ
```

#### よくあるエラー
- **`Failed to register bundle identifier`** — Bundle ID が他で使われています。`Plain.xcodeproj/project.pbxproj` の `PRODUCT_BUNDLE_IDENTIFIER` を `app.plain.Plain` から自分の好きな値（例: `com.yourname.Plain`）に置換してください。App Group ID も同様。
- **Widget がメニューに出ない** — アプリを1度起動した後、再度ウィジェット編集を開いてください。

### B. DMG をインストール（フォールバック）

Xcode を入れたくない人向け。Widget が不安定な場合があります。

[GitHub Releases](https://github.com/MACHII-Kaisei/plain/releases) から最新の `Plain-x.y.z.dmg` をダウンロードし、[`docs/install.md`](docs/install.md) の手順に従ってください。

## 機能

- 今日 / 明日のタスク管理
- タグ・フィルタ・並び替え・一括操作
- Interactive Widget（Today / Large）
- メニューバーアプリ
- CLI ツール `plain`（`PlainCLI` ターゲット）

## データ保存先

- 本体: `~/Library/Group Containers/group.app.plain.Plain/`
- v0.1.3 以前を使っていた場合は旧 App Group (`group.com.KaiseiMachii.Plain`) からデータを自動移行します

## 開発

- 言語: Swift / SwiftUI
- データ層: SwiftData（ローカル）
- ターゲット構成: `Plain` / `PlainWidgetExtension` / `PlainCLI` + `PlainCore`（Swift Package）
- 開発ドキュメント: `docs/specs/`

## ライセンス

未定（α 期間中は再配布不可）。
