import XCTest
@testable import Pipes

final class PipesTests: XCTestCase {
    func testExample() {
        Dispatcher().run()
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
