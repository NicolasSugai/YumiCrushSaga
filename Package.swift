// swift-tools-version: 5.9
import PackageDescription

let engineTarget = Target.target(
    name: "YumiEngine",
    path: ".",
    sources: ["Domain", "Infrastructure/Random", "Infrastructure/Persistence"]
)
let applicationTarget = Target.target(
    name: "YumiApplication",
    dependencies: ["YumiEngine"],
    path: ".",
    sources: ["Application/State"]
)
#if os(Linux)
let packageProducts: [Product] = [.library(name: "YumiEngine", targets: ["YumiEngine"])]
let packageTargets: [Target] = [
    engineTarget,
    .testTarget(name: "YumiCrushSagaTests", dependencies: ["YumiEngine"], path: "Tests", sources: ["UnitTests", "IntegrationTests"])
]
#else
let applicationTestDependencies: [Target.Dependency] = ["YumiApplication"]
let packageProducts: [Product] = [
    .library(name: "YumiEngine", targets: ["YumiEngine"]),
    .library(name: "YumiApplication", targets: ["YumiApplication"])
]
let packageTargets: [Target] = [
    engineTarget,
    applicationTarget,
    .testTarget(name: "YumiCrushSagaTests", dependencies: ["YumiEngine"] + applicationTestDependencies, path: "Tests", sources: ["UnitTests", "IntegrationTests"])
]
#endif

let package = Package(
    name: "YumiCrushSaga",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: packageProducts,
    targets: packageTargets
)
