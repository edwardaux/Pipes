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
            try! streamLock.output("a")
            try! streamLock.output("b")
            try! streamLock.output("c")
            try! streamLock.output("d")
            try! streamLock.output("e")
            try! streamLock.output("f")
        }

        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.readto())

        XCTAssertEqual(sequence, ["a", "b", "c", "d", "e", "f"])
    }

    func testStreamLockReadtoSleep() {
        let streamLock = StreamLock<String>()
        var sequence = [String]()

        DispatchQueue.global().async {
            try! streamLock.output("a")
            try! streamLock.output("b")
            try! streamLock.output("c")
            try! streamLock.output("d")
            try! streamLock.output("e")
            try! streamLock.output("f")
        }

        Thread.sleep(forTimeInterval: 0.05)
        sequence.append(try! streamLock.readto())
        Thread.sleep(forTimeInterval: 0.1)
        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.readto())
        Thread.sleep(forTimeInterval: 0.05)
        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.readto())
        Thread.sleep(forTimeInterval: 0.1)
        sequence.append(try! streamLock.readto())

        XCTAssertEqual(sequence, ["a", "b", "c", "d", "e", "f"])
    }

    func testStreamLockPeekto() {
        let streamLock = StreamLock<String>()
        var sequence = [String]()

        DispatchQueue.global().async {
            try! streamLock.output("a")
            try! streamLock.output("b")
            try! streamLock.output("c")
            try! streamLock.output("d")
            try! streamLock.output("e")
            try! streamLock.output("f")
        }

        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.peekto())
        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.peekto())
        sequence.append(try! streamLock.peekto())
        sequence.append(try! streamLock.peekto())
        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.readto())
        sequence.append(try! streamLock.readto())

        XCTAssertEqual(sequence, ["a", "b", "b", "c", "d", "d", "d", "d", "e", "f"])
    }

    func testStreamLockSever() {
        let streamLock = StreamLock<String>()
        var sequence = [String?]()

        DispatchQueue.global().async {
            try! streamLock.output("a")
            try! streamLock.output("b")
            try? streamLock.output("c")
        }

        sequence.append(try? streamLock.readto())
        sequence.append(try? streamLock.readto())
        streamLock.sever()
        sequence.append(try? streamLock.peekto())
        sequence.append(try? streamLock.readto())


        XCTAssertEqual(sequence, ["a", "b", nil, nil])
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
