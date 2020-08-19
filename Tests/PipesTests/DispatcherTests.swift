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

    func testStreamLockReadto() {
        let streamLock = StreamLock<String>()
        var sequence = [String]()

        DispatchQueue.global().async {
            streamLock.output("a")
            streamLock.output("b")
            streamLock.output("c")
            streamLock.output("d")
            streamLock.output("e")
            streamLock.output("f")
        }

        sequence.append(streamLock.readto())
        sequence.append(streamLock.readto())
        sequence.append(streamLock.readto())
        sequence.append(streamLock.readto())
        sequence.append(streamLock.readto())
        sequence.append(streamLock.readto())

        XCTAssertEqual(sequence, ["a", "b", "c", "d", "e", "f"])
    }

    func testStreamLockReadtoSleep() {
        let streamLock = StreamLock<String>()
        var sequence = [String]()

        DispatchQueue.global().async {
            streamLock.output("a")
            streamLock.output("b")
            streamLock.output("c")
            streamLock.output("d")
            streamLock.output("e")
            streamLock.output("f")
        }

        Thread.sleep(forTimeInterval: 0.05)
        sequence.append(streamLock.readto())
        Thread.sleep(forTimeInterval: 0.1)
        sequence.append(streamLock.readto())
        sequence.append(streamLock.readto())
        Thread.sleep(forTimeInterval: 0.05)
        sequence.append(streamLock.readto())
        sequence.append(streamLock.readto())
        Thread.sleep(forTimeInterval: 0.1)
        sequence.append(streamLock.readto())

        XCTAssertEqual(sequence, ["a", "b", "c", "d", "e", "f"])
    }

    func testStreamLockPeekto() {
        let streamLock = StreamLock<String>()
        var sequence = [String]()

        DispatchQueue.global().async {
            streamLock.output("a")
            streamLock.output("b")
            streamLock.output("c")
            streamLock.output("d")
            streamLock.output("e")
            streamLock.output("f")
        }

        sequence.append(streamLock.readto())
        sequence.append(streamLock.peekto())
        sequence.append(streamLock.readto())
        sequence.append(streamLock.readto())
        sequence.append(streamLock.peekto())
        sequence.append(streamLock.peekto())
        sequence.append(streamLock.peekto())
        sequence.append(streamLock.readto())
        sequence.append(streamLock.readto())
        sequence.append(streamLock.readto())

        XCTAssertEqual(sequence, ["a", "b", "b", "c", "d", "d", "d", "d", "e", "f"])
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
