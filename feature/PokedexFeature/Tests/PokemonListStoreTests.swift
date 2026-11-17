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
}
