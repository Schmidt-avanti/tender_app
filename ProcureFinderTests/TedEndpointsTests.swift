import XCTest
@testable import ProcureFinder

final class TedEndpointsTests: XCTestCase {
    func testLinks() {
        let html = TedEndpoints.htmlLink(publicationNumber: "1-2024").absoluteString
        XCTAssertTrue(html.contains("/notice/1-2024/html"))
        let pdf = TedEndpoints.pdfLink(publicationNumber: "1-2024").absoluteString
        XCTAssertTrue(pdf.contains("/notice/1-2024/pdf"))
    }
}
