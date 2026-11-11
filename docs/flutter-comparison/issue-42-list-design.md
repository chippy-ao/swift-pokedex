# #42 一覧画面のデザインと DesignSystem

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/42

一覧画面の見た目で初めて出てきたもの（`.redacted`、自作の shimmer、意味の名前の色、text style、`.glassProminent`、値の置き場）を、Dart / Flutter の同じ層のものと比べる学習ノートです。前の Issue で説明した言葉は [issue-07-pokemon-list.md](issue-07-pokemon-list.md) を見てください。

## Apple 標準

### redacted(reason: .placeholder) と skeletonizer

**何の話か:** 読み込み中に、行と同じ形の灰色の仮の行（スケルトン）を出す方法です。

**意味:** `.redacted(reason: .placeholder)` は、View の中身を灰色の塊に置き換えます。仮のデータで本物の行を作って包むだけで、スケルトン用の View を別に作らなくて済みます。Flutter の標準にはこれに当たるものが見つからないので、外部ライブラリの skeletonizer を使うのが普通です。skeletonizer も、既存のレイアウトを `Skeletonizer` で包み、`enabled` で切り替えます。

```swift
List(placeholderItems) { PokemonRow(pokemon: $0) }
    .redacted(reason: .placeholder)
```

```dart
Skeletonizer(
  enabled: isLoading,
  child: ListView(children: [for (final p in placeholderItems) PokemonRow(p)]),
);
```

**違いと間違えやすいところ:** どちらも、形を作るために仮のデータが要ります。skeletonizer は画像のように仮のデータで描けない部品に `Skeleton.replace` を使います。SwiftUI は、画像を読む部品が仮のデータでも通信しないよう、自分で気を付ける必要があります（このアプリでは読みに行かない URL を渡しています）。

