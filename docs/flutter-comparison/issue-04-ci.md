# #4 CI ワークフローを作る

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/4
- PR: https://github.com/chippy-ao/swift-pokedex/pull/24

PR のチェックを CI で動かした Issue です。CI の YAML や Renovate は言語に依らないので扱いません。ここでは、CI でテストを動かすときに出てくる Xcode 側の部品（Xcode のバージョンの選び方、`xcodebuild test`、シミュレーターの指定）だけを Flutter と比べます。

## 目次

- [Xcode のバージョンを選ぶ（`DEVELOPER_DIR`）](#xcode-のバージョンを選ぶdeveloper_dir)
- [コマンドラインでテストを動かす（`xcodebuild test`）](#コマンドラインでテストを動かすxcodebuild-test)
- [テストを動かすシミュレーターを選ぶ（`-destination`）](#テストを動かすシミュレーターを選ぶ-destination)
- [早見表](#早見表)

### Xcode のバージョンを選ぶ（`DEVELOPER_DIR`）

何の話か: 同じ Mac に Xcode が何個か入っているとき、どの Xcode でビルドするかを決める方法です。

意味:

- 環境変数 `DEVELOPER_DIR` に Xcode の場所を入れると、その Xcode が使われます。Mac 全体の設定（`xcode-select -s`）より優先されます。
- 理由は 2 つあります。コマンド 1 つ、ジョブ 1 つの範囲だけで Xcode を切り替えられること。Mac 全体の設定を書き換えずに済むことです。
- 例えるなら、`PATH` の先頭に別の Flutter SDK を置くようなものです。

Swift 側（このリポジトリの CI）:

```sh
DEVELOPER_DIR=/Applications/Xcode_27.2.app xcodebuild -version
```

CI では [ci.yml](../../.github/workflows/ci.yml) の `env` に同じ値を書いています（YAML の書き方は扱いません）。値は README の「動作環境」の Xcode と揃えます。

Dart 側（普段の Flutter で同じことをする書き方）:

```sh
# FVM で、プロジェクトごとに Flutter SDK のバージョンを固定する
fvm use 3.27.0
fvm flutter test
```

違いと間違えやすいところ:

- Flutter SDK は 1 バージョンずつ取得して切り替えられます。Xcode は Apple の配布物で、`/Applications` に置いたものから選ぶだけです。ランナーや Mac に入っていない版は選べません。
- `DEVELOPER_DIR` には、`Xcode.app` のパスと、その中の `Contents/Developer` のパスのどちらも書けます（`xcode-select` のマニュアルに書かれています）。このリポジトリは `.app` までのパスを書いています。
- Xcode と Swift のバージョンは対になっています。Xcode を変えると Swift コンパイラも変わります。Dart SDK が Flutter SDK に同梱されているのと似ています。
- Mac 全体の設定を変える `xcode-select -s` は、管理者権限が要り、ほかの作業にも影響します。環境変数なら、そのシェルやコマンドだけで済みます。

出典:

- [xcode-select(1)](https://keith.github.io/xcode-man-pages/xcode-select.1.html)（`DEVELOPER_DIR` の説明）
- [FVM](https://fvm.app/)

### コマンドラインでテストを動かす（`xcodebuild test`）

何の話か: Xcode の画面を開かずに、ターミナルから全部のテストを動かすコマンドです。

意味:

- `xcodebuild test` は、ビルドしてテストを実行するところまでを 1 コマンドで行います。Xcode の「Product > Test」と同じ処理です。
- 何を動かすかは、プロジェクト、スキーム、テストプランで決まります。このリポジトリでは、モジュールごとのテスト target をテストプラン `AllTests` にまとめて、1 回で全部動かします。
- 例えるなら、`flutter test` の「どの `test/` を走らせるか」を、ファイル名で自動で探す代わりに、設定ファイルで明示するようなものです。

Swift 側（このリポジトリのテスト）:

```sh
xcodebuild test \
  -project app/App.xcodeproj \
  -scheme Pokedex \
  -testPlan AllTests \
  -destination "${POKEDEX_TEST_DESTINATION}" \
  -skipMacroValidation
```

[mise.toml](../../mise.toml) の `tasks.test` で定義しています（実際は出力を整形するツールにつないでいますが、ここでは扱いません）。テストプランは [app/AllTests.xctestplan](../../app/AllTests.xctestplan) です。

Dart 側（普段の Flutter で同じことをする書き方）:

```sh
flutter test                      # test/ 以下を自動で探して全部動かす
flutter test test/model           # 範囲を絞るときはパスを渡す
```

違いと間違えやすいところ:

- `flutter test` は `test/` のファイルを自動で探します。`xcodebuild test` は、スキームとテストプランに登録した target しか動かしません。target を足したのにテストプランへ登録し忘れると、そのテストは動かないままになります。
- `flutter test` はホスト上の Dart VM で動き、デバイスを必要としません。`xcodebuild test` で iOS アプリのテストを動かすには、シミュレーターか実機が要ります（次の項目）。
- `-skipMacroValidation` は、Swift のマクロの検証（承認）を省くオプションです。理由は [mise.toml](../../mise.toml) のコメントにあります。Dart の `build_runner` のコード生成には、実行前の承認の仕組みがありません。

出典:

- [xcodebuild(1)](https://keith.github.io/xcode-man-pages/xcodebuild.1.html)（`-testPlan`、`-destination`、`test` アクション）
- [Running tests and viewing results（Apple）](https://developer.apple.com/documentation/xcode/running-tests-and-viewing-results)
- [Testing Flutter apps（Flutter）](https://docs.flutter.dev/testing/overview)
- [WWDC23 Expand on Swift macros（Apple）](https://developer.apple.com/videos/play/wwdc2023/10167/)（`-skipMacroValidation` の背景。オプション自体の説明は `xcodebuild -help`）

### テストを動かすシミュレーターを選ぶ（`-destination`）

何の話か: テストをどの端末（シミュレーター）の上で動かすかを、コマンドで指定する方法です。

意味:

- `-destination` に `platform=iOS Simulator,name=iPhone 17` のような `キー=値` を渡すと、その端末で動きます。
- 指定しないと、スキームに合う端末が選ばれます。このリポジトリでは、CI のイメージごとに入っている iPhone の名前が違うため、入っているものを調べて選ぶようにしています。
- 例えるなら、`flutter test -d <デバイス>` の `-d` です。

Swift 側（このリポジトリの既定の選び方）:

```sh
if [ -z "${POKEDEX_TEST_DESTINATION:-}" ]; then
  sim_name="$(xcrun simctl list devices available | grep -E '^ +iPhone' | sed -E 's/^ +//; s/ \([0-9A-F-]{36}\).*//' | tail -n 1)"
  POKEDEX_TEST_DESTINATION="platform=iOS Simulator,name=${sim_name}"
fi
```

[mise.toml](../../mise.toml) の `tasks.test` にあります。別の端末で動かしたいときは `POKEDEX_TEST_DESTINATION` を指定します。

Dart 側（普段の Flutter で同じことをする書き方）:

```sh
flutter devices                              # 使える端末の一覧
flutter test integration_test -d <デバイスID>   # 端末を指定して実行
```

違いと間違えやすいところ:

- `flutter test`（ユニットテストとウィジェットテスト）は端末を必要としません。端末を指定するのは `integration_test` のときだけです。`xcodebuild test` は、アプリ本体のテストでも端末を使います。
- Flutter の端末は `-d` にデバイス ID を渡します。Xcode は `キー=値` の組を渡し、`platform`、`name`、`id`、`OS` などを指定できます（`name` と `id` はどちらか一方だけ）。
- 端末の名前は Xcode の版で変わります。名前を固定すると、Xcode を上げたときに該当する端末が無くなる恐れがあるため、既定では入っているものから選んでいます。
- `xcrun simctl list devices available` は、`flutter devices` に近い一覧コマンドです。ただし、動かしていない端末も含めて、Xcode に入っているシミュレーターを全部出します。

出典:

- [xcodebuild(1)](https://keith.github.io/xcode-man-pages/xcodebuild.1.html)（Destinations の節）
- [Integration testing（Flutter）](https://docs.flutter.dev/testing/integration-tests)

## 早見表

| Swift / iOS | Dart / Flutter での相当 | 違い | このリポジトリで使っている場所 |
| --- | --- | --- | --- |
| `DEVELOPER_DIR`（使う Xcode を選ぶ） | FVM（`fvm use`）で Flutter SDK を固定 | Flutter SDK は版を指定して取得できる。Xcode は入っているものから選ぶだけ | [ci.yml](../../.github/workflows/ci.yml) |
| `xcodebuild test`（スキーム + テストプラン） | `flutter test` | Flutter は `test/` を自動で探す。Xcode は登録した target だけ動かす | [mise.toml](../../mise.toml) |
| `-destination`（シミュレーターの指定） | `flutter test integration_test -d` | Flutter のユニットテストは端末が要らない。Xcode は端末が要る | [mise.toml](../../mise.toml) |
| `xcrun simctl list devices available` | `flutter devices` | simctl は動いていない端末も含めて出す | [mise.toml](../../mise.toml) |
