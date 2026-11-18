import Dependencies
import Domain
import Foundation
import Model
import Testing

@testable import PokedexFeature

/// 一覧の名前検索（README の「検索の決めごと」）の Store のテスト。
@MainActor
struct PokemonListSearchTests {
    private nonisolated static func page(ids: Range<Int>, hasNext: Bool) -> PokemonPage {
        PokemonPage(
            items: ids.map {
                PokemonSummary(
                    id: $0, name: "pokemon-\($0)",
                    spriteURL: URL(string: "https://example.com/sprites/\($0).png")!)
            },
            hasNext: hasNext)
    }

    private actor Recorder {
        private(set) var offsets: [Int] = []
        func record(_ offset: Int) { offsets.append(offset) }
    }

    private func makeSearchStore(
        search: @escaping @Sendable (_ query: String) async throws -> [PokemonSummary],
        recorder: Recorder = Recorder()
    ) -> PokemonListStore {
        withDependencies {
            $0.fetchPokemonPage.execute = { offset in
                await recorder.record(offset)
                return Self.page(ids: 1..<21, hasNext: true)
            }
            $0.searchPokemonByName.execute = search
        } operation: {
            PokemonListStore()
        }
    }

    private nonisolated static func summaries(_ ids: [Int]) -> [PokemonSummary] {
        ids.map {
            PokemonSummary(
                id: $0, name: "found-\($0)",
                spriteURL: URL(string: "https://example.com/sprites/\($0).png")!)
        }
    }

    @Test("入力すると、その文字で探した結果が searchResults に入り、入力のたびに置き換わる")
    func queryChangedShowsSearchResults() async {
        let store = makeSearchStore { query in
            switch query {
            case "p": Self.summaries([25, 172, 4])
            case "pi": Self.summaries([25, 172])
            default: []
            }
        }
        await store.send(.onAppear)?.value

        await store.send(.queryChanged("p"))?.value
        #expect(store.state.query == "p")
        #expect(store.state.searchResults?.map(\.id) == [25, 172, 4])

        await store.send(.queryChanged("pi"))?.value
        #expect(store.state.query == "pi")
        #expect(store.state.searchResults?.map(\.id) == [25, 172])
        // 読み込み済みの一覧は触らない
        #expect(store.state.items.map(\.id) == Array(1..<21))
    }

    @Test("検索中の reachedBottom は無視して、次のページを読まない")
    func reachedBottomIgnoredWhileSearching() async {
        let recorder = Recorder()
        let store = makeSearchStore(
            search: { _ in Self.summaries([25]) }, recorder: recorder)
        await store.send(.onAppear)?.value
        await store.send(.queryChanged("pi"))?.value

        let task = store.send(.reachedBottom)
        await task?.value

        #expect(task == nil)
        #expect(await recorder.offsets == [0])
        #expect(store.state.items.count == 20)
    }

    @Test("検索を空に戻すと、読み込み済みの一覧に戻り、reachedBottom がまた効く")
    func clearingQueryReturnsToPagedList() async {
        let recorder = Recorder()
        let store = makeSearchStore(
            search: { _ in Self.summaries([25]) }, recorder: recorder)
        await store.send(.onAppear)?.value
        await store.send(.queryChanged("pi"))?.value
        #expect(store.state.searchResults?.map(\.id) == [25])

        await store.send(.queryChanged(""))?.value

        #expect(store.state.query == "")
        #expect(store.state.searchResults == nil)
        #expect(store.state.items.map(\.id) == Array(1..<21))
        await store.send(.reachedBottom)?.value
        #expect(await recorder.offsets == [0, 20])
    }

    @Test("一致が 0 件のときは、searchResults が nil ではなく空配列になる")
    func noMatchGivesEmptyResults() async {
        let store = makeSearchStore { _ in [] }
        await store.send(.onAppear)?.value

        await store.send(.queryChanged("zzz"))?.value

        #expect(store.state.searchResults?.isEmpty == true)
    }

