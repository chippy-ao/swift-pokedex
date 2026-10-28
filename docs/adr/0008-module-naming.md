# ADR-0008: モジュール命名規約

- ステータス: 承認済み
- 日付: 2026-10-27

## コンテキスト

Swift のモジュール名は import 時に名前空間として使われます。Apple SDK や標準ライブラリと同じ名前を付けると、型やモジュールの参照が曖昧になったり、意図しないモジュールを import したりします。

## 決定

Apple SDK や標準ライブラリのモジュール名・型名と衝突する名前を避けます。

| 避ける名前 | 衝突先 | 採用する名前 |
| --- | --- | --- |
| Network | Network.framework | NetworkClient |
| Data | Foundation.Data | Repository(Now in Android / Flutter 版の `core/data` に相当) |
| Testing | Swift Testing | TestSupport |
| UI | 汎用的すぎる | SharedUI |

追加のルール:

- `CoreXxx` という接頭辞は CoreData などの Apple フレームワークと紛らわしいので付けません。
- feature は `XxxFeature` とします。
- ディレクトリ名 = target 名とします。
- 実装モジュールは「interface 名 + 技術名」とします(`NetworkClientURLSession`、`DatabaseSwiftData`、`DatastoreUserDefaults`)。

## 理由

- 衝突を最初から避けると、後からのリネームや曖昧さの解消が不要になります。
- ディレクトリ名と target 名を揃えると、`Package.swift` の `path` 指定を探しやすくなります。
- 実装モジュール名に技術名を含めると、差し替え可能な実装であることが名前から分かります([ADR-0004](0004-dependency-injection.md))。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| `Network` / `Data` / `Testing` / `UI` をそのまま使う | Apple SDK・標準ライブラリ・Swift Testing と衝突、または汎用的すぎる |
| `CoreNetwork` のような `Core` 接頭辞 | CoreData などの Apple フレームワークと紛らわしい |
| ディレクトリ名と target 名を変える | 対応を覚える負担が増える |

## 影響

### 良い点

- import 文が曖昧にならない。
- 命名規則が機械的で、新しいモジュールの名前に迷わない。

### 悪い点・注意点

- `Repository` は Flutter 版の `core/data` と名前が異なるため、対応を意識する必要がある。
- 新しいモジュールを追加するときも、Apple SDK との衝突を確認する。

## 参考リンク

- [Now in Android のモジュール化](https://github.com/android/nowinandroid/blob/main/docs/ModularizationLearningJourney.md)
- [Apple Swift Testing](https://developer.apple.com/documentation/testing)
