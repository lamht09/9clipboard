import Testing
@testable import ClipCore

@Test func versionIsSet() {
    #expect(!ClipCore.version.isEmpty)
}
