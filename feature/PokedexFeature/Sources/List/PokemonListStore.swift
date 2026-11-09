import Dependencies
import Domain
import Model
import Observation

@MainActor
@Observable
public final class PokemonListStore {
    public enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(LoadError)
    }

    public struct State: Equatable {
        public var items: [PokemonSummary] = []
        public var phase: Phase = .idle
        public var hasNext = true
    }

    public enum Action {
        case onAppear
        case reachedBottom
        case retryTapped
    }

    public private(set) var state = State()

    @ObservationIgnored
    @Dependency(\.fetchPokemonPage) private var fetchPokemonPage

    public init() {}

    // 実装前のスタブ。何もしない。
    @discardableResult
    public func send(_ action: Action) -> Task<Void, Never>? {
        nil
    }
}
