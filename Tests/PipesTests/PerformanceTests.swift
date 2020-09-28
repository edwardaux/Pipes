import XCTest
@testable import Pipes

final class PerformanceTests: XCTestCase {
    func testReadto() {
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
        let stage1 = TestInputStage()
        let stage2 = TestOutputStage()
        let stream  = Pipes.Stream(producer: stage1, producerStreamNo: 0, consumer: stage2, consumerStreamNo: 0)
        stage1.setTestStream(stream: stream)
        stage2.setTestStream(stream: stream)

        let count = 10_000
        measure {
            DispatchQueue.global().async {
                for _ in 1...count {
                    try! stage1.output("a")
                }
            }

            for _ in 1...count {
                _ = try! stage2.readto()
            }
        }
    }
}
