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

final class ZZZTestGeneratorStage: Stage, RegisteredStage {
    private let records: [String]

    init(_ records: [String]) {
        self.records = records
    }

    override func run() throws {
        try records.forEach {
            try output($0)
        }
    }

    static var allowedStageNames: [String] { ["zzzgen" ] }
    static func createStage(args: Args) -> Stage { return ZZZTestGeneratorStage(try! args.scanWord().split(separator: "/").map { String($0) }) }
    static var helpSummary: String? { "Takes a slash-separated list of 'n' values and creates 'n' records"}
    static var helpSyntax: String? { "──ZZZGEN──/a/b/c/──" }
}

class ZZZTestCheckerStage: Stage, RegisteredStage {
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
            if (actual != expected) {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "\(actual) not equal to \(expected)"])
            }
        }
    }

    static var allowedStageNames: [String] { ["zzzcheck" ] }
    static func createStage(args: Args) -> Stage { return ZZZTestCheckerStage(try! args.scanRemaining().split(separator: "/").map { String($0) }) }
    static var helpSummary: String? { "Takes a slash-separated list of 'n' values and checks that the pipe produces 'n' records" }
    static var helpSyntax: String? { "──ZZZCHECK──/a/b/c/──" }
}

