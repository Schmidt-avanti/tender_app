import XCTest
@testable import ProcureFinder

final class L10nTests: XCTestCase {
    func testLocalizedKeysReturnString() {
        XCTAssertFalse(L10n.t(.searchTitle).isEmpty)
        XCTAssertFalse(L10n.t(.apply).isEmpty)
    }
}
