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

    func testStreamLock() {
        let streamLock = StreamLock<String>()
        var sequence = [String]()

        DispatchQueue.global().async {
            streamLock.output("a")
            streamLock.output("b")
            streamLock.output("c")
        }
        
        Thread.sleep(forTimeInterval: 0.05)
        sequence.append(streamLock.readto())
        Thread.sleep(forTimeInterval: 0.1)
        sequence.append(streamLock.readto())
        Thread.sleep(forTimeInterval: 0.1)
        sequence.append(streamLock.readto())

        XCTAssertEqual(sequence, ["a", "b", "c"])
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
