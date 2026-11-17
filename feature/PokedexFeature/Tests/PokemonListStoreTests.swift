import Dependencies
import Domain
import Foundation
import Model
import Testing

@testable import PokedexFeature

@MainActor
struct PokemonListStoreTests {
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

    private func makeStore(
        execute: @escaping @Sendable (_ offset: Int) async throws -> PokemonPage
    ) -> PokemonListStore {
        withDependencies {
            $0.fetchPokemonPage.execute = execute
        } operation: {
            PokemonListStore()
        }
    }

    @Test("onAppear で先頭ページを読み込む") func onAppearLoadsFirstPage() async {
        let recorder = Recorder()
        let store = makeStore { offset in
            await recorder.record(offset)
            return Self.page(ids: 1..<21, hasNext: true)
        }

        await store.send(.onAppear)?.value

        #expect(await recorder.offsets == [0])
        #expect(store.state.items.map(\.id) == Array(1..<21))
        #expect(store.state.phase == .loaded)
        #expect(store.state.hasNext == true)
    }

    @Test("読み込み済みなら onAppear で再読み込みしない") func onAppearIgnoredWhenLoaded() async {
        let recorder = Recorder()
        let store = makeStore { offset in
            await recorder.record(offset)
            return Self.page(ids: 1..<21, hasNext: true)
        }
        await store.send(.onAppear)?.value

        await store.send(.onAppear)?.value

        #expect(await recorder.offsets == [0])
    }

    @Test("reachedBottom で次ページを読み、items に連結する") func reachedBottomLoadsNextPage() async {
        let recorder = Recorder()
        let store = makeStore { offset in
            await recorder.record(offset)
            return Self.page(ids: (offset + 1)..<(offset + 21), hasNext: true)
        }
        await store.send(.onAppear)?.value

        await store.send(.reachedBottom)?.value

        #expect(await recorder.offsets == [0, 20])
        #expect(store.state.items.map(\.id) == Array(1..<41))
        #expect(store.state.phase == .loaded)
    }

    @Test("hasNext が false なら reachedBottom は無視する") func reachedBottomIgnoredWithoutNext() async {
        let recorder = Recorder()
        let store = makeStore { offset in
            await recorder.record(offset)
            return Self.page(ids: 1..<21, hasNext: false)
        }
        await store.send(.onAppear)?.value

        let task = store.send(.reachedBottom)
        await task?.value

        #expect(task == nil)
        #expect(await recorder.offsets == [0])
        #expect(store.state.items.count == 20)
    }

    @Test("読み込み中の reachedBottom は無視する") func reachedBottomIgnoredWhileLoading() async {
        let recorder = Recorder()
        let store = makeStore { offset in
            await recorder.record(offset)
            return Self.page(ids: 1..<21, hasNext: true)
        }
        let first = store.send(.onAppear)
        #expect(store.state.phase == .loading)

        let second = store.send(.reachedBottom)
        await first?.value

        #expect(second == nil)
        #expect(await recorder.offsets == [0])
        #expect(store.state.items.count == 20)
    }

    @Test("初回の読み込みがキャンセルされたら、idle に戻る") func firstLoadCancellationReturnsToIdle() async {
        let recorder = Recorder()
        let store = makeStore { offset in
            await recorder.record(offset)
            throw CancellationError()
        }

        await store.send(.onAppear)?.value

        #expect(await recorder.offsets == [0])
        #expect(store.state.phase == .idle)
        #expect(store.state.items.isEmpty)
    }

    @Test("次ページの読み込みがキャンセルされたら、loaded に戻り items は維持する")
    func nextPageCancellationReturnsToLoaded() async {
        let recorder = Recorder()
        let store = makeStore { offset in
            await recorder.record(offset)
            if offset == 0 { return Self.page(ids: 1..<21, hasNext: true) }
            throw CancellationError()
        }
        await store.send(.onAppear)?.value

        await store.send(.reachedBottom)?.value

        #expect(await recorder.offsets == [0, 20])
        #expect(store.state.phase == .loaded)
        #expect(store.state.items.map(\.id) == Array(1..<21))
        #expect(store.state.hasNext == true)
    }

    @Test(
        "初回のエラーは phase が failed(LoadError) になる",
        arguments: [LoadError.offline, LoadError.unavailable])
    func firstLoadFailure(error: LoadError) async {
        let store = makeStore { _ in throw error }

        await store.send(.onAppear)?.value

        #expect(store.state.phase == .failed(error))
        #expect(store.state.items.isEmpty)
    }

    @Test("次ページのエラーでも、取得済みの items は維持する") func nextPageFailureKeepsItems() async {
        let store = makeStore { offset in
            if offset == 0 { return Self.page(ids: 1..<21, hasNext: true) }
            throw LoadError.offline
        }
        await store.send(.onAppear)?.value

        await store.send(.reachedBottom)?.value

        #expect(store.state.phase == .failed(.offline))
        #expect(store.state.items.map(\.id) == Array(1..<21))
    }

    @Test("retryTapped で初回の失敗をやり直す") func retryAfterFirstFailure() async {
        let recorder = Recorder()
        let store = makeStore { offset in
            await recorder.record(offset)
            if await recorder.offsets.count == 1 { throw LoadError.unavailable }
            return Self.page(ids: 1..<21, hasNext: true)
        }
        await store.send(.onAppear)?.value

        await store.send(.retryTapped)?.value

        #expect(await recorder.offsets == [0, 0])
        #expect(store.state.phase == .loaded)
        #expect(store.state.items.map(\.id) == Array(1..<21))
    }

    @Test("retryTapped で次ページの失敗をやり直す") func retryAfterNextPageFailure() async {
        let recorder = Recorder()
        let store = makeStore { offset in
            await recorder.record(offset)
            if await recorder.offsets.count == 2 { throw LoadError.unavailable }
            return Self.page(ids: (offset + 1)..<(offset + 21), hasNext: true)
        }
        await store.send(.onAppear)?.value
        await store.send(.reachedBottom)?.value

        await store.send(.retryTapped)?.value

        #expect(await recorder.offsets == [0, 20, 20])
        #expect(store.state.phase == .loaded)
        #expect(store.state.items.map(\.id) == Array(1..<41))
    }

    // MARK: - 名前の検索

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
        page(ids: 0..<0, hasNext: false).items
            + ids.map {
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
}
