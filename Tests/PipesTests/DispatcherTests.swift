import XCTest
@testable import Pipes

final class DispatcherTests: XCTestCase {
    func testExample() {
        let input = [ "a", "b", "c" ]
        let one = GeneratorStage(input)
        let two = PassthroughStage(count: input.count)
        let three = CheckerStage(input)
        Dispatcher().run(stages: [ one, two, three ])

        Thread.sleep(forTimeInterval: 1)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
