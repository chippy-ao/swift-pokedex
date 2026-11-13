/// 画面に見せるための読み込みエラー。feature から見えるエラーはこれだけ。
///
/// 画面で出し分けるのは「オフラインかどうか」だけなので、2 種類にしている。
package enum LoadError: Error, Equatable {
    case offline
    case unavailable
}
