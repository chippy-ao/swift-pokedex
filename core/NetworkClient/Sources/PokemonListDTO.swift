/// `GET /api/v2/pokemon?limit=&offset=` のレスポンス。PokeAPI の形にそのまま合わせる。
public struct PokemonListDTO: Codable, Equatable, Sendable {
    public struct Entry: Codable, Equatable, Sendable {
        public var name: String
        public var url: String

        public init(name: String, url: String) {
            self.name = name
            self.url = url
        }
    }

    public var count: Int
    public var next: String?
    public var previous: String?
    public var results: [Entry]

    public init(count: Int, next: String? = nil, previous: String? = nil, results: [Entry]) {
        self.count = count
        self.next = next
        self.previous = previous
        self.results = results
    }
}
