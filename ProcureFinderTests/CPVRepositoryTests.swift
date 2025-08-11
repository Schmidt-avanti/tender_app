import XCTest
@testable import ProcureFinder

final class CPVRepositoryTests: XCTestCase {
    func testSearch() async {
        let repo = CPVRepository()
        await repo.loadCPV()
        XCTAssertFalse(repo.all.isEmpty)
        let res = repo.search("software")
        XCTAssertTrue(res.contains(where: { $0.code == "48000000-8" }))
    }
}
