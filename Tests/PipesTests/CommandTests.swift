import XCTest
@testable import Pipes

final class CommandTests: XCTestCase {
    func testStreamState() throws {
        let stage1 = Stage()
        let stage2 = Stage()
        let stream  = Pipes.Stream(producer: stage1, producerStreamNo: 0, consumer: stage2, consumerStreamNo: 0)
        stage1.outputStreams = [stream]
        stage2.inputStreams = [stream]

        stage1.committed = true
        stage2.committed = true

        DispatchQueue.global().async {
            try! stage1.output("a")
        }

        Thread.sleep(forTimeInterval: 0.05)
        XCTAssertEqual(stage1.streamState(.output, streamNo: 0), StreamState.connectedWaiting)
        XCTAssertEqual(stage1.streamState(.output, streamNo: 1), StreamState.notDefined)
        XCTAssertEqual(stage2.streamState(.input, streamNo: 0), StreamState.connectedWaiting)
        XCTAssertEqual(stage2.streamState(.input, streamNo: 1), StreamState.notDefined)

        _ = try! stage2.readto()

        XCTAssertEqual(stage1.streamState(.output, streamNo: 0), StreamState.connectedNotWaiting)
        XCTAssertEqual(stage1.streamState(.output, streamNo: 1), StreamState.notDefined)
        XCTAssertEqual(stage2.streamState(.input, streamNo: 0), StreamState.connectedNotWaiting)
        XCTAssertEqual(stage2.streamState(.input, streamNo: 1), StreamState.notDefined)
    }

    func testIllegalCommandInCommit() {
        class TestStage: Stage {
            override public func commit() throws {
                try output("")
            }
        }

        XCTAssertThrows(try Pipe().add(TestStage()).run(), PipeError.commandNotPermitted(command: "OUTPUT"))
    }

    func testValidationInCommit() {
        class TestStage: Stage {
            override public func commit() throws {
                throw PipeError.invalidStreamIdentifier(identifier: "abc")
            }
        }

        XCTAssertThrows(try Pipe().add(TestStage()).run(), PipeError.invalidStreamIdentifier(identifier: "abc"))
    }
}
