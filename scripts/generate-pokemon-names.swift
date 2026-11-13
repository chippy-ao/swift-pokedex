// ポケモン名の表（en / ja-hrkt）を PokeAPI のリポジトリの CSV から作る。
// 使い方: mise run generate-pokemon-names（中身は `swift scripts/generate-pokemon-names.swift`）。
//
// 作り直すとき:
// 1. 下の pokeAPICommitSHA を新しいコミット SHA に上げる。
// 2. mise run generate-pokemon-names を流す。
// 3. できた JSON と POKEAPI-LICENSE.md の diff を確かめてコミットする。
//
// 表と LICENSE は core/NetworkClientURLSession/Resources/ に出す。ビルドのたびに通信はしない。
// 背景は Issue #44 を参照。
import Foundation

let pokeAPICommitSHA = "e5b5b99d3310cddda53ade8216b1282657ec947d"

let rawBase = "https://raw.githubusercontent.com/PokeAPI/pokeapi/\(pokeAPICommitSHA)"
let csvURL = URL(string: "\(rawBase)/data/v2/csv/pokemon_species_names.csv")!
let licenseURL = URL(string: "\(rawBase)/LICENSE.md")!
let outputDirectory = "core/NetworkClientURLSession/Resources"

// languages.csv の local_language_id。1 が ja-hrkt（かな・カナ）、9 が en。
let languageCodes: [Int: String] = [1: "ja-hrkt", 9: "en"]

struct SpeciesEntry: Encodable {
    let id: Int
    // JSONEncoder の .sortedKeys でキーの順が決まる（en、ja-hrkt）。
    var names: [String: String]
}

func fetch(_ url: URL) throws -> String {
    let data = try Data(contentsOf: url)
    guard let text = String(data: data, encoding: .utf8) else {
        throw NSError(
            domain: "generate", code: 1, userInfo: [NSLocalizedDescriptionKey: "UTF-8 ではない: \(url)"]
        )
    }
    return text
}

/// 引用符つきのフィールドに対応した 1 行分の CSV 分解。
func parseCSVLine(_ line: String) -> [String] {
    var fields: [String] = []
    var current = ""
    var inQuotes = false
    var iterator = line.makeIterator()
    var pending = iterator.next()
    while let char = pending {
        pending = iterator.next()
        if inQuotes {
            if char == "\"" {
                if pending == "\"" {
                    current.append("\"")
                    pending = iterator.next()
                } else {
                    inQuotes = false
                }
            } else {
                current.append(char)
            }
        } else if char == "\"" {
            inQuotes = true
        } else if char == "," {
            fields.append(current)
            current = ""
        } else {
            current.append(char)
        }
    }
    fields.append(current)
    return fields
}

let csv = try fetch(csvURL)
var entries: [Int: SpeciesEntry] = [:]
for line in csv.split(whereSeparator: \.isNewline).dropFirst() {
    let fields = parseCSVLine(String(line))
    guard fields.count >= 3,
        let speciesID = Int(fields[0]),
        let languageID = Int(fields[1]),
        let code = languageCodes[languageID]
    else { continue }
    entries[speciesID, default: SpeciesEntry(id: speciesID, names: [:])].names[code] = fields[2]
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
let json = try encoder.encode(entries.values.sorted { $0.id < $1.id })

try FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)
try (json + Data("\n".utf8)).write(
    to: URL(fileURLWithPath: "\(outputDirectory)/pokemon-species-names.json"))

let licenseHeader = """
    # PokeAPI のライセンス

    - 元: \(licenseURL.absoluteString)
    - コミット SHA: \(pokeAPICommitSHA)
    - このディレクトリの pokemon-species-names.json は上の LICENSE の対象で、このリポジトリの MIT ライセンスの対象外。
      ポケモンの名前は Nintendo の商標。

    以下は元の LICENSE.md の写し。

    ---


    """
let license = try fetch(licenseURL)
try (licenseHeader + license).write(
    toFile: "\(outputDirectory)/POKEAPI-LICENSE.md", atomically: true, encoding: .utf8)

print("species: \(entries.count)")
