import XCTest
@testable import Pipes

final class LockingTests: XCTestCase {
    private func makeTestStages() -> (Stage, Stage) {
        class TestInputStage: Stage {
            func setTestStream(stream: Pipes.Stream) {
                self.setup(inputStreams: [], outputStreams: [stream])
            }
        }
        class TestOutputStage: Stage {
            func setTestStream(stream: Pipes.Stream) {
                self.setup(inputStreams: [stream], outputStreams: [])
            }
        }
        let stage1 = TestInputStage("Stage 1")
        let stage2 = TestOutputStage("Stage 2", debugIndent: "         ")
        let stream  = Pipes.Stream(producer: stage1, producerStreamNo: 0, consumer: stage2, consumerStreamNo: 0)
        stage1.setTestStream(stream: stream)
        stage2.setTestStream(stream: stream)
        return (stage1, stage2)
    }

    func testStreamLockReadto() {
        let (stage1, stage2) = makeTestStages()
        var sequence = [String]()

        DispatchQueue.global().async {
            try! stage1.output("a")
            try! stage1.output("b")
            try! stage1.output("c")
            try! stage1.output("d")
            try! stage1.output("e")
            try! stage1.output("f")
        }

        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())

        XCTAssertEqual(sequence, ["a", "b", "c", "d", "e", "f"])
    }

    func testStreamLockReadtoSleep() {
        let (stage1, stage2) = makeTestStages()
        var sequence = [String]()

        DispatchQueue.global().async {
            try! stage1.output("a")
            try! stage1.output("b")
            try! stage1.output("c")
            try! stage1.output("d")
            try! stage1.output("e")
            try! stage1.output("f")
        }

        Thread.sleep(forTimeInterval: 0.05)
        sequence.append(try! stage2.readto())
        Thread.sleep(forTimeInterval: 0.1)
        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())
        Thread.sleep(forTimeInterval: 0.05)
        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())
        Thread.sleep(forTimeInterval: 0.1)
        sequence.append(try! stage2.readto())

        XCTAssertEqual(sequence, ["a", "b", "c", "d", "e", "f"])
    }

    func testStreamLockPeekto() {
        let (stage1, stage2) = makeTestStages()
        var sequence = [String]()

        DispatchQueue.global().async {
            try! stage1.output("a")
            try! stage1.output("b")
            try! stage1.output("c")
            try! stage1.output("d")
            try! stage1.output("e")
            try! stage1.output("f")
        }

        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.peekto())
        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.peekto())
        sequence.append(try! stage2.peekto())
        sequence.append(try! stage2.peekto())
        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())

        XCTAssertEqual(sequence, ["a", "b", "b", "c", "d", "d", "d", "d", "e", "f"])
    }

    func testPeektoDoesntUnblockProducer() {
        let (stage1, stage2) = makeTestStages()
        var sequence = [String]()

        DispatchQueue.global().async {
            try! stage1.output("b")
            sequence.append("d")
        }

        sequence.append("a")
        sequence.append(try! stage2.peekto())
        sequence.append("c")

        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertEqual(sequence, ["a", "b", "c"])
    }

    func testStreamLockSever() {
        let (stage1, stage2) = makeTestStages()
        var sequence = [String?]()

        DispatchQueue.global().async {
            try! stage1.output("a")
            try! stage1.output("b")
            try? stage1.output("c")
        }

        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())
        try! stage1.sever()
        sequence.append(try? stage2.peekto())
        sequence.append(try? stage2.readto())

        XCTAssertEqual(sequence, ["a", "b", nil, nil])
    }

    func testStageLockPeektoAny() {
        // This is essentially the same tests as testStreamLockPeekto()
        // but using the ANY stream selection instead of explicitly using
        // stream 0.
        let (stage1, stage2) = makeTestStages()
        var sequence = [String]()

        DispatchQueue.global().async {
            try! stage1.output("a")
            try! stage1.output("b")
            try! stage1.output("c")
            try! stage1.output("d")
            try! stage1.output("e")
            try! stage1.output("f")
        }

        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.peekto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.peekto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.peekto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.peekto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))

        XCTAssertEqual(sequence, ["a", "b", "b", "c", "d", "d", "d", "d", "e", "f"])
    }
}
