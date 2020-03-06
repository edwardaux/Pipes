import Foundation
import XCTest
import Pipes

class GeneratorStage: Stage {
    private let records: [String]

    init(_ records: [String]) {
        self.records = records
        super.init()
    }

    override func run() {
        records.forEach {
            output($0)
        }
    }
}

class CheckerStage: Stage {
    private let expected: [String]

    init(_ expected: [String]) {
        self.expected = expected
        super.init()
    }

    override func run() {
        for e in expected {
            let actual = readto()
            XCTAssertEqual(actual, e)
        }
    }
}

class PassthroughStage: Stage {
    private let count: Int

    init(count: Int) {
        self.count = count
        super.init()
    }

    override func run() {
        for _ in 0..<count {
            let record1 = peekto()
            output(record1)
            _ = readto()
        }
    }
}
