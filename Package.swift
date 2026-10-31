// swift-tools-version: 6.2
// 依存ルールは docs/package-dependencies.md を参照。外部ライブラリは、最初に使う Issue で追加する。
import PackageDescription

let package = Package(
    name: "swift-pokedex",
    platforms: [.iOS(.v26)],
    products: [
        // App ターゲット（app/Pokedex.xcodeproj）がリンクするものだけを公開する
        .library(name: "PokedexFeature", targets: ["PokedexFeature"]),
        .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "NetworkClientURLSession", targets: ["NetworkClientURLSession"]),
        .library(name: "DatabaseSwiftData", targets: ["DatabaseSwiftData"]),
        .library(name: "DatastoreUserDefaults", targets: ["DatastoreUserDefaults"]),
    ],
    targets: [
        // feature
        .target(
            name: "PokedexFeature",
            dependencies: ["Domain", "SharedUI", "DesignSystem", "Model", "Common"],
            path: "feature/PokedexFeature/Sources"
        ),
        .testTarget(
            name: "PokedexFeatureTests",
            dependencies: ["PokedexFeature", "TestSupport"],
            path: "feature/PokedexFeature/Tests"
        ),
        .target(
            name: "SettingsFeature",
            dependencies: ["Domain", "SharedUI", "DesignSystem", "Model", "Common"],
            path: "feature/SettingsFeature/Sources"
        ),
        .testTarget(
            name: "SettingsFeatureTests",
            dependencies: ["SettingsFeature", "TestSupport"],
            path: "feature/SettingsFeature/Tests"
        ),

        // core
        .target(
            name: "Common",
            path: "core/Common/Sources"
        ),
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common", "TestSupport"],
            path: "core/Common/Tests"
        ),
        .target(
            name: "Model",
            dependencies: ["Common"],
            path: "core/Model/Sources"
        ),
        .testTarget(
            name: "ModelTests",
            dependencies: ["Model", "TestSupport"],
            path: "core/Model/Tests"
        ),
        .target(
            name: "Domain",
            dependencies: ["Repository", "Model", "Common"],
            path: "core/Domain/Sources"
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain", "TestSupport"],
            path: "core/Domain/Tests"
        ),
        .target(
            name: "Repository",
            dependencies: ["NetworkClient", "Database", "Datastore", "Model", "Common"],
            path: "core/Repository/Sources"
        ),
        .testTarget(
            name: "RepositoryTests",
            dependencies: ["Repository", "TestSupport"],
            path: "core/Repository/Tests"
        ),
        .target(
            name: "DesignSystem",
            dependencies: ["Common"],
            path: "core/DesignSystem/Sources"
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem", "TestSupport"],
            path: "core/DesignSystem/Tests"
        ),
        .target(
            name: "SharedUI",
            dependencies: ["DesignSystem", "Model", "Common"],
            path: "core/SharedUI/Sources"
        ),
        .testTarget(
            name: "SharedUITests",
            dependencies: ["SharedUI", "TestSupport"],
            path: "core/SharedUI/Tests"
        ),
        .target(
            name: "TestSupport",
            dependencies: ["Model", "Common"],
            path: "core/TestSupport/Sources"
        ),

        // core: interface
        .target(
            name: "NetworkClient",
            dependencies: ["Common"],
            path: "core/NetworkClient/Sources"
        ),
        .testTarget(
            name: "NetworkClientTests",
            dependencies: ["NetworkClient", "TestSupport"],
            path: "core/NetworkClient/Tests"
        ),
        .target(
            name: "Database",
            dependencies: ["Model", "Common"],
            path: "core/Database/Sources"
        ),
        .testTarget(
            name: "DatabaseTests",
            dependencies: ["Database", "TestSupport"],
            path: "core/Database/Tests"
        ),
        .target(
            name: "Datastore",
            dependencies: ["Model", "Common"],
            path: "core/Datastore/Sources"
        ),
        .testTarget(
            name: "DatastoreTests",
            dependencies: ["Datastore", "TestSupport"],
            path: "core/Datastore/Tests"
        ),

        // core: 実装（依存してよいのは App ターゲットだけ）
        .target(
            name: "NetworkClientURLSession",
            dependencies: ["NetworkClient"],
            path: "core/NetworkClientURLSession/Sources"
        ),
        .testTarget(
            name: "NetworkClientURLSessionTests",
            dependencies: ["NetworkClientURLSession", "TestSupport"],
            path: "core/NetworkClientURLSession/Tests"
        ),
        .target(
            name: "DatabaseSwiftData",
            dependencies: ["Database", "Model"],
            path: "core/DatabaseSwiftData/Sources"
        ),
        .testTarget(
            name: "DatabaseSwiftDataTests",
            dependencies: ["DatabaseSwiftData", "TestSupport"],
            path: "core/DatabaseSwiftData/Tests"
        ),
        .target(
            name: "DatastoreUserDefaults",
            dependencies: ["Datastore"],
            path: "core/DatastoreUserDefaults/Sources"
        ),
        .testTarget(
            name: "DatastoreUserDefaultsTests",
            dependencies: ["DatastoreUserDefaults", "TestSupport"],
            path: "core/DatastoreUserDefaults/Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
