import XCTest

/// 組み上げたアプリ（Pokedex.app）を起動し、一覧の名前がアプリの言語で出ることを確かめる。
/// 単体テストは各層を DI で差し替えるため、アプリ本体が言語を持っているか（Bundle.main の
/// preferredLocalizations）や、同梱の名前の表が実際につながっているかを見られない。そこを見る。
/// 一覧の通信だけは PokedexApp が固定のデータに差し替える（POKEDEX_UI_TEST_FIXTURE。CI で PokeAPI を叩かない）。
final class LocalizedNameUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testJapaneseShowsJapaneseNameInFirstRow() {
        assertFirstRowShows(language: "ja", name: "フシギダネ")
    }

    func testEnglishShowsEnglishNameInFirstRow() {
        assertFirstRowShows(language: "en", name: "Bulbasaur")
    }

    /// 指定の言語で起動し、一覧の 1 行目（cell）の中に名前の文字が出るのを待つ。
    /// 読み込み中も 1 行目の cell はあるので、cell の有無ではなく中の文字を待つ。
    /// 行の読み上げは 1 つの文字（名前と番号をまとめたラベル）になるので、ラベルの部分一致で探す。
    private func assertFirstRowShows(
        language: String, name: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))"]
        app.launchEnvironment["POKEDEX_UI_TEST_FIXTURE"] = "1"
        app.launch()
        let label = app.cells.firstMatch.staticTexts
            .containing(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
        XCTAssertTrue(
            label.waitForExistence(timeout: 15),
            "言語 \(language) の 1 行目に「\(name)」が出ていない\n\(app.debugDescription)",
            file: file, line: line)
    }
}
