import Testing

@testable import SnapshotTestSupport

/// 参照画像の置き場所。リポジトリのルートの `feature/<feature 名>/__Snapshots__/<テストのファイル名>`。
/// リポジトリのルートは、テストのファイル（`app/<target>/X.swift`）の 2 つ上。
struct SnapshotDirectoryTests {
    @Test func placesDirectoryUnderFeature() {
        let directory = SnapshotDirectory.path(
            forTestFile: "/work/app/PokedexSnapshotTests/PokemonDetailSnapshotTests.swift",
            feature: "PokedexFeature")
        #expect(
            directory
                == "/work/feature/PokedexFeature/__Snapshots__/PokemonDetailSnapshotTests")
    }

    @Test func usesFileNameWithoutExtensionAndGivenFeature() {
        let directory = SnapshotDirectory.path(
            forTestFile: "/a/app/T/Foo.swift", feature: "SettingsFeature")
        #expect(directory == "/a/feature/SettingsFeature/__Snapshots__/Foo")
    }
}
