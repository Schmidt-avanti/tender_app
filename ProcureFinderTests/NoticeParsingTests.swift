import XCTest
@testable import ProcureFinder

final class NoticeParsingTests: XCTestCase {
    func testBuildExpertQuery() throws {
        var f = SearchFilters()
        f.text = "cloud"
        f.cpvCodes = ["30200000-1","72000000-5"]
        f.countries = ["DE","FR"]
        let q = NoticeRepository.buildExpertQuery(filters: f)
        XCTAssertTrue(q.contains("FT=\"cloud\""))
        XCTAssertTrue(q.contains("CPV IN (30200000-1 OR 72000000-5)"))
        XCTAssertTrue(q.contains("CY IN (DE OR FR)"))
    }
}
