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

        XCTAssertThrows(try Pipe("cons eof"), PipeError.requiredOperandMissing)
        XCTAssertThrows(try Pipe("cons broken"), PipeError.excessiveOptions(string: "broken"))
    }

    func testDiskr() throws {
        XCTAssertThrows(try Pipe("diskr").run(), PipeError.requiredOperandMissing)
        XCTAssertThrows(try Pipe("diskr ").run(), PipeError.requiredOperandMissing)
        XCTAssertThrows(try Pipe("diskr a-non-existing-file").run(), PipeError.fileDoesNotExist(filename: "a-non-existing-file"))
        XCTAssertThrows(try Pipe("literal abc | diskr foobar").run(), PipeError.mustBeFirstStage)

        try withTempFileContaining("ignored") { (filename) in
            try Pipe("diskr \(filename)").run()
            try Pipe("< \(filename)").run()
        }
        try withTempFileContaining("a\n\n\nb\nc\n  \nd\ne\n") { (filename) in
            try Pipe("diskr \(filename) | zzzcheck /a///b/c/  /d/e/").run()
        }
        try withTempFileContaining("a\n\n\nb\nc\n  \nd\ne") { (filename) in
            try Pipe("diskr \(filename) | zzzcheck /a///b/c/  /d/e/").run()
        }
        try withTempFileContaining("") { (filename) in
            try Pipe("diskr \(filename) | zzzcheck").run()
        }
        try withTempFileContaining("\n") { (filename) in
            try Pipe("diskr \(filename) | zzzcheck //").run()
        }
        try withTempFileContaining(" \n") { (filename) in
            try Pipe("diskr \(filename) | cons | zzzcheck / /").run()
        }
    }

    func testDiskw() throws {
        class IgnoredError: Error {}
        XCTAssertThrows(try Pipe("diskw").run(), PipeError.requiredOperandMissing)
        XCTAssertThrows(try Pipe("diskw ").run(), PipeError.requiredOperandMissing)
        XCTAssertThrows(try Pipe("diskw foobar").run(), PipeError.cannotBeFirstStage)
        XCTAssertThrows(try Pipe("literal abc | diskw /cantWriteToRoot").run(), PipeError.unableToWriteToFile(path: "/cantWriteToRoot", error: IgnoredError()))

        try withFileContentsFor("literal | > /tmp/foobar", filename: "/tmp/foobar") { (contents) in
            XCTAssertEqual(contents, "\n")
        }
        try withFileContentsFor("literal  | > /tmp/foobar", filename: "/tmp/foobar") { (contents) in
            XCTAssertEqual(contents, " \n")
        }
//        try withFileContentsFor("literal a| take 0 | > /tmp/foobar", filename: "/tmp/foobar") { (contents) in
//            XCTAssertEqual(contents, "")
//        }
        try withFileContentsFor("zzzgen /a/b/c/ | > /tmp/foobar", filename: "/tmp/foobar", remove: false) { contents1 in
            XCTAssertEqual(contents1, "a\nb\nc\n")
            try withFileContentsFor("zzzgen /d/e/f/ | > /tmp/foobar", filename: "/tmp/foobar") { (contents2) in
                XCTAssertEqual(contents2, "d\ne\nf\n")
            }
        }
//        try withFileContentsFor("zzzgen /a/b/c/d/e/ | diskw /tmp/foobar | take 3 | zzzcheck /a/b/c/", filename: "/tmp/foobar") { contents in
//            XCTAssertEqual(contents, "a\nb\nc\nd\ne\n")
//        }
        try withFileContentsFor("literal abc| > /tmp/file with spaces in name", filename: "/tmp/file with spaces in name") { (contents) in
            XCTAssertEqual(contents, "abc\n")
        }
        try withFileContentsFor("literal abc| >     /tmp/trailingspaces    ", filename: "/tmp/trailingspaces") { (contents) in
            XCTAssertEqual(contents, "abc\n")
        }
        try withFileContentsFor("literal abc| >     /tmp/  trailingspaces    ", filename: "/tmp/  trailingspaces") { (contents) in
            XCTAssertEqual(contents, "abc\n")
        }
    }

    func testDiskwa() throws {
        XCTAssertThrows(try Pipe("diskwa").run(), PipeError.requiredOperandMissing)
        XCTAssertThrows(try Pipe("diskwa ").run(), PipeError.requiredOperandMissing)
        XCTAssertThrows(try Pipe("diskwa foobar").run(), PipeError.cannotBeFirstStage)

        try withFileContentsFor("literal | >> /tmp/foobar", filename: "/tmp/foobar") { (contents) in
            XCTAssertEqual(contents, "\n")
        }
        try withFileContentsFor("literal  | >> /tmp/foobar", filename: "/tmp/foobar") { (contents) in
            XCTAssertEqual(contents, " \n")
        }
//        try withFileContentsFor("literal a| take 0 | >> /tmp/foobar", filename: "/tmp/foobar") { (contents) in
//            XCTAssertEqual(contents, "")
//        }
        try withFileContentsFor("zzzgen /a/b/c/ | > /tmp/foobar", filename: "/tmp/foobar", remove: false) { contents1 in
            XCTAssertEqual(contents1, "a\nb\nc\n")
            try withFileContentsFor("zzzgen /d/e/f/ | >> /tmp/foobar", filename: "/tmp/foobar") { (contents2) in
                XCTAssertEqual(contents2, "a\nb\nc\nd\ne\nf\n")
            }
        }
//        try withFileContentsFor("zzzgen /a/b/c/d/e/ | >> /tmp/foobar | take 3 | zzzcheck /a/b/c/", filename: "/tmp/foobar") { contents in
//            XCTAssertEqual(contents, "a\nb\nc\nd\ne\n")
//        }
    }

    func testHelp() throws {
        let syntax = Help.helpSyntax!
        let summary = Help.helpSummary!
        try Pipe("help help | zzzcheck /\(syntax)/\(summary)/").run()

        XCTAssertThrows(try Pipe("help help broken"), PipeError.excessiveOptions(string: "broken"))
    }

    func testHole() throws {
        try Pipe("literal a|literal b| hole | literal c| zzzcheck /c/").run()
    }

    func testLiteral() throws {
        try Pipe("literal a| zzzcheck /a/").run()
        try Pipe("literal  a| zzzcheck / a/").run()
        try Pipe("literal a | zzzcheck /a /").run()
        try Pipe("literal aa | zzzcheck /aa /").run()
        try Pipe("literal | zzzcheck //").run()
        try Pipe("literal| zzzcheck //").run()
        try Pipe("literal b| literal a| zzzcheck /a/b/").run()
        try Pipe("literal b | literal a | zzzcheck /a /b /").run()
    }

    func testZZZ() throws {
        try Pipe("zzzgen // | zzzcheck //").run()
        try Pipe("zzzgen /a/b/c/ | zzzcheck /a/b/c/").run()
    }
}
