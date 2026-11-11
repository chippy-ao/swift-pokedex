# Swift と Dart / Flutter の比較ノート

Swift の言語機能と Apple 標準の部品を、Dart / Flutter の同じ層のものと比べる、自分用の学習ノートです。仕様やルールではありません。

## 入れる範囲

- Swift に関係することだけを入れます。Swift の言語機能、Apple 標準（Foundation、URLSession、Xcode など）、Swift のツール（swift-format、SwiftLint など）、Swift の外部ライブラリです。
- 言語に依らないツール（mise、prek、committed、GitHub Actions など）は入れません。
- 比べる相手は、言語は言語どうし、標準は標準どうし、外部ライブラリは外部ライブラリどうしです。Dart 側は普段のアプリ開発で使うものに合わせます。

## 書き方

- 1 Issue 1 ファイルで、その Issue で初めて出てきたものを書きます。ファイル名は `issue-<番号>-<名前>.md` です。
- 理解が進んだら、Issue ごとのファイルを分野ごとにまとめ直すことがあります。
- 前の Issue で説明した言葉は、書き直さずにその項目へリンクします。
- 1 項目は次の順に書きます。
  1. 何の話か
  2. 意味
  3. Swift のコード
  4. Dart のコード
  5. 違いと間違えやすいところ
  6. ダメな例（必要なときだけ）
  7. 出典（公式ドキュメントなど。推測で書かない）

## ノートの一覧

| Issue | ノート |
| --- | --- |
| #2 | [Package.swift とモジュールの骨組み](issue-02-package-structure.md) |
| #3 | [Lint と整形（swift-format と SwiftLint）](issue-03-lint.md) |
| #4 | [CI ワークフロー](issue-04-ci.md) |
| #6 | [NetworkClient と API の共通部分](issue-06-network-client.md) |
| #7 | [ポケモン一覧](issue-07-pokemon-list.md) |
| #38 | [文字列の多言語対応（String Catalog）](issue-38-localization.md) |
| #42 | [一覧画面のデザインと DesignSystem](issue-42-list-design.md) |

## 外部ライブラリの対応表

すでに別のドキュメントにある対応は、コピーせずにリンクします。

- モジュールごとの対応: [モジュール一覧](../package-dependencies.md#モジュール一覧)の「Flutter 版で相当するパッケージ」列
- ライブラリの対応: [Flutter のよく使うパッケージとの対応](../package-dependencies.md#flutter-のよく使うパッケージとの対応)
