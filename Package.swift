// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "OfficeViewer",
  platforms: [
    .macOS(.v12)
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-format.git",
      .branch("main")
    )
  ]
)
