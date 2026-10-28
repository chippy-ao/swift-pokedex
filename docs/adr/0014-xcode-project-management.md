# ADR-0014: Xcode プロジェクトの管理方法

- ステータス: 承認済み
- 日付: 2026-10-28

## コンテキスト

[ADR-0005](0005-external-libraries.md) で XcodeGen / Tuist は「個人開発なので当面不要」としました。その後、AI と一緒に開発を進める前提で改めて検討しました。`project.pbxproj` は UUID を多く含む巨大なファイルで、AI が直接編集すると壊しやすいという懸念があります。

## 決定

- `app/Pokedex` の Xcode プロジェクトは、生成ツールを使わずに直接リポジトリで管理します。
- ソースのフォルダは buildable folder(Xcode 16 以降のフォルダ参照)にします。
- モジュールの追加や依存の変更は、すべてルートの `Package.swift` で行います([ADR-0003](0003-multi-module-structure.md))。Xcode プロジェクトはアプリの入口だけを持つ薄い殻にします。

運用上のルールは [development.md](../development.md#xcode-プロジェクト) に書きます。

## 理由

- buildable folder では、ファイルの追加・削除で `project.pbxproj` が変わりません。Xcode 16 のリリースノートでも、プロジェクトファイルの変更とコンフリクトを減らす機能として紹介されています。
- コードのほとんどは SwiftPM のパッケージにあるため、AI が触るのは主にテキストの `Package.swift` です。`project.pbxproj` を編集するのは署名や Capability などアプリの設定を変えるときだけです。
- XcodeGen はファイルを追加するたびに `xcodegen generate` で作り直す必要があります。作り直しを忘れると、ファイルがビルドに含まれない事故が起きます。
- Apple 標準の方式なので、追加のツールが要りません。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| XcodeGen | `project.yml` は AI が編集しやすいが、この構成では `project.pbxproj` の編集が少なく、作り直しの手間の方が大きい |
| Tuist | 大規模チーム向けの機能(キャッシュなど)が中心で、個人の学習用プロジェクトには過剰 |

## 影響

### 良い点

- ツールを追加せずに済み、Xcode の標準的な使い方を学べる。
- ファイルの追加でコンフリクトが起きにくい。

### 悪い点・注意点

- アプリ拡張(Widget など)でターゲットが増え、`project.pbxproj` の編集が頻繁になったら、XcodeGen への移行を新しい ADR で検討する。
- `project.pbxproj` を変更した PR では、Xcode で開けることを確認する必要がある(ルールは development.md)。

## 参考リンク

- [Xcode 16 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes)
- [yonaskolb/XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [tuist/tuist](https://github.com/tuist/tuist)
