import XCTest
@testable import FitTwinApp

final class FitTwinAppTests: XCTestCase {
    func testContentViewProducesBody() throws {
        let view = ContentView()
        _ = view.body
        XCTAssertTrue(true)
    }
}
