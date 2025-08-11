import XCTest
@testable import ProcureFinder

final class SearchViewModelTests: XCTestCase {
    func testPreset() {
        let vm = SearchViewModel()
        vm.preset(days: 7)
        XCTAssertNotNil(vm.filters.dateFrom)
        XCTAssertNotNil(vm.filters.dateTo)
    }
}
