import XCTest
@testable import Pipes

final class StageTests: XCTestCase {
    override class func setUp() {
        Pipe.register(ZZZTestGeneratorStage.self)
        Pipe.register(ZZZTestCheckerStage.self)
    }

    func testRepeatability() throws {
        // Let's try running a few times to make sure there aren't any race conditions
        for _ in 0..<1000 {
            try Pipe("zzzgen /a/b/c/d/e/f/g/ | zzzcheck /a/b/c/d/e/f/g/").run()
        }
    }

    func testConsole() throws {
        // Tricky to test reading from console, but we can verify that at least the records pass through OK
        try Pipe("zzzgen /a/b/c/d/ | cons | console | zzzcheck /a/b/c/d/").run()

        XCTAssertThrows(try Pipe("cons broken"), PipeError.excessiveOptions(string: "broken"))
    }

    func testHelp() throws {
        let syntax = Help.helpSyntax!
        let summary = Help.helpSummary!
        try Pipe("help help | zzzcheck /\(syntax)/\(summary)/").run()

        XCTAssertThrows(try Pipe("help help broken"), PipeError.excessiveOptions(string: "broken"))
    }

    func testLiteral() throws {
        try Pipe("literal a| zzzcheck /a/").run()
        try Pipe("literal a | zzzcheck /a /").run()
        try Pipe("literal aa | zzzcheck /aa /").run()
        try Pipe("literal | zzzcheck //").run()
        try Pipe("literal| zzzcheck //").run()
        try Pipe("literal b| literal a| zzzcheck /a/b/").run()
    }

    func testZZZ() throws {
        try Pipe("zzzgen // | zzzcheck //").run()
        try Pipe("zzzgen /a/b/c/ | zzzcheck /a/b/c/").run()
    }
}
