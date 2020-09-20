import XCTest
@testable import Pipes

final class DispatcherTests: XCTestCase {
    func testSimpleExample() {
//        let input = [ "a", "b", "c" ]
//
//        let stage1 = GeneratorStage(input)
//        let stage2 = PassthroughStage(count: input.count)
//        let stage3 = CheckerStage(input)
//
//        let stream1 = Pipes.Stream(producer: nil,                         consumer: stage1, consumerStreamNo: 0)
//        let stream2 = Pipes.Stream(producer: stage1, producerStreamNo: 0, consumer: stage2, consumerStreamNo: 0)
//        let stream3 = Pipes.Stream(producer: stage2, producerStreamNo: 0, consumer: stage3, consumerStreamNo: 0)
//        let stream4 = Pipes.Stream(producer: stage3, producerStreamNo: 0, consumer: nil)
//
//        let pipeline = Pipeline(stages: [ stage1, stage2, stage3 ], streams: [ stream1, stream2, stream3, stream4 ])
//        pipeline.run()
    }

    static var allTests = [
        ("testSimpleExample", testSimpleExample),
    ]
}
