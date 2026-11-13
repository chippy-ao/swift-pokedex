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

    init(id: Int) {
        self.id = id
    }

    /// 読み込みを始めたときだけ、その Task を返す（無視した Action は nil）。
    @discardableResult
    func send(_ action: Action) -> Task<Void, Never>? {
        // 仮の中身（テスト先行の段階。実装で置き換える）
        nil
    }
}
