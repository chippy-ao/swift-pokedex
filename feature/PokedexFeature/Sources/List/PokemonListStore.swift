import Dependencies
import Domain
import Model
import Observation

@MainActor
@Observable
final class PokemonListStore {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(LoadError)
    }

    struct State: Equatable {
        var items: [PokemonSummary] = []
        var phase: Phase = .idle
        var hasNext = true
        var query = ""
        var searchResults: [PokemonSummary]?
        var searchError: LoadError?
    }

    enum Action {
        case onAppear
        case reachedBottom
        case retryTapped
        case queryChanged(String)
        case searchRetryTapped
    }

    private(set) var state = State()

    @ObservationIgnored
    @Dependency(\.fetchPokemonPage) private var fetchPokemonPage

    @ObservationIgnored
    @Dependency(\.searchPokemonByName) private var searchPokemonByName

    init() {}

    /// 読み込みを始めたときだけ、その Task を返す（無視した Action は nil）。
    @discardableResult
    func send(_ action: Action) -> Task<Void, Never>? {
        switch action {
        case .onAppear:
            guard state.phase == .idle else { return nil }
            return load(offset: 0)
        case .reachedBottom:
            // onAppear は何度も呼ばれるので、読み込み中と末尾の後は無視する。
            // 検索中は全件から探していて続きが無いので、これも無視する
            guard state.query.isEmpty, state.phase == .loaded, state.hasNext else { return nil }
            return load(offset: state.items.count)
        case .retryTapped:
            guard case .failed = state.phase else { return nil }
            return load(offset: state.items.count)
        case .queryChanged(let query):
            state.query = query
            guard !query.isEmpty else {
                // 空に戻したら、ページング一覧に戻る
                state.searchResults = nil
                return nil
            }
            return search(query)
        case .searchRetryTapped:
            return nil
        }
    }

    private func load(offset: Int) -> Task<Void, Never> {
        state.phase = .loading
        return Task {
            do {
                let page = try await fetchPokemonPage.execute(offset)
                state.items += page.items
                state.hasNext = page.hasNext
                state.phase = .loaded
            } catch is CancellationError {
                // キャンセルは失敗ではない。やり直せる状態に戻す
                state.phase = state.items.isEmpty ? .idle : .loaded
            } catch let error as LoadError {
                state.phase = .failed(error)
            } catch {
                state.phase = .failed(.unavailable)
            }
        }
    }

    /// 入力のたびに探す。端末内の表を絞るだけで一瞬なので、debounce も前の検索のキャンセルもしない。
    private func search(_ query: String) -> Task<Void, Never> {
        Task {
            do {
                let results = try await searchPokemonByName.execute(query)
                // 答えを待つ間に入力が変わっていたら、古い答えなので捨てる
                guard state.query == query else { return }
                state.searchResults = results
            } catch {
                // 端末内の表を読むだけなので、失敗は想定しない。前の結果を残し、エラー表示は出さない
            }
        }
    }
}
