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
        XCTAssertThrows(try Pipe("cons aaa"), PipeError.operandNotValid(keyword: "aaa"))
        XCTAssertThrows(try Pipe("cons noeof broken"), PipeError.excessiveOptions(string: "broken"))
    }

    func testCount() throws {
        XCTAssertThrows(try Pipe("count"), PipeError.requiredOperandMissing)
        XCTAssertThrows(try Pipe("count xxx"), PipeError.operandNotValid(keyword: "xxx"))
        XCTAssertThrows(try Pipe("count bytes aa words"), PipeError.operandNotValid(keyword: "aa"))

        try Pipe("count words min max | zzzcheck /0 -1 -1/").run()
        try Pipe("literal a|count words").run()
        try Pipe("literal a|count words lines").run()
        try Pipe("literal a|count words lines lines").run()

        try Pipe("literal aa bb     cc dd       ee      | count bytes chars words | zzzcheck /30 30 5/").run()
        try Pipe("literal abc d \u{1F99C} \u{1F46A} 🌍| count bytes chars words lines min max | zzzcheck /20 11 5 1 11 11/").run()
        try Pipe("literal 🤦🏼‍♂️| count bytes chars words | zzzcheck /17 1 1/").run()

        try Pipe("literal abc|literal def|literal hello there how are you|literal | count chars words lines min max | zzzcheck /29 7 4 0 23/").run()
        try Pipe("literal abc|literal def|literal hello there how are you|literal | count max min lines words chars chars chars | zzzcheck /23 0 4 7 29 29 29/").run()
        try Pipe("(end ?) literal abc|literal def|literal hello there how are you|literal | c: count chars words lines min max | zzzcheck //hello there how are you/def/abc/ ? c: | zzzcheck /29 7 4 0 23/").run()
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
        // TODO uncomment once we get TAKE
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

    func testFanin() throws {
        try Pipe("fanin").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin | zzzcheck /a/b/c/").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin | zzzcheck /a/b/c/d/e/f/ ? zzzgen /d/e/f/ | f:").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin | zzzcheck /a/b/c/d/e/f/g/h/i/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin 2 1 0 | zzzcheck /g/h/i/d/e/f/a/b/c/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin 2 | zzzcheck /g/h/i/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin 2 1 2 0 | zzzcheck /g/h/i/d/e/f/a/b/c/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run()

        XCTAssertThrows(try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin 5 | zzzcheck /g/h/i/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run(), PipeError.streamNotDefined(streamNo: 5))
        XCTAssertThrows(try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin -1 | zzzcheck /g/h/i/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run(), PipeError.invalidStreamIdentifier(identifier: "-1"))
        XCTAssertThrows(try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin abc | zzzcheck /g/h/i/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run(), PipeError.invalidStreamIdentifier(identifier: "abc"))
        XCTAssertThrows(try Pipe("(end ?) literal a | a: fanin | console ? a: | console").run(), PipeError.unusedOutputStreamConnected(streamNo: 1))
    }

    func testFaninany() throws {
        try Pipe("fanin").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: faninany | zzzcheck /a/b/c/").run()
        // TODO these are non-deterministic. should probably test with a sort stage
        // try Pipe("(end ?) zzzgen /a/b/c/ | f: faninany | zzzcheck /a/b/c/d/e/f/ ? zzzgen /d/e/f/ | f:").run()
        // try Pipe("(end ?) zzzgen /a/b/c/ | f: faninany | zzzcheck /a/b/c/d/e/f/g/h/i/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run()

        XCTAssertThrows(try Pipe("(end ?) literal a | a: faninany | console ? a: | console").run(), PipeError.unusedOutputStreamConnected(streamNo: 1))

        // TODO have an example using locate or other stage that splits the input
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
