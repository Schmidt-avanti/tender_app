import XCTest
@testable import ProcureFinder

final class ResultsViewModelTests: XCTestCase {
    func testInitialState() {
        let vm = ResultsViewModel()
        XCTAssertTrue(vm.notices.isEmpty)
        XCTAssertFalse(vm.loading)
    }
}
