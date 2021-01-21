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

    func testCommand() throws {
        XCTAssertThrows(try Pipe("command | cons").run(), PipeError.requiredOperandMissing)

        try Pipe("command /bin/echo hello there how are you | zzzcheck /hello there how are you/").run()
        try Pipe("zzzgen /aaa/bbb/ccc/ | command /bin/cat | zzzcheck /aaa/bbb/ccc/").run()

        let tmpDirectory = NSTemporaryDirectory() + UUID().uuidString
        defer { try? FileManager.default.removeItem(atPath: tmpDirectory) }

        try FileManager.default.createDirectory(atPath: tmpDirectory, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: tmpDirectory + "/a.txt", contents: "a".data(using: .utf8), attributes: nil)
        FileManager.default.createFile(atPath: tmpDirectory + "/b.txt", contents: "b".data(using: .utf8), attributes: nil)
        FileManager.default.createFile(atPath: tmpDirectory + "/c.txt", contents: "c".data(using: .utf8), attributes: nil)
        FileManager.default.createFile(atPath: tmpDirectory + "/d.txt", contents: "d".data(using: .utf8), attributes: nil)
        try Pipe("command /bin/ls \(tmpDirectory) | zzzcheck /a.txt/b.txt/c.txt/d.txt/").run()

        var file = tmpDirectory + "/z.txt"
        XCTAssertThrows(try Pipe("command \(file) | zzzcheck /aaa/bbb/ccc/").run(), PipeError.programUnableToExecute(program: file, reason: "Not found"))

        file = tmpDirectory + "/a.txt"
        XCTAssertThrows(try Pipe("command \(file) | zzzcheck /aaa/bbb/ccc/").run(), PipeError.programUnableToExecute(program: file, reason: "Not executable"))

        file = tmpDirectory + "/file with spaces.sh"
        FileManager.default.createFile(atPath: file, contents: "#!/bin/bash\necho hello\necho there\n".data(using: .utf8), attributes: nil)
        var attributes = [FileAttributeKey : Any]()
        attributes[.posixPermissions] = 0o777
        try FileManager.default.setAttributes(attributes, ofItemAtPath: file)
        try Pipe("command '\(tmpDirectory)/file with spaces.sh' | zzzcheck /hello/there/").run()
        try Pipe("command \"\(tmpDirectory)/file with spaces.sh\" | zzzcheck /hello/there/").run()

        let script = """
        #!/bin/bash
        echo hello
        echo hi >&2
        echo there
        echo again >&2
        """
        file = tmpDirectory + "/error.sh"
        FileManager.default.createFile(atPath: file, contents: script.data(using: .utf8), attributes: nil)
        attributes[.posixPermissions] = 0o777
        try FileManager.default.setAttributes(attributes, ofItemAtPath: file)
        try Pipe("(end ?)    command \(file) | zzzcheck /hello/there/").run()
        try Pipe("(end ?) c: command \(file) | zzzcheck /hello/there/").run()
        try Pipe("(end ?) c: command \(file) | zzzcheck /hello/there/ ? c: | zzzcheck /hi/again/").run()
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
        try Pipe("(end ?) literal abc|literal def|literal hello there how are you|literal | c: count chars words lines minline maxline | zzzcheck //hello there how are you/def/abc/ ? c: | zzzcheck /29 7 4 0 23/").run()
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
        XCTAssertThrows(try Pipe("diskw").run(), PipeError.requiredOperandMissing)
        XCTAssertThrows(try Pipe("diskw ").run(), PipeError.requiredOperandMissing)
        XCTAssertThrows(try Pipe("diskw foobar").run(), PipeError.cannotBeFirstStage)
        XCTAssertThrows(try Pipe("literal abc | diskw /__nonexistentdir__/cantWriteToFile").run(), PipeError.unableToWriteToFile(path: "/__nonexistentdir__/cantWriteToFile", error: "The file “cantWriteToFile” doesn’t exist."))

        try withFileContentsFor("literal | > /tmp/foobar", filename: "/tmp/foobar") { (contents) in
            XCTAssertEqual(contents, "\n")
        }
        try withFileContentsFor("literal  | > /tmp/foobar", filename: "/tmp/foobar") { (contents) in
            XCTAssertEqual(contents, " \n")
        }
        try withFileContentsFor("literal a| take 0 | > /tmp/foobar", filename: "/tmp/foobar") { (contents) in
            XCTAssertEqual(contents, "")
        }
        try withFileContentsFor("zzzgen /a/b/c/ | > /tmp/foobar", filename: "/tmp/foobar", remove: false) { contents1 in
            XCTAssertEqual(contents1, "a\nb\nc\n")
            try withFileContentsFor("zzzgen /d/e/f/ | > /tmp/foobar", filename: "/tmp/foobar") { (contents2) in
                XCTAssertEqual(contents2, "d\ne\nf\n")
            }
        }
        try withFileContentsFor("zzzgen /a/b/c/d/e/ | diskw /tmp/foobar | take 3 | zzzcheck /a/b/c/", filename: "/tmp/foobar") { contents in
            XCTAssertEqual(contents, "a\nb\nc\nd\ne\n")
        }
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
        try withFileContentsFor("literal a| take 0 | >> /tmp/foobar", filename: "/tmp/foobar") { (contents) in
            XCTAssertEqual(contents, "")
        }
        try withFileContentsFor("zzzgen /a/b/c/ | > /tmp/foobar", filename: "/tmp/foobar", remove: false) { contents1 in
            XCTAssertEqual(contents1, "a\nb\nc\n")
            try withFileContentsFor("zzzgen /d/e/f/ | >> /tmp/foobar", filename: "/tmp/foobar") { (contents2) in
                XCTAssertEqual(contents2, "a\nb\nc\nd\ne\nf\n")
            }
        }
        try withFileContentsFor("zzzgen /a/b/c/d/e/ | >> /tmp/foobar | take 3 | zzzcheck /a/b/c/", filename: "/tmp/foobar") { contents in
            XCTAssertEqual(contents, "a\nb\nc\nd\ne\n")
        }
    }

    func testHelp() throws {
        // Need to make sure the built-in stages are pre-registered before we query the help
        // as they are listed in the help text.
        Pipe.registerBuiltInStages()

        // Note that we have to use a different stage sep because the general help contains
        // some | chars which when embedded in the string itself causes parser problems
        try Pipe("(sep ^) help ^ zzzcheck /\(Help.generalHelp)/").run()
        try Pipe("help help | zzzcheck /\(Help.helpSyntax!)/\(Help.helpSummary!)/").run()
        try Pipe("help inputRange | zzzcheck /\(Help.inputRangeHelp)/").run()
        try Pipe("help nonsense | zzzcheck /\(PipeError.stageNotFound(stageName: "nonsense").localizedDescription)/").run()

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

        XCTAssertThrows(try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin 5 | zzzcheck /g/h/i/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run(), PipeError.streamNotDefined(direction: .input, streamNo: 5))
        XCTAssertThrows(try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin -1 | zzzcheck /g/h/i/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run(), PipeError.invalidStreamIdentifier(identifier: "-1"))
        XCTAssertThrows(try Pipe("(end ?) zzzgen /a/b/c/ | f: fanin abc | zzzcheck /g/h/i/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run(), PipeError.invalidStreamIdentifier(identifier: "abc"))
        XCTAssertThrows(try Pipe("(end ?) literal a | a: fanin | console ? a: | console").run(), PipeError.unusedStreamConnected(direction: .output, streamNo: 1))
    }

    func testFaninany() throws {
        try Pipe("fanin").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: faninany | zzzcheck /a/b/c/").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: faninany | sort | zzzcheck /a/b/c/d/e/f/ ? zzzgen /d/e/f/ | f:").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: faninany | sort | zzzcheck /a/b/c/d/e/f/g/h/i/ ? zzzgen /d/e/f/ | f: ? zzzgen /g/h/i/ | f:").run()

        XCTAssertThrows(try Pipe("(end ?) literal a | a: faninany | console ? a: | console").run(), PipeError.unusedStreamConnected(direction: .output, streamNo: 1))

        try Pipe("(end ?) zzzgen /aa/ab/xc/ad/xe/af/xg/xh/ai/ | l: locate 1.1 /a/ | f: faninany | zzzcheck /aa/ab/xc/ad/xe/af/xg/xh/ai/ ? l: | f:").run()
        try Pipe("(end ?) zzzgen /aa/ab/xc/ad/xe/af/xg/xh/ai/ | l: locate 1.1 /a/ | f: faninany | zzzcheck /aa/ab/xc/ad/af/ai/ ? l: | locate 2.1 /c/ | f:").run()
    }


    func testFanout() throws {
        try Pipe("zzzgen /a/b/c/ | fanout | zzzcheck /a/b/c/").run()
        try Pipe("(end ?) zzzgen /a/b/c/ | f: fanout | zzzcheck /a/b/c/").run()

        try Pipe("(end ?) literal blah| f: fanout | zzzcheck /blah/ ? f: | zzzcheck /blah/ ? f: | zzzcheck /blah/ ? f: | zzzcheck /blah/").run()
        try Pipe("(end ?) literal d|literal c|literal b|literal a| f: fanout STOP ALLEOF | zzzcheck /a/b/c/d/ ? f: | zzzcheck /a/b/c/d/      ? f: | zzzcheck /a/b/c/d/ ? f: | zzzcheck /a/b/c/d/").run()
        try Pipe("(end ?) literal d|literal c|literal b|literal a| f: fanout STOP ALLEOF | zzzcheck /a/b/c/d/ ? f: | take 2 | zzzcheck /a/b/ ? f: | zzzcheck /a/b/c/d/ ? f: | zzzcheck /a/b/c/d/").run()
        try Pipe("(end ?) literal d|literal c|literal b|literal a| f: fanout STOP ANYEOF | zzzcheck /a/b/c/   ? f: | take 2 | zzzcheck /a/b/ ? f: | zzzcheck /a/b/c/   ? f: | zzzcheck /a/b/c/").run()
        try Pipe("(end ?) literal d|literal c|literal b|literal a| f: fanout STOP 1      | zzzcheck /a/b/c/   ? f: | take 2 | zzzcheck /a/b/ ? f: | zzzcheck /a/b/c/   ? f: | zzzcheck /a/b/c/").run()
        try Pipe("(end ?) literal d|literal c|literal b|literal a| f: fanout STOP 2      | zzzcheck /a/b/c/d/ ? f: | take 2 | zzzcheck /a/b/ ? f: | take 3 | zzzcheck /a/b/c/ ? f: | zzzcheck /a/b/c/d/").run()
        try Pipe("(end ?) literal d|literal c|literal b|literal a| f: fanout STOP 10     | zzzcheck /a/b/c/d/ ? f: | take 2 | zzzcheck /a/b/ ? f: | take 3 | zzzcheck /a/b/c/ ? f: | zzzcheck /a/b/c/d/").run()

        XCTAssertThrows(try Pipe("fanout").run(), PipeError.streamNotConnected(direction: .input, streamNo: 0))
        XCTAssertThrows(try Pipe("(end ?) literal a| fanout blah"), PipeError.operandNotValid(keyword: "blah"))
        XCTAssertThrows(try Pipe("(end ?) literal a| fanout stop blah"), PipeError.invalidNumber(word: "blah"))
        XCTAssertThrows(try Pipe("(end ?) literal a| fanout stop anyeof blah"), PipeError.excessiveOptions(string: "blah"))
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

    func testLocate() throws {
        try Pipe("literal a | locate /a/").run()
        try Pipe("literal a | locate anycase /a/").run()
        try Pipe("literal a | locate 1.* /a/").run()
        try Pipe("literal a | locate 3-10 /a/").run()
        try Pipe("literal a | locate (1-5 3-10) /a/").run()
        try Pipe("literal a | locate anycase (1-5 3-10) /a/").run()
        try Pipe("literal a | locate anycase (1-5 3-10) anyof /a/").run()
        try Pipe("literal a | locate anycase (1-5 3-10) anyof").run()
        try Pipe("literal a | locate anycase (1-5 3-10 10-*) anyof x323232").run()
        try Pipe("literal a | locate b11110000").run()

        try Pipe("zzzgen /a/b/c/ | locate /a/ | zzzcheck /a/").run()
        try Pipe("zzzgen /a/b/c/ | locate /A/ | literal x| zzzcheck /x/").run()
        try Pipe("zzzgen /a/b/c/ | locate anycase /A/ | zzzcheck /a/").run()
        try Pipe("literal 4444|literal 333|literal 22|literal 1| locate 2| zzzcheck /22/333/4444/").run()
        try Pipe("literal 4444|literal 333|literal 22|literal 1| locate w1| zzzcheck /1/22/333/4444/").run()
        try Pipe("literal 444 4|literal 333|literal 22|literal 1| locate w2| zzzcheck /444 4/").run()
        try Pipe("literal a|literal|literal b| locate | zzzcheck /b/a/").run()

        try Pipe("literal hello there|literal I am here| locate /here/ | zzzcheck /I am here/hello there/").run()
        try Pipe("literal hello there|literal I am here| locate anycase /HE/ | zzzcheck /I am here/hello there/").run()
        try Pipe("literal hello there|literal I am here| locate anycase 2-5 /HE/ | literal x|zzzcheck /x/").run()
        try Pipe("literal hello there|literal I am here| locate (1.2 2-5) /he/ | literal x|zzzcheck /x/hello there/").run()
        try Pipe("literal hello there|literal I am here| locate anycase (1.2 2-5 6-7) /HE/ | literal x|zzzcheck /x/I am here/hello there/").run()
        try Pipe("literal hello there|literal I am here| locate anycase (1.2 2-5 7-8) /HE/ | literal x|zzzcheck /x/hello there/").run()

        try Pipe("literal a-b-c|literal d-e-f| locate wordsep - w3 /c/ | zzzcheck /a-b-c/").run()
        try Pipe("literal a?b?|literal e??f| locate fieldsep ? f2-3 /f/ | zzzcheck /e??f/").run()
        try Pipe("literal ?ab?c??a|literal ab?c?a| locate (ws ? w1 w3) /a/ | zzzcheck /ab?c?a/?ab?c??a/").run()
        try Pipe("literal afbc|literal adef|literal ghfi|literal fjkl| locate -2;-1 /f/ | zzzcheck /ghfi/adef/").run()

        let colours = "/red apples/white flag/roses are red/grass is green/barry white/white christmas/blue bayou/helen reddy/"
        try Pipe("zzzgen \(colours) | locate /red/ |zzzcheck /red apples/roses are red/helen reddy/").run()
        try Pipe("(end ?) zzzgen \(colours) | l: locate /red/ | f: faninany | zzzcheck /red apples/white flag/roses are red/barry white/white christmas/helen reddy/ ? l: | locate /white/ | f:").run()

        try Pipe("literal aaa|literal bbb|literal ccc|literal ddd| locate anyof /a/ | zzzcheck /aaa/").run()
        try Pipe("literal aaa|literal bbb|literal ccc|literal ddd| locate anyof /ac/ | zzzcheck /ccc/aaa/").run()
        try Pipe("literal aaa|literal bbb|literal ccc|literal ddd| locate anyof /abc/ | zzzcheck /ccc/bbb/aaa/").run()
        try Pipe("literal aaa|literal bbb|literal ccc|literal ddd| locate anyof /zyxabc/ | zzzcheck /ccc/bbb/aaa/").run()
        try Pipe("literal aaa|literal bbb|literal ccc|literal ddd| locate anyof | zzzcheck /ddd/ccc/bbb/aaa/").run()

        try Pipe("(end ?) zzzgen /aaa/bbb/ccc/ddd/a/aa/c/dd/ee/ | l: locate /a/ | zzzcheck /aaa/a/aa/ ? l: | zzzcheck /bbb/ccc/ddd/c/dd/ee/").run()
        try Pipe("(end ?) zzzgen /aaa/bbb/ccc/ddd/a/aa/c/dd/ee/ | l: locate /a/ | zzzcheck /aaa/a/aa/ ? l: | take 1 | zzzcheck /bbb/").run()

        try Pipe("literal a,b,'c',d| literal c,c,c| literal g,h,i| locate fs , q ' f3 /c/ | zzzcheck /c,c,c/a,b,'c',d/").run()
    }


    func testNLocate() throws {
        try Pipe("zzzgen /a/b/c/ | nlocate /a/ | zzzcheck /b/c/").run()
        try Pipe("zzzgen /a/b/c/ | nlocate /A/ | literal x| zzzcheck /x/a/b/c/").run()
        try Pipe("zzzgen /a/b/c/ | nlocate anycase /A/ | zzzcheck /b/c/").run()
        try Pipe("literal 4444|literal 333|literal 22|literal 1| nlocate 2| zzzcheck /1/").run()
        try Pipe("literal 4444|literal 333|literal 22|literal 1| nlocate w1| literal x| zzzcheck /x/").run()
        try Pipe("literal 444 4|literal 333|literal 22|literal 1| nlocate w2| zzzcheck /1/22/333/").run()
        try Pipe("literal a|literal|literal b| nlocate | zzzcheck //").run()

        try Pipe("literal hello there|literal I am here| nlocate /here/ | literal x| zzzcheck /x/").run()
        try Pipe("literal hello there|literal I am here| nlocate anycase /HE/ | literal x| zzzcheck /x/").run()
        try Pipe("literal hello there|literal I am here| nlocate anycase 2-5 /HE/ | literal x|zzzcheck /x/I am here/hello there/").run()
        try Pipe("literal hello there|literal I am here| nlocate (1.2 2-5) /he/ | literal x|zzzcheck /x/I am here/").run()
        try Pipe("literal hello there|literal I am here| nlocate anycase (1.2 2-5 6-7) /HE/ | literal x|zzzcheck /x/").run()
        try Pipe("literal hello there|literal I am here| nlocate anycase (1.2 2-5 7-8) /HE/ | literal x|zzzcheck /x/I am here/").run()

        try Pipe("literal a-b-c|literal d-e-f| nlocate wordsep - w3 /c/ | zzzcheck /d-e-f/").run()
        try Pipe("literal a?b?|literal e??f| nlocate fieldsep ? f2-3 /f/ | zzzcheck /a?b?/").run()
        try Pipe("literal ?ab?c??a|literal ab?c?a| nlocate (ws ? w1 w3) /a/ | literal x| zzzcheck /x/").run()
        try Pipe("literal afbc|literal adef|literal ghfi|literal fjkl| nlocate -2;-1 /f/ | zzzcheck /fjkl/afbc/").run()

        let colours = "/red apples/white flag/roses are red/grass is green/barry white/white christmas/blue bayou/helen reddy/"
        try Pipe("zzzgen \(colours) | nlocate /red/ |zzzcheck /white flag/grass is green/barry white/white christmas/blue bayou/").run()
        try Pipe("(end ?) zzzgen \(colours) | l: nlocate /red/ | f: faninany | zzzcheck /white flag/grass is green/barry white/white christmas/blue bayou/helen reddy/ ? l: | locate /helen/ | f:").run()
        try Pipe("(end ?) zzzgen \(colours) | l: nlocate /red/ | nlocate /white/ | zzzcheck /grass is green/blue bayou/").run()

        try Pipe("literal aaa|literal bbb|literal ccc|literal ddd| nlocate anyof /a/ | zzzcheck /ddd/ccc/bbb/").run()
        try Pipe("literal aaa|literal bbb|literal ccc|literal ddd| nlocate anyof /ac/ | zzzcheck /ddd/bbb/").run()
        try Pipe("literal aaa|literal bbb|literal ccc|literal ddd| nlocate anyof /abc/ | zzzcheck /ddd/").run()
        try Pipe("literal aaa|literal bbb|literal ccc|literal ddd| nlocate anyof /zyxabc/ | zzzcheck /ddd/").run()
        try Pipe("literal aaa|literal bbb|literal ccc|literal ddd| nlocate anyof | literal x| zzzcheck /x/").run()

        try Pipe("(end ?) zzzgen /aaa/bbb/ccc/ddd/a/aa/c/dd/ee/ | l: nlocate /a/ | zzzcheck /bbb/ccc/ddd/c/dd/ee/ ? l: | zzzcheck /aaa/a/aa/").run()
        try Pipe("(end ?) zzzgen /aaa/bbb/ccc/ddd/a/aa/c/dd/ee/ | l: nlocate /a/ | zzzcheck /bbb/ccc/ddd/c/dd/ee/ ? l: | take 1 | zzzcheck /aaa/").run()

        try Pipe("literal one|literal two|literal three|literal four|literal five| locate 4 | nlocate 5| zzzcheck /five/four/").run()
    }

    func testSort() throws {
        try Pipe("zzzgen /b/c/a/d/ | sort | zzzcheck /a/b/c/d/").run()
        try Pipe("zzzgen /b/c/a/d/ | sort asc | zzzcheck /a/b/c/d/").run()
        try Pipe("zzzgen /b/c/a/d/ | sort desc | zzzcheck /d/c/b/a/").run()

        try Pipe("zzzgen /b/D/c/c/C/a/A/d/ | sort asc | zzzcheck /A/C/D/a/b/c/c/d/").run()
        try Pipe("zzzgen /b/D/c/c/C/a/A/d/ | sort anycase asc | zzzcheck /a/A/b/c/c/C/D/d/").run()

        let s1 = "John Alice    Bo"
        let s2 = "John Alice    Charlie"
        let s3 = "John Alic     Bob"
        let s4 = "John Alice    Dean"
        let s5 = "John Alice    Deap"
        let s6 = "Peter Alice   Dean"
        let s7 = "Peter Allison Deap"
        let s8 = "Peter Allison Dean"
        let s9 = "Andy Alice    Bo"
        let input = "/\(s1)/\(s2)/\(s3)/\(s4)/\(s5)/\(s6)/\(s7)/\(s8)/\(s9)/"

        // Sort by whole record
        try Pipe("zzzgen \(input) | sort             | zzzcheck /\(s9)/\(s3)/\(s1)/\(s2)/\(s4)/\(s5)/\(s6)/\(s8)/\(s7)/").run()

        // Sort ascending by one range (stable sort for matching keys)
        try Pipe("zzzgen \(input) | sort 1.4 asc     | zzzcheck /\(s9)/\(s1)/\(s2)/\(s3)/\(s4)/\(s5)/\(s6)/\(s7)/\(s8)/").run()
        // Sort decending by one range (stable sort for matching keys)
        try Pipe("zzzgen \(input) | sort 1.4 desc    | zzzcheck /\(s6)/\(s7)/\(s8)/\(s1)/\(s2)/\(s3)/\(s4)/\(s5)/\(s9)/").run()

        // Check that pad works
        try Pipe("zzzgen \(input) | sort w2          | zzzcheck /\(s3)/\(s1)/\(s2)/\(s4)/\(s5)/\(s6)/\(s9)/\(s7)/\(s8)/").run()
        try Pipe("zzzgen \(input) | sort w2 pad e    | zzzcheck /\(s1)/\(s2)/\(s3)/\(s4)/\(s5)/\(s6)/\(s9)/\(s7)/\(s8)/").run()
        try Pipe("zzzgen \(input) | sort 15-40       | zzzcheck /\(s1)/\(s9)/\(s3)/\(s2)/\(s4)/\(s6)/\(s8)/\(s5)/\(s7)/").run()
        try Pipe("zzzgen \(input) | sort 15-40 pad e | zzzcheck /\(s3)/\(s1)/\(s9)/\(s2)/\(s4)/\(s6)/\(s8)/\(s5)/\(s7)/").run()
        try Pipe("zzzgen \(input) | sort 15-40 pad b | zzzcheck /\(s1)/\(s3)/\(s9)/\(s2)/\(s4)/\(s6)/\(s8)/\(s5)/\(s7)/").run()

        // Multi-key
        try Pipe("zzzgen \(input) | sort 15-40 asc  w1 asc         | zzzcheck /\(s9)/\(s1)/\(s3)/\(s2)/\(s4)/\(s6)/\(s8)/\(s5)/\(s7)/").run()
        try Pipe("zzzgen \(input) | sort 15-40 asc  w1 desc        | zzzcheck /\(s1)/\(s9)/\(s3)/\(s2)/\(s6)/\(s8)/\(s4)/\(s7)/\(s5)/").run()
        try Pipe("zzzgen \(input) | sort 15-40 desc w1 asc         | zzzcheck /\(s5)/\(s7)/\(s4)/\(s6)/\(s8)/\(s2)/\(s3)/\(s9)/\(s1)/").run()
        try Pipe("zzzgen \(input) | sort 15-40 desc w1 desc        | zzzcheck /\(s7)/\(s5)/\(s6)/\(s8)/\(s4)/\(s2)/\(s3)/\(s1)/\(s9)/").run()
        try Pipe("zzzgen \(input) | sort 15-40 asc  w1 asc w2 asc  | zzzcheck /\(s9)/\(s1)/\(s3)/\(s2)/\(s4)/\(s6)/\(s8)/\(s5)/\(s7)/").run()
        try Pipe("zzzgen \(input) | sort 15-40 asc  w1 asc w2 desc | zzzcheck /\(s9)/\(s1)/\(s3)/\(s2)/\(s4)/\(s8)/\(s6)/\(s5)/\(s7)/").run()
        try Pipe("zzzgen \(input) | sort 15-40 asc pad e w1 asc w2 desc | zzzcheck /\(s3)/\(s9)/\(s1)/\(s2)/\(s4)/\(s8)/\(s6)/\(s5)/\(s7)/").run()
        try Pipe("zzzgen \(input) | sort 15-40 asc pad b w1 asc w2 desc | zzzcheck /\(s9)/\(s1)/\(s3)/\(s2)/\(s4)/\(s8)/\(s6)/\(s5)/\(s7)/").run()

        let u1 = "aa bb cc dd ee"
        let u2 = "aa bb cc dd ee"
        let u3 = "zz bb cc dd ee"
        let u4 = "zz bb cc dd ee"
        let u5 = "zz bb zz dd ee"
        let u6 = "aa bb cc dd ee"
        let u7 = "aa bb zz dd ee"
        let u8 = "aa bb cc dd ee"
        let u9 = "aa bb zz dd ee"
        let input2 = "/\(u1)/\(u2)/\(u3)/\(u4)/\(u5)/\(u6)/\(u7)/\(u8)/\(u9)/"

        // Unique
        try Pipe("        zzzgen \(input2) |    sort unique | zzzcheck /\(u1)/\(u7)/\(u3)/\(u5)/").run()
        try Pipe("(end ?) zzzgen \(input2) | s: sort unique | zzzcheck /\(u1)/\(u7)/\(u3)/\(u5)/ ? s: | zzzcheck /\(u2)/\(u6)/\(u8)/\(u9)/\(u4)/").run()
        try Pipe("        zzzgen \(input2) |    sort unique w1 | zzzcheck /\(u1)/\(u3)/").run()
        try Pipe("(end ?) zzzgen \(input2) | s: sort unique w5 | zzzcheck /\(u1)/ ? s: | zzzcheck /\(u2)/\(u3)/\(u4)/\(u5)/\(u6)/\(u7)/\(u8)/\(u9)/").run()

        // Count
        try Pipe("        zzzgen \(input2) |    sort count | zzzcheck /         4\(u1)/         2\(u7)/         2\(u3)/         1\(u5)/").run()
        try Pipe("(end ?) zzzgen \(input2) | s: sort count | zzzcheck /         4\(u1)/         2\(u7)/         2\(u3)/         1\(u5)/ ? s: | zzzcheck /\(u2)/\(u6)/\(u8)/\(u9)/\(u4)/").run()
        try Pipe("        zzzgen \(input2) |    sort count w1 | zzzcheck /         6\(u1)/         3\(u3)/").run()
        try Pipe("(end ?) zzzgen \(input2) | s: sort count w5 | zzzcheck /         9\(u1)/ ? s: | zzzcheck /\(u2)/\(u3)/\(u4)/\(u5)/\(u6)/\(u7)/\(u8)/\(u9)/").run()

        // Can't have secondary output for normal sort
        XCTAssertThrows(try Pipe("(end ?) literal x | s: sort ? s: | hole").run(), PipeError.unusedStreamConnected(direction: .output, streamNo: 1))
    }

    func testSpec() throws {
        XCTAssertThrows(try Pipe("literal x | spec").run(), PipeError.emptyParameterList)
        XCTAssertThrows(try Pipe("literal x | spec | hole").run(), PipeError.emptyParameterList)
        XCTAssertThrows(try Pipe("literal x | spec reno | hole").run(), PipeError.invalidRange(range: "reno"))
        XCTAssertThrows(try Pipe("literal x | spec recno nb | hole").run(), PipeError.outputSpecificationInvalid(word: "nb"))
        XCTAssertThrows(try Pipe("literal x | spec w1").run(), PipeError.outputSpecificationMissing)
        XCTAssertThrows(try Pipe("literal x | spec w1 1-").run(), PipeError.outputSpecificationInvalid(word: "1-"))
        XCTAssertThrows(try Pipe("literal x | spec w1 1.X").run(), PipeError.outputSpecificationInvalid(word: "1.X"))
        XCTAssertThrows(try Pipe("literal x | spec w1 1-*").run(), PipeError.outputRangeEndInvalid)

        try Pipe("zzzgen /a/b/ | literal abcdefgh| literal mnopqrstuvwxyz| spec recno 1 1-* n /blah/ nw | zzzcheck /         1mnopqrstuvwxyz blah/         2abcdefgh blah/         3a blah/         4b blah/").run()
        try Pipe("literal | spec number 1 | zzzcheck /         1/").run()
        try Pipe("literal | spec recno 1 | zzzcheck /         1/").run()
        try Pipe("literal | spec recno 1 l /a/ n | zzzcheck /1         a/").run()
        try Pipe("literal | spec recno 1 r /a/ n | zzzcheck /         1a/").run()
        try Pipe("literal | spec recno 1 c /a/ n | zzzcheck /    1     a/").run()
        try Pipe("literal | spec recno 1 recno n | zzzcheck /         1         1/").run()
        try Pipe("literal | spec recno 1 l recno n | zzzcheck /1                  1/").run()
        try Pipe("zzzgen /a/b/c/d/ | spec number from 1 by -1 strip 1 | zzzcheck /1/0/-1/-2/").run()
        try Pipe("zzzgen /a/b/c/d/ | spec number from -5 by -3 strip 1 | zzzcheck /-5/-8/-11/-14/").run()
        try Pipe("zzzgen /a/b/c/d/ | spec number from 10 by 1 strip 1 | zzzcheck /10/11/12/13/").run()
        try Pipe("zzzgen /a/b/c/d/ | spec number from 2 by 0 strip 1 | zzzcheck /2/2/2/2/").run()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let d = formatter.string(from: Date())
        try Pipe("zzzgen /a/b/c/d/ | spec time pattern /yyyy-MM-dd/ 1 | zzzcheck /\(d)/\(d)/\(d)/\(d)/").run()

        try Pipe("literal | spec /abc/ 1 | zzzcheck /abc/").run()
        try Pipe("literal | spec /abc/ 1 l /a/ n | zzzcheck /abca/").run()
        try Pipe("literal | spec /abc/ 1 r /a/ n | zzzcheck /abca/").run()
        try Pipe("literal | spec /abc/ 1 c /a/ n | zzzcheck /abca/").run()
        try Pipe("literal | spec /abc/ 1 l /abc/ n | zzzcheck /abcabc/").run()

        try Pipe("literal abcdefgh| spec 2-5 1 | zzzcheck /bcde/").run()
        try Pipe("literal abcdefgh| spec 2-5 1 l /a/ n | zzzcheck /bcdea/").run()
        try Pipe("literal abcdefgh| spec 2-5 1 r /a/ n | zzzcheck /bcdea/").run()
        try Pipe("literal abcdefgh| spec 2-5 1 c /a/ n | zzzcheck /bcdea/").run()
        try Pipe("literal abcdefgh| spec 2-5 1 l 2-5 n | zzzcheck /bcdebcde/").run()

        try Pipe("literal abcdefgh| spec 2-5 3.4 | zzzcheck /  bcde/").run()
        try Pipe("literal abcdefgh| spec 2-3 3.4 | zzzcheck /  bc  /").run()
        try Pipe("literal abcdefgh| spec 2-5 3.2 | zzzcheck /  bc/").run()
        try Pipe("literal abcdefgh| spec 2-5 3.4 left | zzzcheck /  bcde/").run()
        try Pipe("literal abcdefgh| spec 2-3 3.4 left | zzzcheck /  bc  /").run()
        try Pipe("literal abcdefgh| spec 2-5 3.2 left | zzzcheck /  bc/").run()
        try Pipe("literal abcdefgh| spec 2-5 3.4 right | zzzcheck /  bcde/").run()
        try Pipe("literal abcdefgh| spec 2-3 3.4 right | zzzcheck /    bc/").run()
        try Pipe("literal abcdefgh| spec 2-5 3.2 right | zzzcheck /  de/").run()
        try Pipe("literal abcdefgh| spec 2-5 3.4 center | zzzcheck /  bcde/").run()
        try Pipe("literal abcdefgh| spec 2-3 3.4 center | zzzcheck /   bc /").run()
        try Pipe("literal abcdefgh| spec 2-5 3.2 center | zzzcheck /  cd/").run()

        try Pipe("literal abcdefgh| spec 1.3 n 4.3 n 1.3 n | zzzcheck /abcdefabc/").run()
        try Pipe("literal abcdefgh| spec 1.3 nw 4.3 nw 1.3 nw | zzzcheck /abc def abc/").run()
        try Pipe("literal abcdefgh| spec 1.3 nf 4.3 nf 1.3 nf | zzzcheck /abc\tdef\tabc/").run()

        try Pipe("literal abcdefgh| spec 1.3 n.3  4.3 n.3  1.3 n.3 | zzzcheck /abcdefabc/").run()
        try Pipe("literal abcdefgh| spec 1.3 nw.3 4.3 nw.3 1.3 nw.3 | zzzcheck /abc def abc/").run()
        try Pipe("literal abcdefgh| spec 1.3 nf.3 4.3 nf.3 1.3 nf.3 | zzzcheck /abc\tdef\tabc/").run()
        try Pipe("literal abcdefgh| spec 1.3 n.5  4.3 n.5  1.3 n.5 | zzzcheck /abc  def  abc  /").run()
        try Pipe("literal abcdefgh| spec 1.3 nw.5 4.3 nw.5 1.3 nw.5 | zzzcheck /abc   def   abc  /").run()
        try Pipe("literal abcdefgh| spec 1.3 nf.5 4.3 nf.5 1.3 nf.5 | zzzcheck /abc  \tdef  \tabc  /").run()
        try Pipe("literal abcdefgh| spec 1.3 n.2  4.3 n.2  1.3 n.2 | zzzcheck /abdeab/").run()
        try Pipe("literal abcdefgh| spec 1.3 nw.2 4.3 nw.2 1.3 nw.2 | zzzcheck /ab de ab/").run()
        try Pipe("literal abcdefgh| spec 1.3 nf.2 4.3 nf.2 1.3 nf.2 | zzzcheck /ab\tde\tab/").run()

        try Pipe("literal abcdefgh| spec 1.3 nw.5 right 4.3 nw.5 c 1.3 nw.5 ri | zzzcheck /  abc  def    abc/").run()

        try Pipe("literal   abc  | spec 1-* 1 | zzzcheck /  abc  /").run()
        try Pipe("literal   abc  | spec 1-* strip 1 | zzzcheck /abc/").run()
        try Pipe("literal   abc  def| spec 1-7 strip 1 8.3 n | zzzcheck /abcdef/").run()

        try Pipe("literal a b c d e f | spec w1 1 | zzzcheck /a/").run()
        try Pipe("literal a b c d e f | spec w1 n w2 n w3 n w4-6 nw | zzzcheck /abc d e f/").run()

        try Pipe("literal a | spec pad _ 1.1 1.5 | zzzcheck /a____/").run()
        try Pipe("literal a b | spec pad _ w1 1.5 pad + w2 n.4 right | zzzcheck /a____+++b/").run()

        try Pipe("literal blah| spec 1-* c2x 1 | spec 1-* x2c 1 | zzzcheck /blah/").run()
        try Pipe("literal blah| spec 1-* c2b 1 | spec 1-* b2c 1 | zzzcheck /blah/").run()

        try Pipe("zzzgen /First record/Second record/Short/ | spec 1.4 c2x 1 5.4 c2x nextword /*/ 19 1.8 next.8 /*/ next | zzzcheck /46697273 74207265 *First re*/5365636F 6E642072 *Second r*/53686F72 74       *Short   */").run()

        let csv = """
        /10,11,12/"20","21",22/"30",31,"32"/
        """
        try Pipe("zzzgen \(csv) | spec fs , q \" f2 1 f3 3 f1 5     | zzzcheck /111210/212220/313230/").run()
        try Pipe("zzzgen \(csv) | spec /_/ 1 fs , q \" f2-3 n /_/ n | zzzcheck /_11,12_/_\"21\",22_/_31,\"32\"_/").run()
    }

    func testTakeFirst() throws {
        XCTAssertThrows(try Pipe("take 2").run(), PipeError.streamNotConnected(direction: .input, streamNo: 0))
        XCTAssertThrows(try Pipe("literal a|take -50").run(), PipeError.numberCannotBeNegative(number: -50))
        XCTAssertThrows(try Pipe("literal a|take blah").run(), PipeError.invalidNumber(word: "blah"))
        XCTAssertThrows(try Pipe("literal a|take blah 3 bytes").run(), PipeError.invalidNumber(word: "blah"))
        XCTAssertThrows(try Pipe("literal a|take 3 foo").run(), PipeError.excessiveOptions(string: "foo"))
        XCTAssertThrows(try Pipe("literal a|take foo").run(), PipeError.invalidNumber(word: "foo"))
        XCTAssertThrows(try Pipe("literal a|take first 3 bytes foo").run(), PipeError.excessiveOptions(string: "foo"))

        try Pipe("zzzgen /a/b/c/d/e/ | take 0 | literal x| zzzcheck /x/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | take 3 | literal x| zzzcheck /x/a/b/c/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | take 3 lines | literal x| zzzcheck /x/a/b/c/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | take 5 | zzzcheck /a/b/c/d/e/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | take 8 | zzzcheck /a/b/c/d/e/").run()

        try Pipe("zzzgen /a/b/c/d/e/ | take 3 bytes | zzzcheck /a/b/c/").run()
        try Pipe("literal abcdefgh| take 3 bytes | zzzcheck /abc/").run()
        try Pipe("zzzgen /abcdefgh/a/b/c/d/e/ | take 10 bytes | zzzcheck /abcdefgh/a/b/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | literal abcdefgh| take 10 bytes | zzzcheck /abcdefgh/a/b/").run()
        try Pipe("literal abcdefgh| take 20 bytes | zzzcheck /abcdefgh/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | literal abcdefgh| take 20 bytes | zzzcheck /abcdefgh/a/b/c/d/e/").run()

        try Pipe("zzzgen /a/b/c/d/e/ | take 3 chars | zzzcheck /a/b/c/").run()
        try Pipe("literal abcdefgh| take 3 chars | zzzcheck /abc/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | literal abcdefgh| take 10 chars | zzzcheck /abcdefgh/a/b/").run()
        try Pipe("literal abcdefgh| take 20 chars | zzzcheck /abcdefgh/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | literal abcdefgh| take 20 chars | zzzcheck /abcdefgh/a/b/c/d/e/").run()

        // Char   Unicode                                      UTF8 Encoding
        // ------------------------------------------------------------------------------------------------------
        //  🦜    \u{1F99C}                                    F0 9F A6 9C
        //  🤦    \u{1F926}                                    F0 9F A4 A6
        //  🤦🏼‍♂️    \u{1F926}\u{1F3FC}\u{200D}\u{2642}\u{FE0F}   F0 9F A4 A6 F0 9F 8F BC E2 80 8D E2 99 82 EF B8 08
        //  👪    \u{1F46A}                                    F0 9F 91 AA
        //  🌍    \u{1F30D}                                    F0 9F 8C 8D

        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍/ | take 1 byte | zzzcheck /a/").run()
        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍/ | take 7 bytes | zzzcheck /ab \u{1F99C}/").run()
        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍/ | take 27 bytes | zzzcheck /ab \u{1F99C} c 🤦🏼‍♂️/").run()
        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍/ | take 1 char | zzzcheck /a/").run()
        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍/ | take 7 chars | zzzcheck /ab \u{1F99C} c /").run()
        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍/ | take 27 chars | zzzcheck /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍/").run()

        XCTAssertThrows(try Pipe("zzzgen /🌍/ | take 1 byte | zzzcheck //").run(), PipeError.invalidString)
        try Pipe("zzzgen /🌍/ | take 1 char | zzzcheck /🌍/").run()

        try Pipe("(end ?) zzzgen /a/b/c/d/e/ | t: take 2 | zzzcheck /a/b/").run()
        try Pipe("(end ?) zzzgen /a/b/c/d/e/ | t: take 2 | zzzcheck /a/b/ ? t: | zzzcheck /c/d/e/").run()
        try Pipe("(end ?) literal abcdefgh| t: take 2 bytes | zzzcheck /ab/ ? t: | zzzcheck /cdefgh/").run()
        try Pipe("(end ?) zzzgen /aaa/bbb/ccc/ddd/ | t: take 8 bytes | zzzcheck /aaa/bbb/cc/ ? t: | zzzcheck /c/ddd/").run()

        // no output stream is connected, so take terminates immediately, which shuts zzzgen down too
        try Pipe("(end ?) zzzgen /a/b/c/d/e/ | t: take 2 ? t: | literal x| zzzcheck /x/").run()
        // however, now cons is in the picture so we can keep going.
        try Pipe("(end ?) zzzgen /a/b/c/d/e/ | t: take 2 | console | zzzcheck /a/b/ ? t: | literal x| zzzcheck /x/c/d/e/").run()
    }

    func testTakeLast() throws {
        try Pipe("zzzgen /a/b/c/d/e/ | take last 0 | literal x| zzzcheck /x/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | take last 3 | literal x| zzzcheck /x/c/d/e/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | take last 3 lines | literal x| zzzcheck /x/c/d/e/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | take last 5 | zzzcheck /a/b/c/d/e/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | take last 8 | zzzcheck /a/b/c/d/e/").run()

        try Pipe("zzzgen /a/b/c/d/e/ | take last 3 bytes | zzzcheck /c/d/e/").run()
        try Pipe("literal abcdefgh| take last 3 bytes | zzzcheck /fgh/").run()
        try Pipe("zzzgen /abcdefgh/a/b/c/d/e/ | take last 10 bytes | zzzcheck /defgh/a/b/c/d/e/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | literal abcdefgh| take last 10 bytes | zzzcheck /defgh/a/b/c/d/e/").run()
        try Pipe("literal abcdefgh| take last 20 bytes | zzzcheck /abcdefgh/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | literal abcdefgh| take last 20 bytes | zzzcheck /abcdefgh/a/b/c/d/e/").run()

        try Pipe("zzzgen /a/b/c/d/e/ | take last 3 chars | zzzcheck /c/d/e/").run()
        try Pipe("literal abcdefgh| take last 3 chars | zzzcheck /fgh/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | literal abcdefgh| take last 10 chars | zzzcheck /defgh/a/b/c/d/e/").run()
        try Pipe("literal abcdefgh| take last 20 chars | zzzcheck /abcdefgh/").run()
        try Pipe("zzzgen /a/b/c/d/e/ | literal abcdefgh| take last 20 chars | zzzcheck /abcdefgh/a/b/c/d/e/").run()

        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍 z/ | take last 1 byte | zzzcheck /z/").run()
        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍 z/ | take last 7 bytes | zzzcheck / 🌍 z/").run()
        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍 z/ | take last 31 bytes | zzzcheck /🤦🏼‍♂️ d \u{1F46A} 🌍 z/").run()
        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍 z/ | take last 1 char | zzzcheck /z/").run()
        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍 z/ | take last 7 chars | zzzcheck /d \u{1F46A} 🌍 z/").run()
        try Pipe("zzzgen /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍 z/ | take last 27 chars | zzzcheck /ab \u{1F99C} c 🤦🏼‍♂️ d \u{1F46A} 🌍 z/").run()

        XCTAssertThrows(try Pipe("zzzgen /🌍/ | take last 1 byte | zzzcheck //").run(), PipeError.invalidString)
        try Pipe("zzzgen /🌍/ | take last 1 char | zzzcheck /🌍/").run()

        try Pipe("(end ?) zzzgen /a/b/c/d/e/ | t: take last 2 | zzzcheck /d/e/").run()
        try Pipe("(end ?) zzzgen /a/b/c/d/e/ | t: take last 2 | zzzcheck /d/e/ ? t: | zzzcheck /a/b/c/").run()
        try Pipe("(end ?) literal abcdefgh| t: take last 2 bytes | zzzcheck /gh/ ? t: | zzzcheck /abcdef/").run()
        try Pipe("(end ?) zzzgen /aaa/bbb/ccc/ddd/ | t: take last 8 bytes | zzzcheck /bb/ccc/ddd/ ? t: | zzzcheck /aaa/b/").run()

        // different to "take first 2" because "take last" will already have written a/b/c before it terminates
        try Pipe("(end ?) zzzgen /a/b/c/d/e/ | t: take last 2 ? t: | literal x| zzzcheck /x/a/b/c/").run()
        // cons is in the picture, but should be the same result as above
        try Pipe("(end ?) zzzgen /a/b/c/d/e/ | t: take last 2 | console | zzzcheck /d/e/ ? t: | literal x| zzzcheck /x/a/b/c/").run()
    }

    func testZZZ() throws {
        try Pipe("zzzgen // | zzzcheck //").run()
        try Pipe("zzzgen /a/b/c/ | zzzcheck /a/b/c/").run()
    }
}
