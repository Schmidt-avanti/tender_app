import XCTest
@testable import ProcureFinder

final class CPVFavoriteTests: XCTestCase {
    func testToggleFavorite() async {
        let repo = CPVRepository()
        await repo.loadCPV()
        let code = repo.all.first!.code
        repo.toggleFavorite(code: code)
        XCTAssertTrue(repo.favorites.contains(code))
        repo.toggleFavorite(code: code)
        XCTAssertFalse(repo.favorites.contains(code))
    }
}
