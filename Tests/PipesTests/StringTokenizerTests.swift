import XCTest
@testable import Pipes

final class StringTokenizerTests: XCTestCase {
    func testTokenizing() throws {
        var st: StringTokenizer

        st = StringTokenizer("")
        XCTAssertEqual(nil, st.peekWord())
        XCTAssertEqual(nil, st.scanWord())
        XCTAssertEqual(nil, st.peekChar())
        XCTAssertEqual(nil, st.scanChar())
        XCTAssertEqual(nil, st.scan(between: "(", and: ")"))
        XCTAssertEqual("", st.scanRemainder(trimLeading: true, trimTrailing: true))

        st = StringTokenizer("hello")
        XCTAssertEqual("hello", st.peekWord())
        XCTAssertEqual("hello", st.scanWord())
        XCTAssertEqual(nil, st.scanWord())
        XCTAssertEqual("", st.scanRemainder(trimLeading: true, trimTrailing: true))

        st = StringTokenizer("  hello")
        XCTAssertEqual("hello", st.scanWord())
        XCTAssertEqual(nil, st.scanWord())
        XCTAssertEqual("", st.scanRemainder(trimLeading: true, trimTrailing: true))

        st = StringTokenizer("  hello ")
        XCTAssertEqual("hello", st.scanWord())
        XCTAssertEqual(nil, st.scanWord())
        XCTAssertEqual("", st.scanRemainder(trimLeading: true, trimTrailing: true))

        st = StringTokenizer("  hello there, how are you  ")
        XCTAssertEqual("hello", st.scanWord())
        XCTAssertEqual("there,", st.scanWord())
        XCTAssertEqual("how", st.scanWord())
        XCTAssertEqual("are you", st.scanRemainder(trimLeading: true, trimTrailing: true))
        XCTAssertEqual("are you  ", st.scanRemainder(trimLeading: true, trimTrailing: false))

        st = StringTokenizer("  abc d (e f) g h   i  ")
        XCTAssertEqual("abc", st.peekWord())
        XCTAssertEqual("abc", st.scanWord())
        st.undo()
        XCTAssertEqual("abc", st.scanWord())
        XCTAssertEqual("d", st.scanWord())
        XCTAssertEqual("e f", st.scan(between: "(", and: ")"))
        XCTAssertEqual("g", st.scanWord())
        XCTAssertEqual("h", st.scanWord())
        XCTAssertEqual("i", st.scanWord())
        XCTAssertEqual("", st.scanRemainder(trimLeading: true, trimTrailing: true))

        st = StringTokenizer("  abc d (e f) g h   i  ")
        XCTAssertEqual("e f", st.scan(between: "(", and: ")"))

        st = StringTokenizer("  (abc")
        XCTAssertEqual(nil, st.scan(between: "(", and: ")"))

        st = StringTokenizer("  abc")
        XCTAssertEqual(nil, st.scan(between: "(", and: ")"))

        st = StringTokenizer("  abc def  ")
        XCTAssertEqual("a", st.peekChar())
        XCTAssertEqual("abc", st.peekWord())
        XCTAssertEqual("a", st.scanChar())
        XCTAssertEqual("bc", st.scanWord())
        XCTAssertEqual("d", st.scanChar())
        XCTAssertEqual("e", st.scanChar())
        XCTAssertEqual("f", st.scanChar())
        XCTAssertEqual(nil, st.scanChar())
    }

    func testDelimitedString() throws {
        var args: Args

        args = try Args("dummy")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.requiredOperandMissing)
        XCTAssertEqual("", args.scanRemainder())

