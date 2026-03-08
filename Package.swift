// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RetailRewardsRescuePackages",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Routing", targets: ["Routing"]),
        .library(name: "FeaturesOffers", targets: ["FeaturesOffers"]),
        .library(name: "NetworkingModern", targets: ["NetworkingModern"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "FeaturesSavedOffers", targets: ["FeaturesSavedOffers"])
    ],
    targets: [
        .target(
            name: "Core",
            path: "Packages/Core/Sources"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Packages/Core/Tests"
        ),
        .target(
            name: "DesignSystem",
            path: "Packages/DesignSystem/Sources"
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            path: "Packages/DesignSystem/Tests"
        ),
        .target(
            name: "Routing",
            path: "Packages/Routing/Sources"
        ),
        .testTarget(
            name: "RoutingTests",
            dependencies: ["Routing"],
            path: "Packages/Routing/Tests"
        ),
        .target(
            name: "FeaturesOffers",
            dependencies: ["Core"],
            path: "Packages/FeaturesOffers/Sources"
        ),
        .testTarget(
            name: "FeaturesOffersTests",
            dependencies: ["FeaturesOffers", "Core"],
            path: "Packages/FeaturesOffers/Tests"
        ),
        .target(
            name: "NetworkingModern",
            dependencies: ["Core", "FeaturesOffers"],
            path: "Packages/NetworkingModern/Sources"
        ),
        .testTarget(
            name: "NetworkingModernTests",
            dependencies: ["NetworkingModern", "FeaturesOffers", "Core"],
            path: "Packages/NetworkingModern/Tests"
        ),
        .target(
            name: "Persistence",
            dependencies: ["Core", "FeaturesOffers"],
            path: "Packages/Persistence/Sources"
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Persistence", "FeaturesOffers"],
            path: "Packages/Persistence/Tests"
        ),
        .target(
            name: "FeaturesSavedOffers",
            dependencies: ["FeaturesOffers"],
            path: "Packages/FeaturesSavedOffers/Sources"
        ),
        .testTarget(
            name: "FeaturesSavedOffersTests",
            dependencies: ["FeaturesSavedOffers", "FeaturesOffers"],
            path: "Packages/FeaturesSavedOffers/Tests"
        )
    ]
)
