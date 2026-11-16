import Testing

@testable import SnapshotTestSupport

/// 参照画像の置き場所。テストのファイルの 1 つ上の `__Snapshots__` に、テストのファイル名のフォルダを作る。
struct SnapshotDirectoryTests {
    @Test func placesDirectoryNextToTestFolder() {
        let directory = SnapshotDirectory.path(
            forTestFile: "/work/app/PokedexSnapshotTests/PokemonDetailSnapshotTests.swift")
        #expect(directory == "/work/app/__Snapshots__/PokemonDetailSnapshotTests")
    }

    @Test func usesFileNameWithoutExtension() {
        let directory = SnapshotDirectory.path(forTestFile: "/a/b/Foo.swift")
        #expect(directory == "/a/__Snapshots__/Foo")
    }
}