        args = try Args("dummy /hello/")
        XCTAssertEqual("hello", try args.scanDelimitedString())
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.requiredOperandMissing)
        XCTAssertEqual("", args.scanRemainder())

        args = try Args("dummy   /hello/")
        XCTAssertEqual("hello", try args.scanDelimitedString())
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.requiredOperandMissing)
        XCTAssertEqual("", args.scanRemainder())

        args = try Args("dummy   /hello/ ")
        XCTAssertEqual("hello", try args.scanDelimitedString())
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.requiredOperandMissing)
        XCTAssertEqual("", args.scanRemainder())

        args = try Args("dummy   ,hello,  ")
        XCTAssertEqual("hello", try args.scanDelimitedString())
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.requiredOperandMissing)
        XCTAssertEqual("", args.scanRemainder())

        args = try Args("dummy   ,hello, /there,/ /how/ /are/ /you/  ")
        XCTAssertEqual("hello", try args.scanDelimitedString())
        XCTAssertEqual("there,", try args.scanDelimitedString())
        XCTAssertEqual("how", try args.scanDelimitedString())
        XCTAssertEqual("/are/ /you/", args.scanRemainder())
        XCTAssertEqual("/are/ /you/  ", args.scanRemainder(trimTrailing: false))

        args = try Args("dummy /hello")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.delimiterMissing(delimiter: "/"))

        args = try Args("dummy b00111000")
        XCTAssertEqual("8", try args.scanDelimitedString())

        args = try Args("dummy b11000010")
        XCTAssertEqual("\u{00C2}", try args.scanDelimitedString())

        args = try Args("dummy   b00111000  ")
        XCTAssertEqual("8", try args.scanDelimitedString())
        XCTAssertEqual("", args.scanRemainder())

        args = try Args("dummy   b00111000 b00111000 /a/  ")
        XCTAssertEqual("8", try args.scanDelimitedString())
        XCTAssertEqual("8", try args.scanDelimitedString())
        XCTAssertEqual("a", try args.scanDelimitedString())
        XCTAssertEqual("", args.scanRemainder())

        args = try Args("dummy b001110000011100100111010")
        XCTAssertEqual("89:", try args.scanDelimitedString())

        args = try Args("dummy b")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.binaryDataMissing(prefix: "b"))

        args = try Args("dummy  b ")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.binaryDataMissing(prefix: "b"))

        args = try Args("dummy b1111")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.binaryStringNotDivisibleBy8(string: "b1111"))

        args = try Args("dummy bxxxxxxxx")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.binaryStringNotBinary(string: "bxxxxxxxx"))

        args = try Args("dummy x20")
        XCTAssertEqual(" ", try args.scanDelimitedString())

        args = try Args("dummy x4D")
        XCTAssertEqual("M", try args.scanDelimitedString())

        args = try Args("dummy x4D204D204D")
        XCTAssertEqual("M M M", try args.scanDelimitedString())

        args = try Args("dummy x")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.hexDataMissing(prefix: "x"))

        args = try Args("dummy  x ")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.hexDataMissing(prefix: "x"))

        args = try Args("dummy xA")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.hexStringNotDivisibleBy2(string: "xA"))

        args = try Args("dummy xxxxxxxxx")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.hexStringNotHex(string: "xxxxxxxxx"))

        args = try Args("dummy hello there, /how/ are you  ")
        XCTAssertEqual("hello", try args.scanWord())
        XCTAssertEqual("there,", try args.scanWord())
        XCTAssertEqual("/how/", try args.scanWord())
        args.undo()
        XCTAssertEqual("/how/", try args.scanWord())
        args.undo()
        XCTAssertEqual("how", try args.scanDelimitedString())

        args = try Args("dummy hello there")
        XCTAssertThrows(try args.scanExpression(), PipeError.requiredOperandMissing)
        XCTAssertEqual("hello", try args.scanWord())
        XCTAssertEqual("there", try args.scanWord())
        args = try Args("dummy hello (hi there) there")
        XCTAssertThrows(try args.scanExpression(), PipeError.requiredOperandMissing)
        XCTAssertEqual("hello", try args.scanWord())
        XCTAssertEqual("(hi", try args.scanWord())
        XCTAssertEqual("there)", try args.scanWord())
        XCTAssertEqual("there", try args.scanWord())
        args = try Args("dummy (hi there) there")
        XCTAssertEqual("hi there", try args.scanExpression())
        XCTAssertEqual("there", try args.scanWord())

        args = try Args("dummy (hi")
        XCTAssertThrows(try args.scanExpression(), PipeError.missingEndingParenthesis)
    }

    func testSplitSimple() {
        XCTAssertEqual("".split(separator: "|", escape: nil), [""])
        XCTAssertEqual(" ".split(separator: "|", escape: nil), [" "])
        XCTAssertEqual(" |".split(separator: "|", escape: nil), [" ", ""])
        XCTAssertEqual(" | ".split(separator: "|", escape: nil), [" ", " "])
        XCTAssertEqual("a | b | c | d ".split(separator: "|", escape: nil), ["a ", " b ", " c ", " d "])
        XCTAssertEqual("||||".split(separator: "|", escape: nil), ["", "", "", "", ""])

        XCTAssertEqual("".split(separator: "|", escape: "^"), [""])
        XCTAssertEqual(" ".split(separator: "|", escape: "^"), [" "])
        XCTAssertEqual(" |".split(separator: "|", escape: "^"), [" ", ""])
        XCTAssertEqual(" | ".split(separator: "|", escape: "^"), [" ", " "])
        XCTAssertEqual("a | b | c | d ".split(separator: "|", escape: "^"), ["a ", " b ", " c ", " d "])
        XCTAssertEqual("||||".split(separator: "|", escape: "^"), ["", "", "", "", ""])
    }

    func testEscapingStages() {
        XCTAssertEqual("a ^| b | ".split(separator: "|", escape: "^"), ["a | b ", " "])
        XCTAssertEqual("^| ".split(separator: "|", escape: "^"), ["| "])
        XCTAssertEqual("^|^| b | ".split(separator: "|", escape: "^"), ["|| b ", " "])
        XCTAssertEqual("^^ b | ".split(separator: "|", escape: "^"), ["^ b ", " "])
        XCTAssertEqual("^^| b | ".split(separator: "|", escape: "^"), ["^", " b ", " "])
        XCTAssertEqual("a | b | ^".split(separator: "|", escape: "^"), ["a ", " b ", " "])
        XCTAssertEqual("|^||^^^||^||^".split(separator: "|", escape: "^"), ["", "|", "^|", "|", ""])
    }

    func testEscapingStrings() {
        XCTAssertEqual(StringTokenizer("", escape: nil).peekChar(), nil)
        XCTAssertEqual(StringTokenizer("X", escape: nil).peekChar(), "X")
        XCTAssertEqual(StringTokenizer("^", escape: nil).peekChar(), "^")
        XCTAssertEqual(StringTokenizer("^ X", escape: nil).peekChar(), "^")
        XCTAssertEqual(StringTokenizer("^A X", escape: nil).peekChar(), "^")
        XCTAssertEqual(StringTokenizer("^^ X", escape: nil).peekChar(), "^")
        XCTAssertEqual(StringTokenizer("^^^ X", escape: nil).peekChar(), "^")
        XCTAssertEqual(StringTokenizer("", escape: "^").peekChar(), nil)
        XCTAssertEqual(StringTokenizer("X", escape: "^").peekChar(), "X")
        XCTAssertEqual(StringTokenizer("^", escape: "^").peekChar(), nil)
        XCTAssertEqual(StringTokenizer("^ X", escape: "^").peekChar(), "X")
        XCTAssertEqual(StringTokenizer("^A X", escape: "^").peekChar(), "A")
        XCTAssertEqual(StringTokenizer("  ^A X", escape: "^").peekChar(), "A")
        XCTAssertEqual(StringTokenizer("^^ X", escape: "^").peekChar(), "^")
        XCTAssertEqual(StringTokenizer("^^^ X", escape: "^").peekChar(), "^")

        XCTAssertEqual(StringTokenizer("", escape: nil).peekWord(), nil)
        XCTAssertEqual(StringTokenizer("X", escape: nil).peekWord(), "X")
        XCTAssertEqual(StringTokenizer("abc^de fgh", escape: nil).peekWord(), "abc^de")
        XCTAssertEqual(StringTokenizer("abc^ de fgh", escape: nil).peekWord(), "abc^")
        XCTAssertEqual(StringTokenizer("", escape: "^").peekWord(), nil)
        XCTAssertEqual(StringTokenizer(" ", escape: "^").peekWord(), nil)
        XCTAssertEqual(StringTokenizer("abc^de fgh", escape: "^").peekWord(), "abcde")
        XCTAssertEqual(StringTokenizer("abc^ de fgh", escape: "^").peekWord(), "abc de")

        XCTAssertEqual(StringTokenizer("a/bcde/f", escape: nil).scan(between: "/", and: "/"), "bcde")
        XCTAssertEqual(StringTokenizer("a/bc^de/f", escape: nil).scan(between: "/", and: "/"), "bc^de")
        XCTAssertEqual(StringTokenizer("a/bc^/de/f", escape: nil).scan(between: "/", and: "/"), "bc^")
        XCTAssertEqual(StringTokenizer("a/bcde/f", escape: "^").scan(between: "/", and: "/"), "bcde")
        XCTAssertEqual(StringTokenizer("a/bc^de/f", escape: "^").scan(between: "/", and: "/"), "bcde")
        XCTAssertEqual(StringTokenizer("a/bc^/de/f", escape: "^").scan(between: "/", and: "/"), "bc/de")

        XCTAssertEqual(StringTokenizer("  a/bc^de/f  ", escape: nil).scanRemainder(trimLeading: true, trimTrailing: true), "a/bc^de/f")
        XCTAssertEqual(StringTokenizer("  a/bc^de/f  ", escape: nil).scanRemainder(trimLeading: false, trimTrailing: false), "  a/bc^de/f  ")
        XCTAssertEqual(StringTokenizer("  a/bc^de/f  ", escape: "^").scanRemainder(trimLeading: true, trimTrailing: true), "a/bcde/f")
        XCTAssertEqual(StringTokenizer("  a/bc^de/f  ", escape: "^").scanRemainder(trimLeading: false, trimTrailing: false), "  a/bcde/f  ")
    }

    func testOptions() throws {
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "< blah | cons").0, Options.default)
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "< blah | cons").1, "< blah | cons")
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(foobar)   < blah | cons  ").0, Options(stageSep: "|", escape: nil, endChar: nil))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(foobar)   < blah | cons  ").1, "   < blah | cons  ")
        XCTAssertThrows(try Parser.parseOptions(pipeSpec: "(foobar < blah | cons"), PipeError.missingEndingParenthesis)
    }
}
