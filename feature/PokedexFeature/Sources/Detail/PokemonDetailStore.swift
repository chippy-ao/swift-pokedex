import Dependencies
import Domain
import Model
import Observation

@MainActor
@Observable
final class PokemonDetailStore {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(LoadError)
    }

    struct State: Equatable {
        var detail: PokemonDetail?
        var phase: Phase = .idle
    }

    enum Action {
        case onAppear
        case retryTapped
    }

    private(set) var state = State()

    private let id: Int

    @ObservationIgnored
    @Dependency(\.fetchPokemonDetail) private var fetchPokemonDetail

    init(id: Int) {
        self.id = id
    }

    /// 読み込みを始めたときだけ、その Task を返す（無視した Action は nil）。
    @discardableResult
    func send(_ action: Action) -> Task<Void, Never>? {
        switch action {
        case .onAppear:
            // onAppear は何度も呼ばれるので、読み込み中と読み込み済みは無視する
            guard state.phase == .idle else { return nil }
            return load()
        case .retryTapped:
            guard case .failed = state.phase else { return nil }
            return load()
        }
    }

    private func load() -> Task<Void, Never> {
        state.phase = .loading
        return Task {
            do {
                state.detail = try await fetchPokemonDetail.execute(id)
                state.phase = .loaded
            } catch is CancellationError {
                // キャンセルは失敗ではない。onAppear からやり直せる状態に戻す
                state.phase = .idle
            } catch let error as LoadError {
                state.phase = .failed(error)
            } catch {
                state.phase = .failed(.unavailable)
            }
        }
    }
}
