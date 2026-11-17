import Foundation

/// 小さいドット絵の URL。REST のレスポンスには入っていないので、番号から作る。
/// 一覧（REST の結果）と、番号しか持たない名前の表の両方がこの作り方を使う。
package func pokemonSpriteURL(id: Int) -> URL {
    URL(
        string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
    )!
}
