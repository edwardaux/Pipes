import XCTest
@testable import Pipes

final class LockingTests: XCTestCase {
    func testStreamLockReadto() {
        let stream = Pipes.Stream(producer: nil, consumer: GeneratorStage([]), consumerStreamNo: 0)
        var sequence = [String]()

        DispatchQueue.global().async {
            try! stream.output("a")
            try! stream.output("b")
            try! stream.output("c")
            try! stream.output("d")
            try! stream.output("e")
            try! stream.output("f")
        }

        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())

        XCTAssertEqual(sequence, ["a", "b", "c", "d", "e", "f"])
    }

    func testStreamLockReadtoSleep() {
        let stream = Pipes.Stream(producer: nil, consumer: GeneratorStage([]), consumerStreamNo: 0)
        var sequence = [String]()

        DispatchQueue.global().async {
            try! stream.output("a")
            try! stream.output("b")
            try! stream.output("c")
            try! stream.output("d")
            try! stream.output("e")
            try! stream.output("f")
        }

        Thread.sleep(forTimeInterval: 0.05)
        sequence.append(try! stream.readto())
        Thread.sleep(forTimeInterval: 0.1)
        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())
        Thread.sleep(forTimeInterval: 0.05)
        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())
        Thread.sleep(forTimeInterval: 0.1)
        sequence.append(try! stream.readto())

        XCTAssertEqual(sequence, ["a", "b", "c", "d", "e", "f"])
    }

    func testStreamLockPeekto() {
        let stream = Pipes.Stream(producer: nil, consumer: GeneratorStage([]), consumerStreamNo: 0)
        var sequence = [String]()

        DispatchQueue.global().async {
            try! stream.output("a")
            try! stream.output("b")
            try! stream.output("c")
            try! stream.output("d")
            try! stream.output("e")
            try! stream.output("f")
        }

        sequence.append(try! stream.readto())
        sequence.append(try! stream.peekto())
        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())
        sequence.append(try! stream.peekto())
        sequence.append(try! stream.peekto())
        sequence.append(try! stream.peekto())
        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())

        XCTAssertEqual(sequence, ["a", "b", "b", "c", "d", "d", "d", "d", "e", "f"])
    }

    func testPeektoDoesntUnblockProducer() {
        let stream = Pipes.Stream(producer: nil, consumer: GeneratorStage([]), consumerStreamNo: 0)
        var sequence = [String]()

        DispatchQueue.global().async {
            try! stream.output("b")
            sequence.append("d")
        }

        sequence.append("a")
        sequence.append(try! stream.peekto())
        sequence.append("c")

        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertEqual(sequence, ["a", "b", "c"])
    }

    func testStreamLockSever() {
        let stream = Pipes.Stream(producer: nil, consumer: GeneratorStage([]), consumerStreamNo: 0)
        var sequence = [String?]()

        DispatchQueue.global().async {
            try! stream.output("a")
            try! stream.output("b")
            try? stream.output("c")
        }

        sequence.append(try! stream.readto())
        sequence.append(try! stream.readto())
        try! stream.sever()
        sequence.append(try? stream.peekto())
        sequence.append(try? stream.readto())


        XCTAssertEqual(sequence, ["a", "b", nil, nil])
    }


    static var allTests = [
        ("testStreamLockReadto", testStreamLockReadto),
        ("testStreamLockReadtoSleep", testStreamLockReadtoSleep),
        ("testStreamLockPeekto", testStreamLockPeekto),
        ("testStreamLockSever", testStreamLockSever)
    ]
}
