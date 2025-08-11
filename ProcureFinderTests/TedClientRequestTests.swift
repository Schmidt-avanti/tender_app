import XCTest
@testable import ProcureFinder

final class TedClientRequestTests: XCTestCase {
    func testRequestEncoding() throws {
        let req = TedSearchRequest(query: "FT=*",
                                   page: 1,
                                   limit: 10,
                                   sort: "publication-date,desc",
                                   fields: ["ND","PD"])
        let data = try JSONEncoder().encode(req)
        let str = String(data: data, encoding: .utf8)!
        XCTAssertTrue(str.contains("\"query\":\"FT=*\""))
        XCTAssertTrue(str.contains("\"limit\":10"))
    }
}
