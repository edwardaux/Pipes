import XCTest
@testable import Pipes

final class LockingTests: XCTestCase {
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
        ("testStreamLockReadto", testStreamLockReadto),
        ("testStreamLockReadtoSleep", testStreamLockReadtoSleep),
        ("testStreamLockPeekto", testStreamLockPeekto),
        ("testStreamLockSever", testStreamLockSever)
    ]
}
