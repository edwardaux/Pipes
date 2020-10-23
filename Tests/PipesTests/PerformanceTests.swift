import XCTest
@testable import Pipes

final class PerformanceTests: XCTestCase {
    func testReadto() {
        let stage1 = Stage()
        let stage2 = Stage()
        let stream  = Pipes.Stream(producer: stage1, producerStreamNo: 0, consumer: stage2, consumerStreamNo: 0)
        stage1.outputStreams = [stream]
        stage2.inputStreams = [stream]

        stage1.committed = true
        stage2.committed = true

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
