import Foundation
import XCTest
import Pipes

class GeneratorStage: Stage {
    private let records: [String]

    init(_ records: [String]) {
        self.records = records
        super.init("generator")
    }

    override func run() throws {
        try records.forEach {
            try output($0)
        }
    }
}

class PassthroughStage: Stage {
    private let count: Int

    init(count: Int) {
        self.count = count
        super.init("passthrough")
    }

    override func run() throws {
        for _ in 0..<count {
            let record = try peekto()
            try output(record)
            _ = try readto()
        }
    }
}

class CheckerStage: Stage {
    private let expected: [String]

    init(_ expected: [String]) {
        self.expected = expected
        super.init("checker")
    }

    override func run() throws {
        var actual: [String] = []
        do {
            while true {
                let record = try readto()
                actual.append(record)
            }
        } catch {
            XCTAssertEqual(actual, expected)
        }
    }
}