**出典:** [redacted(reason:)](https://developer.apple.com/documentation/swiftui/view/redacted(reason:))、[skeletonizer（pub.dev）](https://pub.dev/packages/skeletonizer)

### 自作の shimmer と「動きを減らす」設定

**何の話か:** 斜めの光を流す表現と、動きを嫌う人への配慮です。

**意味:** SwiftUI には shimmer の標準の部品がありません。このアプリは `DesignSystem` に自作の modifier（`.shimmering()`）を持ち、`@Environment(\.accessibilityReduceMotion)` が `true` のときは動かしません。Flutter も shimmer は標準に無く、skeletonizer の `ShimmerEffect`（色と長さを設定できる）などを使います。動きを減らす設定は、Flutter では `MediaQueryData.disableAnimations` で読めます。

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
// true なら content をそのまま返し、アニメーションを始めない
```

```dart
final reduce = MediaQuery.of(context).disableAnimations;
if (reduce) return child; // 動かさない
```

**違いと間違えやすいところ:** Flutter の `disableAnimations` は、Android の「アニメーションを削除」に対応すると公式に書かれています。iOS の「視差効果を減らす」では立たないと書かれているので、iOS で同じ配慮をするには別の手段が要ります。skeletonizer が動きを減らす設定に従うかは、公式のページからは確かめられませんでした。

**出典:** [accessibilityReduceMotion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion)、[MediaQueryData.disableAnimations](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html)、[skeletonizer（pub.dev）](https://pub.dev/packages/skeletonizer)

### 意味の名前の色（Color(.secondarySystemBackground)、.secondary）と ColorScheme

**何の話か:** 色を hex で持たず、「背景の二番目」「弱い文字」のような役割の名前で持つ方法です。

**意味:** `Color(.secondarySystemBackground)` や `.secondary` は役割の名前で、ライト / ダークとコントラストの設定に合わせて実際の色が変わります。Flutter の近い仕組みは `ColorScheme` の役割（`surfaceContainer`、`onSurfaceVariant` など）で、`ColorScheme.of(context)` から引きます。

```swift
.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: CornerRadius.thumbnail))
Text(number).foregroundStyle(.secondary)
```

```dart
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainer,
    borderRadius: BorderRadius.circular(12),
  ),
);
Text(number, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant));
```

**違いと間違えやすいところ:** Flutter の `ColorScheme` は `brightness` を持つ 1 組の色なので、ダーク用は `ThemeData.darkTheme` などで別の組を渡します。UIKit 由来の `UIColor` の名前は OS が持っていて、アプリは何も渡しません。ただし 2 つの役割は 1 対 1 ではありません。`ColorScheme` が OS のダークモードに自動で従うかは、公式のページからは確かめられませんでした。

**出典:** [ColorScheme（Flutter）](https://api.flutter.dev/flutter/material/ColorScheme-class.html)、[Color（HIG）](https://developer.apple.com/design/human-interface-guidelines/color)

### text style（.headline）と Dynamic Type

**何の話か:** 文字の大きさを数値で指定せず、役割の名前で指定する方法です。

**意味:** `.headline` や `.footnote` は text style で、ユーザーが設定した文字サイズに追従（Dynamic Type）します。Flutter では `TextTheme` の `titleMedium`、`bodySmall` などが役割の名前で、文字サイズの設定は `MediaQueryData.textScaler` に入ります。

```swift
Text(name).font(.headline)
Text(number).font(.footnote.monospacedDigit())
```

```dart
Text(name, style: Theme.of(context).textTheme.titleMedium);
Text(number, style: Theme.of(context).textTheme.bodySmall);
```

**違いと間違えやすいところ:** `.headline` は Apple の text style の名前で、Material の `titleMedium` と同じ大きさとは限りません。対応は役割の見当付けです。`monospacedDigit()` は数字の幅を揃える指定で、番号の桁がそろいます。

**出典:** [Font](https://developer.apple.com/documentation/swiftui/font)、[TextTheme](https://api.flutter.dev/flutter/material/TextTheme-class.html)、[MediaQueryData.textScaler](https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html)

### .buttonStyle(.glassProminent)（Liquid Glass）

**何の話か:** 画面の主な操作ボタンを、目立つ見た目にする指定です。

**意味:** `.glassProminent` は iOS 26 以降の Liquid Glass のボタンの形で、再試行ボタンのような主な操作に使います。Flutter の `FilledButton` は「Save や Confirm のような重要な最後の操作」向けの、最も目立つボタンです。使いどころは近いです。

```swift
Button(.listRetryButton) { store.send(.retryTapped) }
    .buttonStyle(.glassProminent)
```

```dart
FilledButton(onPressed: retry, child: Text(l10n.listRetryButton));
```

**違いと間違えやすいところ:** Liquid Glass そのものに当たる Flutter 標準の部品は、公式のページで確かめられなかったので、ここには書きません。

**出典:** [glassProminent](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glassprominent)、[FilledButton](https://api.flutter.dev/flutter/material/FilledButton-class.html)

## Swift の言語機能

### 値の置き場（caseless enum の static let）と Dart の static const

**何の話か:** 余白などの値を 1 か所にまとめる書き方です。

**意味:** `Spacing` は case を持たない `enum` にして、`static let` で値を置きます。case が無いので、インスタンスを作れません。Dart では class に `static const` で置きます。

```swift
package enum Spacing {
    package static let medium: CGFloat = 12
}
```

```dart
class Spacing {
  static const double medium = 12;
}
```

**違いと間違えやすいところ:** Dart の class は誤って `Spacing()` と作れてしまうので、作れなくしたいときは private なコンストラクタを足します（その書き方は公式で確かめていないので、ここでは書きません）。Swift の `package` は同じパッケージ内だけに見せる修飾子で、Dart に同じ段階はありません（Dart は `_` で file 単位の private です）。Dart の定数は lowerCamelCase で書く、と公式にあります。

**出典:** [Classes（Dart）](https://dart.dev/language/classes)、[Access Control（Swift）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/)
