import XCTest
@testable import ProcureFinder

final class QueryBuilderDateRangeTests: XCTestCase {
    func testDateRange() {
        var f = SearchFilters()
        f.dateFrom = ISO8601DateFormatter().date(from: "2024-01-01T00:00:00Z")
        f.dateTo = ISO8601DateFormatter().date(from: "2024-02-01T00:00:00Z")
        let q = NoticeRepository.buildExpertQuery(filters: f)
        XCTAssertTrue(q.contains("PD=[2024-01-01 TO 2024-02-01]"))
    }
}
