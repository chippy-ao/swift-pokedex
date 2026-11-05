/// PokeAPI へのリクエストで NetworkClient 自身が投げるエラー。
///
/// URLSession は 2xx 以外のステータスでも投げないため、実装側が 2xx 以外のときにこれを投げる。
/// `URLError` と `DecodingError` は包まずそのまま投げる。画面に見せる形への変換は Repository が行う。
public enum PokeAPIError: Error, Equatable {
    case httpStatus(Int)
}
