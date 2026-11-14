// swift-tools-version: 6.2
// 依存ルールは docs/package-dependencies.md を参照。外部ライブラリは、最初に使う Issue で追加する。
import PackageDescription

let package = Package(
    name: "swift-pokedex",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        // App ターゲット（app/App.xcodeproj）がリンクするものだけを公開する。
        // SnapshotTestSupport は、ホストアプリ付きのテスト target（PokedexSnapshotTests）がリンクする
        .library(name: "PokedexFeature", targets: ["PokedexFeature"]),
        .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "NetworkClientURLSession", targets: ["NetworkClientURLSession"]),
        .library(name: "DatabaseSwiftData", targets: ["DatabaseSwiftData"]),
        .library(name: "DatastoreUserDefaults", targets: ["DatastoreUserDefaults"]),
        .library(name: "SnapshotTestSupport", targets: ["SnapshotTestSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.17.2"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.8.0"),
        .package(url: "https://github.com/kean/Nuke", from: "13.2.3"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.7"),
    ],
    targets: [
        // feature
        .target(
            name: "PokedexFeature",
            dependencies: [
                "Domain", "SharedUI", "DesignSystem", "Model", "Common",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            path: "feature/PokedexFeature/Sources"
        ),
        .testTarget(
            name: "PokedexFeatureTests",
            dependencies: [
                "PokedexFeature", "Domain", "Model", "TestSupport",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
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
            dependencies: [
                "Repository", "Model", "Common",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ],
            path: "core/Domain/Sources"
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: [
                "Domain", "Repository", "Model", "TestSupport",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            path: "core/Domain/Tests"
        ),
        .target(
            name: "Repository",
            dependencies: [
                "NetworkClient", "Database", "Datastore", "Model", "Common",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ],
            path: "core/Repository/Sources"
        ),
        .testTarget(
            name: "RepositoryTests",
            dependencies: [
                "Repository", "NetworkClient", "Model", "TestSupport",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            path: "core/Repository/Tests"
        ),
        .target(
            name: "DesignSystem",
            dependencies: [
                "Common",
                .product(name: "NukeUI", package: "Nuke"),
            ],
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
        // swift-snapshot-testing に依存してよいのは、この target だけ（ADR-0020）。
        .target(
            name: "SnapshotTestSupport",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "core/SnapshotTestSupport/Sources"
        ),

        // core: interface
        .target(
            name: "NetworkClient",
            dependencies: [
                "Common",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ],
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
            dependencies: [
                "NetworkClient",
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            path: "core/NetworkClientURLSession/Sources",
            resources: [
                // .copy: 生成した JSON と LICENSE の写しを加工せずそのまま同梱する。
                // .process は Xcode が種類ごとに変換することがあるので、中身がそのままアプリに入る .copy にする。
                // JSON は Bundle.module から名前で読む。
                .copy("../Resources/pokemon-species-names.json"),
                .copy("../Resources/POKEAPI-LICENSE.md"),
            ]
        ),
        .testTarget(
            name: "NetworkClientURLSessionTests",
            dependencies: ["NetworkClientURLSession", "NetworkClient", "TestSupport"],
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