    @Test("答えが返る前に空に戻したら、遅れて届いた答えは捨てる")
    func lateAnswerAfterClearIsDiscarded() async {
        let store = makeSearchStore { _ in
            try await Task.sleep(for: .milliseconds(100))
            return Self.summaries([25])
        }
        await store.send(.onAppear)?.value

        let slow = store.send(.queryChanged("pi"))
        await store.send(.queryChanged(""))?.value
        await slow?.value

        #expect(store.state.searchResults == nil)
    }

    private struct UnexpectedError: Error {}

    @Test(
        "検索が失敗したら searchError が入る（LoadError はそのまま、それ以外は unavailable）",
        arguments: [
            (LoadError.offline as Error, LoadError.offline),
            (LoadError.unavailable as Error, LoadError.unavailable),
            (UnexpectedError() as Error, LoadError.unavailable),
        ])
    func searchFailureSetsSearchError(thrown: Error, expected: LoadError) async {
        let store = makeSearchStore { _ in throw thrown }
        await store.send(.onAppear)?.value

        await store.send(.queryChanged("pi"))?.value

        #expect(store.state.searchError == expected)
        #expect(store.state.searchResults == nil)
    }

    @Test("再試行で成功したら結果が入り、searchError は nil に戻る")
    func searchRetrySucceeds() async {
        let calls = Recorder()
        let store = makeSearchStore { _ in
            await calls.record(0)
            if await calls.offsets.count == 1 { throw LoadError.offline }
            return Self.summaries([25])
        }
        await store.send(.onAppear)?.value
        await store.send(.queryChanged("pi"))?.value
        #expect(store.state.searchError == .offline)

        await store.send(.searchRetryTapped)?.value

        #expect(store.state.searchResults?.map(\.id) == [25])
        #expect(store.state.searchError == nil)
    }

    @Test("入力し直すと、前の失敗は消える")
    func queryChangedClearsSearchError() async {
        let store = makeSearchStore { query in
            if query == "p" { throw LoadError.offline }
            return Self.summaries([25])
        }
        await store.send(.onAppear)?.value
        await store.send(.queryChanged("p"))?.value
        #expect(store.state.searchError == .offline)

        await store.send(.queryChanged("pi"))?.value

        #expect(store.state.searchError == nil)
        #expect(store.state.searchResults?.map(\.id) == [25])
    }

    @Test("検索が CancellationError で終わっても、searchError は立てない")
    func searchCancellationIsNotAnError() async {
        let store = makeSearchStore { _ in throw CancellationError() }
        await store.send(.onAppear)?.value

        await store.send(.queryChanged("pi"))?.value

        #expect(store.state.searchError == nil)
    }

    @Test("答えを待つ間に入力が変わったら、遅れて届いた失敗は捨てる")
    func lateFailureIsDiscarded() async {
        let store = makeSearchStore { query in
            if query == "p" {
                try await Task.sleep(for: .milliseconds(100))
                throw LoadError.offline
            }
            return Self.summaries([25])
        }
        await store.send(.onAppear)?.value

        let slow = store.send(.queryChanged("p"))
        await store.send(.queryChanged("pi"))?.value
        await slow?.value

        #expect(store.state.searchError == nil)
        #expect(store.state.searchResults?.map(\.id) == [25])
    }

    @Test("p の答えが pi のあとに届いても、古い p の答えは捨てて pi の結果が残る")
    func staleAnswerArrivingAfterNewerOneIsDiscarded() async {
        let store = makeSearchStore { query in
            if query == "p" {
                try await Task.sleep(for: .milliseconds(100))
                return Self.summaries([4])
            }
            return Self.summaries([25])
        }
        await store.send(.onAppear)?.value

        let slow = store.send(.queryChanged("p"))
        await store.send(.queryChanged("pi"))?.value
        await slow?.value

        #expect(store.state.query == "pi")
        #expect(store.state.searchResults?.map(\.id) == [25])
    }
}
