import NetworkClientURLSession
import Observation
import PokedexFeature
import SwiftUI

/// 図鑑タブの NavigationStack の path を持つ。画面と Route の対応は PokedexFeature が持ち、
/// ここは path を保持するだけ（PokedexFeature は Router を知らない）。
@MainActor
@Observable
final class Router {
    var path: [PokedexRoute] = []
}

// アプリの入口。実装モジュールのリンクと注入はここで行う（docs/package-dependencies.md）。
// NetworkClientURLSession は import するだけで、通信の liveValue が使われる。
@main
struct PokedexApp: App {
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            #if DEBUG
                // ホストアプリ付きのテスト（app/PokedexSnapshotTests）はこのアプリを起動してテストを読み込む。
                // 起動時に一覧が読み込みを始めると、テストの依存（testValue）が未実装として失敗を報告し、
                // 本物の通信も走りうる。単体テストの中では画面を作らない。
                // この環境変数は単体テストのプロセスだけに入る（UI テストで起動したアプリには入らない）。
                // Release には入れない。
                if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                    Color.clear
                } else {
                    root
                }
            #else
                root
            #endif
        }
    }

    private var root: some View {
        NavigationStack(path: $router.path) {
            PokemonListView()
                .pokedexDestinations()
        }
    }
}
