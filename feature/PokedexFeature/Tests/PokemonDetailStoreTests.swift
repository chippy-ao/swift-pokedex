import Dependencies
import Domain
import Foundation
import Model
import Testing

@testable import PokedexFeature

@MainActor
struct PokemonDetailStoreTests {
    private nonisolated static func detail(id: Int) -> PokemonDetail {
        PokemonDetail(
            id: id, name: "pokemon-\(id)", genus: "たねポケモン", types: [.grass, .poison],
            stats: [PokemonStat(kind: .hp, value: 45)], heightInMeters: 0.7,
            weightInKilograms: 6.9, artworkURL: URL(string: "https://example.com/\(id).png"))
    }

    private actor Recorder {
        private(set) var ids: [Int] = []
        func record(_ id: Int) { ids.append(id) }
    }

    private func makeStore(
        id: Int = 1,
        execute: @escaping @Sendable (_ id: Int) async throws -> PokemonDetail
    ) -> PokemonDetailStore {
        withDependencies {
            $0.fetchPokemonDetail.execute = execute
        } operation: {
            PokemonDetailStore(id: id)
        }
    }

    @Test("読み込む前は idle で、詳細は無い") func startsIdle() {
        let store = makeStore { Self.detail(id: $0) }

        #expect(store.state.phase == .idle)
        #expect(store.state.detail == nil)
    }

    @Test("onAppear で、Store の id の詳細を読み込む") func onAppearLoadsDetail() async {
        let recorder = Recorder()
        let store = makeStore(id: 25) { id in
            await recorder.record(id)
            return Self.detail(id: id)
        }

        await store.send(.onAppear)?.value

        #expect(await recorder.ids == [25])
        #expect(store.state.detail == Self.detail(id: 25))
        #expect(store.state.phase == .loaded)
    }

    @Test("読み込み中の phase は loading") func phaseIsLoadingWhileLoading() async {
        let store = makeStore { Self.detail(id: $0) }

        let task = store.send(.onAppear)
        #expect(store.state.phase == .loading)
        await task?.value
    }

    @Test("読み込み中と読み込み済みの onAppear は無視する（何度も呼ばれるため）")
    func onAppearIgnoredWhileLoadingAndAfterLoaded() async {
        let recorder = Recorder()
        let store = makeStore { id in
            await recorder.record(id)
            return Self.detail(id: id)
        }
        let first = store.send(.onAppear)

        let whileLoading = store.send(.onAppear)
        await first?.value
        let afterLoaded = store.send(.onAppear)

        #expect(whileLoading == nil)
        #expect(afterLoaded == nil)
        #expect(await recorder.ids == [1])
    }

    @Test(
        "失敗したら phase が failed(LoadError) になり、詳細は無いまま",
        arguments: [LoadError.offline, LoadError.unavailable])
    func failureBecomesFailed(error: LoadError) async {
        let store = makeStore { _ in throw error }

        await store.send(.onAppear)?.value

        #expect(store.state.phase == .failed(error))
        #expect(store.state.detail == nil)
    }

    @Test("LoadError 以外のエラーは unavailable の失敗にする") func unknownErrorBecomesUnavailable() async {
        struct Unknown: Error {}
        let store = makeStore { _ in throw Unknown() }

        await store.send(.onAppear)?.value

        #expect(store.state.phase == .failed(.unavailable))
    }

    @Test("キャンセルは失敗にしない。idle に戻して、あとで onAppear からやり直せる")
    func cancellationIsNotFailure() async {
        let recorder = Recorder()
        let store = makeStore { id in
            await recorder.record(id)
            if await recorder.ids.count == 1 { throw CancellationError() }
            return Self.detail(id: id)
        }

        await store.send(.onAppear)?.value
        #expect(store.state.phase == .idle)
        #expect(store.state.detail == nil)

        await store.send(.onAppear)?.value
        #expect(await recorder.ids == [1, 1])
        #expect(store.state.phase == .loaded)
    }

    @Test("retryTapped で失敗をやり直す") func retryAfterFailure() async {
        let recorder = Recorder()
        let store = makeStore { id in
            await recorder.record(id)
            if await recorder.ids.count == 1 { throw LoadError.offline }
            return Self.detail(id: id)
        }
        await store.send(.onAppear)?.value

        await store.send(.retryTapped)?.value

        #expect(await recorder.ids == [1, 1])
        #expect(store.state.phase == .loaded)
        #expect(store.state.detail == Self.detail(id: 1))
    }

    @Test("失敗していないときの retryTapped は無視する") func retryIgnoredWithoutFailure() async {
        let recorder = Recorder()
        let store = makeStore { id in
            await recorder.record(id)
            return Self.detail(id: id)
        }

        let beforeLoad = store.send(.retryTapped)
        await store.send(.onAppear)?.value
        let afterLoaded = store.send(.retryTapped)

        #expect(beforeLoad == nil)
        #expect(afterLoaded == nil)
        #expect(await recorder.ids == [1])
    }
}
