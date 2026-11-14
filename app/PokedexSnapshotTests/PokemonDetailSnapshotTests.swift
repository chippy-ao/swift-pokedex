import SnapshotTestSupport
import Testing

@testable import Pokedex

/// 詳細画面を、場面（PokemonDetailScenario）ごとに、ライトとダークで撮って参照画像と比べる。
/// 場面を足せば、ここも自動で増える。撮り方と環境の固定は assertScreenSnapshots を参照。
@MainActor
struct PokemonDetailSnapshotTests {
    @Test func scenarios() async {
        let screens = await SnapshotScreens.pokemonDetail()
        // 場面が空だと比べるものが無く、何も撮らずに通ってしまう。撮る場面がそろっているかを先に確かめる。
        // loading は撮らない（理由は SnapshotScreens）。場面を足したら、ここにも足す。
        #expect(screens.map(\.name).sorted() == ["errorOffline", "loaded"])
        for screen in screens {
            assertScreenSnapshots(
                of: screen.view,
                // 場面ごとに画像の名前を分ける（既定の #function だと全部同じ名前になる）
                testName: screen.name)
        }
    }
}
