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
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(sep |)   < blah | cons  ").0, Options(stageSep: "|", escape: nil, endChar: nil))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(sep |)   < blah | cons  ").1, "   < blah | cons  ")
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(   sep    |  )   < blah | cons  ").0, Options(stageSep: "|", escape: nil, endChar: nil))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(sep ! esc ^ end ?)   < blah | cons  ").0, Options(stageSep: "!", escape: "^", endChar: "?"))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(end ? sep ! esc ^)   < blah | cons  ").0, Options(stageSep: "!", escape: "^", endChar: "?"))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(sep X esc ^ end ? sep !)   < blah | cons  ").0, Options(stageSep: "!", escape: "^", endChar: "?"))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(sep 20)").0, Options(stageSep: " ", escape: nil, endChar: nil))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(sep 40)").0, Options(stageSep: "@", escape: nil, endChar: nil))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(sep 65)").0, Options(stageSep: "e", escape: nil, endChar: nil))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(sep BLANK)").0, Options(stageSep: " ", escape: nil, endChar: nil))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "(sep TAB)").0, Options(stageSep: "\t", escape: nil, endChar: nil))
        XCTAssertEqual(try Parser.parseOptions(pipeSpec: "()").0, Options.default)

        XCTAssertThrows(try Parser.parseOptions(pipeSpec: "(sep |"), PipeError.missingEndingParenthesis)
        XCTAssertThrows(try Parser.parseOptions(pipeSpec: "(foo |)"), PipeError.optionNotValid(option: "foo"))
        XCTAssertThrows(try Parser.parseOptions(pipeSpec: "(sep)"), PipeError.valueMissingForOption(keyword: "sep"))
        XCTAssertThrows(try Parser.parseOptions(pipeSpec: "(sep )"), PipeError.valueMissingForOption(keyword: "sep"))
        XCTAssertThrows(try Parser.parseOptions(pipeSpec: "(sep abc)"), PipeError.invalidCharacterRepresentation(word: "abc"))
        XCTAssertThrows(try Parser.parseOptions(pipeSpec: "(sep zz)"), PipeError.invalidCharacterRepresentation(word: "zz"))
    }

    func testPipeScanning() throws {
        XCTAssertThrows(try Pipe(""), PipeError.noPipelineSpecified)
        XCTAssertThrows(try Pipe("()"), PipeError.noPipelineSpecified)
        XCTAssertThrows(try Pipe("(end ?) |"), PipeError.nullStageFound)
        XCTAssertThrows(try Pipe("(end ?) ?"), PipeError.noPipelineSpecified)
        XCTAssertThrows(try Pipe("(end ?) literal a| cons ?"), PipeError.noPipelineSpecified)
        _ = try Pipe("() literal blah")

        XCTAssertThrows(try Pipe("console | | console"), PipeError.nullStageFound)
        XCTAssertThrows(try Pipe("gsdfgsdfgsd"), PipeError.stageNotFound(stageName: "gsdfgsdfgsd"))
        XCTAssertThrows(try Pipe("(end ?) literal a f: fanout | cons ? f: | cons"), PipeError.labelNotDeclared(label: "f:"))
    }

    func testSyntaxKeywordMatching() {
        XCTAssertEqual("TAB".matchesKeyword("TABulate"), true)
        XCTAssertEqual("TABUL".matchesKeyword("TABulate"), true)
        XCTAssertEqual("TABUX".matchesKeyword("TABulate"), false)

        XCTAssertEqual("tab".matchesKeyword("TAB"), true)
        XCTAssertEqual("ta".matchesKeyword("TABulate"), false)
        XCTAssertEqual("tab".matchesKeyword("TABulate"), true)
        XCTAssertEqual("tabul".matchesKeyword("TABulate"), true)
        XCTAssertEqual("tabux".matchesKeyword("TABulate"), false)

        XCTAssertEqual("tabulate".matchesKeyword("TABulate"), true)
        XCTAssertEqual("tabulatex".matchesKeyword("TABulate"), false)
    }

    func testSyntaxAlignment() {
        XCTAssertEqual("abc".aligned(alignment: .left, length: 1, pad: "_", truncate: false), "abc")
        XCTAssertEqual("abc".aligned(alignment: .left, length: 3, pad: "_", truncate: false), "abc")
        XCTAssertEqual("abc".aligned(alignment: .left, length: 4, pad: "_", truncate: false), "abc_")
        XCTAssertEqual("abc".aligned(alignment: .left, length: 6, pad: "_", truncate: false), "abc___")
        XCTAssertEqual("abc".aligned(alignment: .left, length: 1, pad: "_", truncate: true), "a")
        XCTAssertEqual("abc".aligned(alignment: .left, length: 2, pad: "_", truncate: true), "ab")
        XCTAssertEqual("abc".aligned(alignment: .left, length: 3, pad: "_", truncate: true), "abc")
        XCTAssertEqual("abc".aligned(alignment: .left, length: 4, pad: "_", truncate: true), "abc_")
        XCTAssertEqual("abc".aligned(alignment: .left, length: 6, pad: "_", truncate: true), "abc___")

        XCTAssertEqual("abc".aligned(alignment: .right, length: 1, pad: "_", truncate: false), "abc")
        XCTAssertEqual("abc".aligned(alignment: .right, length: 3, pad: "_", truncate: false), "abc")
        XCTAssertEqual("abc".aligned(alignment: .right, length: 4, pad: "_", truncate: false), "_abc")
        XCTAssertEqual("abc".aligned(alignment: .right, length: 6, pad: "_", truncate: false), "___abc")
        XCTAssertEqual("abc".aligned(alignment: .right, length: 1, pad: "_", truncate: true), "c")
        XCTAssertEqual("abc".aligned(alignment: .right, length: 2, pad: "_", truncate: true), "bc")
        XCTAssertEqual("abc".aligned(alignment: .right, length: 3, pad: "_", truncate: true), "abc")
        XCTAssertEqual("abc".aligned(alignment: .right, length: 4, pad: "_", truncate: true), "_abc")
        XCTAssertEqual("abc".aligned(alignment: .right, length: 6, pad: "_", truncate: true), "___abc")

        XCTAssertEqual("abc".aligned(alignment: .center, length: 1, pad: "_", truncate: false), "abc")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 3, pad: "_", truncate: false), "abc")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 4, pad: "_", truncate: false), "abc_")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 6, pad: "_", truncate: false), "_abc__")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 7, pad: "_", truncate: false), "__abc__")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 8, pad: "_", truncate: false), "__abc___")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 1, pad: "_", truncate: true), "b")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 2, pad: "_", truncate: true), "ab")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 3, pad: "_", truncate: true), "abc")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 4, pad: "_", truncate: true), "abc_")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 6, pad: "_", truncate: true), "_abc__")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 7, pad: "_", truncate: true), "__abc__")
        XCTAssertEqual("abc".aligned(alignment: .center, length: 8, pad: "_", truncate: true), "__abc___")
        XCTAssertEqual("abcdefg".aligned(alignment: .center, length: 1, pad: "_", truncate: true), "d")
        XCTAssertEqual("abcdefg".aligned(alignment: .center, length: 2, pad: "_", truncate: true), "cd")
        XCTAssertEqual("abcdefg".aligned(alignment: .center, length: 3, pad: "_", truncate: true), "cde")
        XCTAssertEqual("abcdefgh".aligned(alignment: .center, length: 1, pad: "_", truncate: true), "d")
        XCTAssertEqual("abcdefgh".aligned(alignment: .center, length: 2, pad: "_", truncate: true), "de")
        XCTAssertEqual("abcdefgh".aligned(alignment: .center, length: 3, pad: "_", truncate: true), "cde")
    }

    func testSyntaxInsertString() {
        XCTAssertEqual("abcdefgh".insertString(string: "___", start: 1), "___defgh")
        XCTAssertEqual("abcdefgh".insertString(string: "___", start: 2), "a___efgh")
        XCTAssertEqual("abcdefgh".insertString(string: "___", start: 5), "abcd___h")
        XCTAssertEqual("abcdefgh".insertString(string: "___", start: 6), "abcde___")
        XCTAssertEqual("abcdefgh".insertString(string: "___", start: 10), "abcdefgh ___")
        XCTAssertEqual("abcdefgh".insertString(string: "___", start: 15), "abcdefgh      ___")
    }

    func testConversion() {
        XCTAssertEqual(try Conversion.c2b.convert("a"), "01100001")
        XCTAssertEqual(try Conversion.c2b.convert("ab"), "0110000101100010")
        XCTAssertEqual(try Conversion.c2b.convert("abc"), "011000010110001001100011")
        XCTAssertEqual(try Conversion.b2c.convert("01100001"), "a")
        XCTAssertEqual(try Conversion.b2c.convert("0110000101100010"), "ab")
        XCTAssertEqual(try Conversion.b2c.convert("011000010110001001100011"), "abc")
        XCTAssertEqual(try Conversion.c2b.convert("🤦🏼‍♂️🌍🦜"), "11110000100111111010010010100110111100001001111110001111101111001110001010000000100011011110001010011001100000101110111110111000100011111111000010011111100011001000110111110000100111111010011010011100")
        XCTAssertEqual(try Conversion.b2c.convert("11110000100111111010010010100110111100001001111110001111101111001110001010000000100011011110001010011001100000101110111110111000100011111111000010011111100011001000110111110000100111111010011010011100"), "🤦🏼‍♂️🌍🦜")
        XCTAssertThrows(try Conversion.b2c.convert("a"), PipeError.conversionError(type: "B2C", reason: "The number of characters in a bit field is not divisible by 8", input: "a"))
        XCTAssertThrows(try Conversion.b2c.convert("0100"), PipeError.conversionError(type: "B2C", reason: "The number of characters in a bit field is not divisible by 8", input: "0100"))
        XCTAssertThrows(try Conversion.b2c.convert("aaaabbbb"), PipeError.conversionError(type: "B2C", reason: "Invalid binary value", input: "aaaabbbb"))

        XCTAssertEqual(try Conversion.c2x.convert("a"), "61")
        XCTAssertEqual(try Conversion.c2x.convert("ab"), "6162")
        XCTAssertEqual(try Conversion.c2x.convert("abc"), "616263")
        XCTAssertEqual(try Conversion.x2c.convert("61"), "a")
        XCTAssertEqual(try Conversion.x2c.convert("6162"), "ab")
        XCTAssertEqual(try Conversion.x2c.convert("616263"), "abc")
        XCTAssertEqual(try Conversion.c2x.convert("🤦🏼‍♂️🌍🦜"), "F09FA4A6F09F8FBCE2808DE29982EFB88FF09F8C8DF09FA69C")
        XCTAssertEqual(try Conversion.x2c.convert("F09FA4A6F09F8FBCE2808DE29982EFB88FF09F8C8DF09FA69C"), "🤦🏼‍♂️🌍🦜")
        XCTAssertThrows(try Conversion.x2c.convert("a"), PipeError.conversionError(type: "X2C", reason: "Odd number of characters in a hexadecimal field", input: "a"))
        XCTAssertThrows(try Conversion.x2c.convert("MM"), PipeError.conversionError(type: "X2C", reason: "Invalid hex value", input: "MM"))

        XCTAssertEqual(try Conversion.x2b.convert("61"), "01100001")
        XCTAssertEqual(try Conversion.x2b.convert("6162"), "0110000101100010")
        XCTAssertEqual(try Conversion.x2b.convert("616263"), "011000010110001001100011")
        XCTAssertEqual(try Conversion.b2x.convert("01100001"), "61")
        XCTAssertEqual(try Conversion.b2x.convert("0110000101100010"), "6162")
        XCTAssertEqual(try Conversion.b2x.convert("011000010110001001100011"), "616263")
        XCTAssertEqual(try Conversion.x2b.convert("F09FA4A6F09F8FBCE2808DE29982EFB88FF09F8C8DF09FA69C"), "11110000100111111010010010100110111100001001111110001111101111001110001010000000100011011110001010011001100000101110111110111000100011111111000010011111100011001000110111110000100111111010011010011100")
        XCTAssertEqual(try Conversion.b2x.convert("11110000100111111010010010100110111100001001111110001111101111001110001010000000100011011110001010011001100000101110111110111000100011111111000010011111100011001000110111110000100111111010011010011100"), "F09FA4A6F09F8FBCE2808DE29982EFB88FF09F8C8DF09FA69C")
    }
}
