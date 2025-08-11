import XCTest
@testable import ProcureFinder

final class NoticeModelTests: XCTestCase {
    func testNoticeEquatable() {
        let n1 = Notice(publicationNumber: "1", title: "A", country: "DE", procedure: nil, cpvTop: nil, budget: nil, publicationDate: nil)
        let n2 = Notice(publicationNumber: "1", title: "A", country: "DE", procedure: nil, cpvTop: nil, budget: nil, publicationDate: nil)
        XCTAssertNotEqual(n1.id, n2.id) // different UUID each
    }
}
