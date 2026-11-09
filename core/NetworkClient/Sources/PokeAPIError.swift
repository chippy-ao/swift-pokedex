/// NetworkClient が投げるエラー。通信方式（HTTP のステータスや URLError など）は漏らさず、
/// 使う側（Repository）が分けたい 2 種類だけにする。仕分けは実装側が行う。
/// キャンセルはエラーに変えず、そのまま投げる。
public enum PokeAPIError: Error, Equatable {
    /// 通信できない状態（機内モード、圏外など）。
    case offline
    /// 通信できたが取得できなかった（サーバーのエラー、形が違うレスポンスなど）。
    case unavailable
}
