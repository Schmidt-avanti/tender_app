import XCTest

final class ProcureFinderUITests: XCTestCase {
    func testSmoke() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["ProcureFinder"].exists)
    }
}
