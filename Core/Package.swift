// swift-tools-version:6.0
import PackageDescription

// Pure Foundation, no UI, no SQLite, no third-party anything — so the rules
// that decide what the app shows can be tested on macOS in a second, with no
// simulator involved. See ../AGENTS.md.
let package = Package(
    name: "GymBuddyCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GymBuddyCore", targets: ["GymBuddyCore"]),
    ],
    targets: [
        .target(name: "GymBuddyCore"),
        .testTarget(name: "GymBuddyCoreTests", dependencies: ["GymBuddyCore"]),
    ]
)
