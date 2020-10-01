import Foundation
import XCTest
import Pipes

class RunnableStage: Stage {
    private let block: () throws -> Void

    init(_ block: @escaping () throws -> Void) {
        self.block = block
    }

    override func run() throws {
        try block()
    }
}

class GeneratorStage: Stage {
    private let records: [String]

    init(_ records: [String]) {
        self.records = records
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
    }

    override func run() throws {
        while true {
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

