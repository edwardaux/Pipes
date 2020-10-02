import XCTest
@testable import Pipes

final class LockingTests: XCTestCase {
    private func makeTestStages() -> (Stage, Stage) {
        let stage1 = Stage()
        let stage2 = Stage()
        let stream  = Pipes.Stream(producer: stage1, producerStreamNo: 0, consumer: stage2, consumerStreamNo: 0)
        stage1.outputStreams = [stream]
        stage2.inputStreams = [stream]
        return (stage1, stage2)
    }

    func testReadto() {
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

    func testReadtoSleep() {
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

    func testPeekto() {
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

    func testSever() {
        let (stage1, stage2) = makeTestStages()
        var sequence = [String?]()

        DispatchQueue.global().async {
            try! stage1.output("a")
            try! stage1.output("b")
            try? stage1.output("c")
        }

        sequence.append(try! stage2.readto())
        sequence.append(try! stage2.readto())
        try! stage2.sever(.input)
        sequence.append(try? stage2.peekto())
        sequence.append(try? stage2.readto())

        XCTAssertEqual(sequence, ["a", "b", nil, nil])
    }

    func testPeektoAny() {
        // This is essentially the same tests as testPeekto()
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

    func testReadtoAnyMultipleStreams() {
        let stage1a = Stage()
        let stage1b = Stage()
        let stage2 = Stage()
        let stream1 = Pipes.Stream(producer: stage1a, producerStreamNo: 0, consumer: stage2, consumerStreamNo: 0)
        let stream2 = Pipes.Stream(producer: stage1b, producerStreamNo: 0, consumer: stage2, consumerStreamNo: 1)
        stage1a.outputStreams = [stream1]
        stage1b.outputStreams = [stream2]
        stage2.inputStreams = [stream1, stream2]

        var sequence = [String]()

        DispatchQueue.global().async {
            try! stage1b.output("ba")
            try! stage1b.output("bb")
            try! stage1b.output("bc")
            try! stage1a.output("aa")
            try! stage1a.output("ab")
            try! stage1a.output("ac")
        }

        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))

        XCTAssertEqual(sequence.sorted(), ["aa", "ab", "ac", "ba", "bb", "bc"])
    }

    func testPeektoAnyMultipleStreams() {
        let stage1a = Stage()
        let stage1b = Stage()
        let stage2 = Stage()
        let stream1 = Pipes.Stream(producer: stage1a, producerStreamNo: 0, consumer: stage2, consumerStreamNo: 0)
        let stream2 = Pipes.Stream(producer: stage1b, producerStreamNo: 0, consumer: stage2, consumerStreamNo: 1)
        stage1a.outputStreams = [stream1]
        stage1b.outputStreams = [stream2]
        stage2.inputStreams = [stream1, stream2]

        var sequence = [String]()

        DispatchQueue.global().async {
            try! stage1b.output("ba")
            try! stage1b.output("bb")
            try! stage1b.output("bc")
        }
        DispatchQueue.global().async {
            // pause to let stream 1 write first
            Thread.sleep(forTimeInterval: 0.05)
            try! stage1a.output("aa")
            try! stage1a.output("ab")
            Thread.sleep(forTimeInterval: 0.25)
            try! stage1a.output("ac")
        }

        // we should be reading from stream 1
        sequence.append(try! stage2.peekto(streamNo: Pipes.Stream.ANY))
        // wait for stream 0 to get a record
        Thread.sleep(forTimeInterval: 0.10)
        // make sure we still peek the right record
        sequence.append(try! stage2.peekto(streamNo: Pipes.Stream.ANY))
        // need to make sure we get the last peeked record
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        // at this point, both input streams should have record available,
        // but we should choose stream 0 and read the first two recods
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        // just make sure that both stream 0 and 1 have both written a record
        Thread.sleep(forTimeInterval: 0.05)
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        // now stream 0 should have nothing available because it is sleeping
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        // give both threads a chance to write a record
        Thread.sleep(forTimeInterval: 0.30)
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))
        sequence.append(try! stage2.readto(streamNo: Pipes.Stream.ANY))

        XCTAssertEqual(sequence, ["ba", "ba", "ba", "aa", "ab", "bb", "ac", "bc"])
    }

}
