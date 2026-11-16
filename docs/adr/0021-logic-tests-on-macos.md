# ADR-0021: ロジックのテストを macOS で回す

- ステータス: 承認済み
- 日付: 2026-11-15
- 関連: [ADR-0013](0013-ci-status-checks.md)（必須のステータスチェック）、[ADR-0020](0020-snapshot-tests-with-host-app.md)（スナップショットテスト）、[Issue #53](https://github.com/chippy-ao/swift-pokedex/issues/53)、[Issue #55](https://github.com/chippy-ao/swift-pokedex/issues/55)

## コンテキスト

CI の `build-test` が約 9 分かかっていた（#53）。測ると、テストそのものは合わせて 2 分弱で、残りはビルド約 2 分とシミュレーターの起動約 4 分だった。`Package.swift` の `platforms` が `.iOS(.v26)` だけで、ロジックのテストまで全部 iOS Simulator で走っていた。

試すと、Model / Domain / Repository / NetworkClient / Database / Datastore とその実装は、コードを変えずに macOS でビルドでき、テスト 63 件が通った。DesignSystem / SharedUI / SnapshotTestSupport / PokedexFeature は UIKit などに依存し、macOS ではビルドできない。

## 決定

- パッケージは 1 つのまま、`platforms` に `.macOS(.v26)` を足す。
- ロジックのテスト target だけを入れた共有 scheme `LogicTests` を作り、macOS で回す。UI のモジュールは入れない。
- CI は、ロジックのテストを毎回走らせる。ロジックだけを変えた PR は、iOS 向けのビルドだけを加え、画面を触った PR は iOS Simulator のテストも走らせる。
- PokedexFeature は Store と View を分けず、まるごと画面側として扱う。
- 対象の target、タスク、CI のジョブの細部は [development.md](../development.md#ロジックのテストと画面のテスト) を参照。

## 理由

- テストの時間を食っているのはテストそのものではなくシミュレーターなので、シミュレーターが要らない範囲を Mac で回すのが効く。手元では `LogicTests` がビルド込みで 26 秒だった。
- ロジックのモジュールに UIKit などが入ると、`LogicTests` の macOS 向けビルドで止まる。境界をコンパイラーが守る。
- パッケージを分けるより変更が小さい。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| パッケージを 2 つに分ける | モジュール間の宣言に付けた `package`（121 か所）がパッケージをまたいで見えなくなる（試すと SharedUI から `PokemonSummary` が見えず止まった）。`public` にすれば動くが、`Package.swift` 2 つ、依存チェック、`project.pbxproj` まで変わり、テストを速くするには大げさ |
| UI のコードを `#if canImport(UIKit)` で囲う | 囲い忘れで macOS のビルドが壊れる。境界をコンパイラーに守らせられない |
| シミュレーターを先に起動してビルドと並行させる | 遅くなった（15 分 16 秒、18 分 23 秒。変える前は 8 分 45 秒。#54） |
| Draft の PR ではテストを飛ばす | 上の決定で足りる見込みで、今は不要 |
| Store と View を別 target に分ける | Store だけを変える PR は少ない。必要になったら分ける |

## 影響

### 良い点

- ロジックのテストが、シミュレーターなしで数十秒で回る。
- ロジックだけを変えた PR は、シミュレーターを使わずに済む。

### 悪い点・注意点

- ロジックのテスト target を足したら、`Package.swift` と `AllTests.xctestplan` に加えて `LogicTests` scheme にも足す（足し忘れは機械で検出できない）。
- ロジックのモジュールに UIKit などが入ると、`LogicTests` の macOS 向けビルドで止まる。意図した効果。
- ロジックだけを変えた PR では、Model や Domain の変更で画面の見た目が変わっても、スナップショットは走らない（#55 で合意した割り切り）。

## 参考リンク

- [I made Xcode's tests 60 times faster](https://justin.searls.co/posts/i-made-xcodes-tests-60-times-faster)
