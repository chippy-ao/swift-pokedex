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
    }

    enum Action {
        case onAppear
        case reachedBottom
        case retryTapped
    }

    private(set) var state = State()

    @ObservationIgnored
    @Dependency(\.fetchPokemonPage) private var fetchPokemonPage

    init() {}

    /// 読み込みを始めたときだけ、その Task を返す（無視した Action は nil）。
    @discardableResult
    func send(_ action: Action) -> Task<Void, Never>? {
        switch action {
        case .onAppear:
            guard state.phase == .idle else { return nil }
            return load(offset: 0)
        case .reachedBottom:
            // onAppear は何度も呼ばれるので、読み込み中と末尾の後は無視する
            guard state.phase == .loaded, state.hasNext else { return nil }
            return load(offset: state.items.count)
        case .retryTapped:
            guard case .failed = state.phase else { return nil }
            return load(offset: state.items.count)
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
}
