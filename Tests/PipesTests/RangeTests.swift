import XCTest
@testable import Pipes

final class RangeTests: XCTestCase {
    func testRangeExtractColumn() throws {
        XCTAssertThrows(try "".extract(fromRange: PipeRange.column(start: 0, end: 1)), PipeError.invalidRange(range: "0;1"))
        XCTAssertThrows(try "".extract(fromRange: PipeRange.column(start: 2, end: 1)), PipeError.invalidRange(range: "2;1"))
        XCTAssertThrows(try "".extract(fromRange: PipeRange.column(start: -2, end: -3)), PipeError.invalidRange(range: "-2;-3"))

        XCTAssertEqual(try "".extract(fromRange: PipeRange.column(start: 2, end: 2)), "")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 2, end: 2)), "b")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 2, end: 4)), "bcd")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 1, end: 10)), "abcdefghij")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 1, end: 100)), "abcdefghij")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 99, end: 100)), "")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 3, end: -3)), "cdefgh")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: -5, end: -3)), "fgh")

        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: .end, end: 3)), "abc")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 3, end: .end)), "cdefghij")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: .end, end: .end)), "abcdefghij")

        XCTAssertEqual(try "abcde".extract(fromRange: PipeRange.column(start: 2, end: -2)), "bcd")
        XCTAssertThrows(try "abcde".extract(fromRange: PipeRange.column(start: 2, end: -5)), PipeError.invalidRange(range: "2;-5"))
        XCTAssertEqual(try "abcdefgh".extract(fromRange: PipeRange.column(start: 2, end: -5)), "bcd")

        // TODO range substrings
        // String s = "abcdefghijklmnopqrstuvwxyz"
        // assertEquals("abcdefghijklm", scanRange(new PipeArgs("1-13 "), true).extractRange(s))
        // assertEquals("cdefghij", scanRange(new PipeArgs("SUBSTR 3.8 OF 1-13 "), true).extractRange(s))
        // assertEquals("defg", scanRange(new PipeArgs("SUBSTR 2-5 OF SUBSTR 3.8 OF 1-13 "), true).extractRange(s))
    }

    func testRangeExtractWords() throws {
        let s = "  hello there   how   are   you today? I am well thanks  "
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: 1, end: 1)), "hello")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: 3, end: 3)), "how")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: 1, end: 3)), "hello there   how")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: 1, end: 6)), "hello there   how   are   you today?")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: 1, end: .end)), "hello there   how   are   you today? I am well thanks")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: 1, end: 10)), "hello there   how   are   you today? I am well thanks")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: -1, end: -1)), "thanks")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: -2, end: -1)), "well thanks")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: 9, end: 10)), "well thanks")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: 9, end: -1)), "well thanks")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.word(start: 7, end: 7)), "I")

        let t = "xxhelloxtherexxxhowxxxarexxxyouxtoday?xIxamxwellxthanksxx"
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: 1, end: 1, separator: "x")), "hello")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: 3, end: 3, separator: "x")), "how")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: 1, end: 3, separator: "x")), "helloxtherexxxhow")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: 1, end: 6, separator: "x")), "helloxtherexxxhowxxxarexxxyouxtoday?")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: 1, end: .end, separator: "x")), "helloxtherexxxhowxxxarexxxyouxtoday?xIxamxwellxthanks")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: 1, end: 10, separator: "x")), "helloxtherexxxhowxxxarexxxyouxtoday?xIxamxwellxthanks")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: -1, end: -1, separator: "x")), "thanks")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: -2, end: -1, separator: "x")), "wellxthanks")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: 9, end: 10, separator: "x")), "wellxthanks")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: 9, end: -1, separator: "x")), "wellxthanks")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.word(start: 7, end: 7, separator: "x")), "I")

        XCTAssertEqual(try "".extract(fromRange: PipeRange.word(start: 2, end: 2)), "")
        XCTAssertEqual(try "hello".extract(fromRange: PipeRange.word(start: 1, end: 1)), "hello")
        XCTAssertEqual(try "hello".extract(fromRange: PipeRange.word(start: 2, end: 2)), "")
        XCTAssertEqual(try "hello".extract(fromRange: PipeRange.word(start: -2, end: -1)), "hello")
    }

    func testRangeExtractFields() {
        let s = ",b,,d,eeee,fff,ggg,"
        XCTAssertEqual(try s.extract(fromRange: PipeRange.field(start: 1, end: 1, separator: ",")), "")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.field(start: 2, end: 2, separator: ",")), "b")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.field(start: 4, end: 6, separator: ",")), "d,eeee,fff")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.field(start: 1, end: 7, separator: ",")), ",b,,d,eeee,fff,ggg")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.field(start: 1, end: .end, separator: ",")), ",b,,d,eeee,fff,ggg,")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.field(start: 1, end: 8, separator: ",")), ",b,,d,eeee,fff,ggg,")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.field(start: -1, end: -1, separator: ",")), "")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.field(start: -2, end: -1, separator: ",")), "ggg,")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.field(start: 7, end: 8, separator: ",")), "ggg,")
        XCTAssertEqual(try s.extract(fromRange: PipeRange.field(start: 7, end: -1, separator: ",")), "ggg,")

        let t = "xbxxdxeeeexfffxgggx";
        XCTAssertEqual(try t.extract(fromRange: PipeRange.field(start: 1, end: 1, separator: "x")), "")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.field(start: 2, end: 2, separator: "x")), "b")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.field(start: 4, end: 6, separator: "x")), "dxeeeexfff")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.field(start: 1, end: 7, separator: "x")), "xbxxdxeeeexfffxggg")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.field(start: 1, end: .end, separator: "x")), "xbxxdxeeeexfffxgggx")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.field(start: 1, end: 8, separator: "x")), "xbxxdxeeeexfffxgggx")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.field(start: -1, end: -1, separator: "x")), "")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.field(start: -2, end: -1, separator: "x")), "gggx")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.field(start: 7, end: 8, separator: "x")), "gggx")
        XCTAssertEqual(try t.extract(fromRange: PipeRange.field(start: 7, end: -1, separator: "x")), "gggx")
    }

    func testSimpleMatches() throws {
        XCTAssertEqual(try "".matches(), false)
        XCTAssertEqual(try "xxx".matches(), true)
        XCTAssertEqual(try "".matches(""), false)
        XCTAssertEqual(try "".matches("xxx"), false)

        XCTAssertEqual(try "abcdef".matches("bcd"), true)
        XCTAssertEqual(try "abcdef".matches("bcd", anyCase: true), true)
        XCTAssertEqual(try "abcdef".matches("bcd", anyCase: false), true)
        XCTAssertEqual(try "abcdef".matches("BcD"), false)
        XCTAssertEqual(try "abcdef".matches("BcD", anyCase: true), true)
        XCTAssertEqual(try "abcdef".matches("BcD", anyCase: false), false)

        XCTAssertEqual(try "abcdef".matches("duy"), false)
        XCTAssertEqual(try "abcdef".matches("duy", anyOf: true), true)
        XCTAssertEqual(try "abcdef".matches("duy", anyOf: false), false)
        XCTAssertEqual(try "abcdef".matches("DUY"), false)
        XCTAssertEqual(try "abcdef".matches("DUY", anyOf: true), false)
        XCTAssertEqual(try "abcdef".matches("DUY", anyOf: false), false)
        XCTAssertEqual(try "abcdef".matches("DUY", anyCase: true, anyOf: true), true)
        XCTAssertEqual(try "abcdef".matches("DUY", anyCase: true, anyOf: false), false)
    }

    func testColumnMatches() throws {
        XCTAssertEqual(try "abcdefghij".matches("b", inRanges: [ .column(start: 2, end: 2) ]), true)
        XCTAssertEqual(try "abcdefghij".matches("bc", inRanges: [ .column(start: 2, end: 2) ]), false)
        XCTAssertEqual(try "abcdefghij".matches("b", inRanges: [ .column(start: 2, end: 4) ]), true)
        XCTAssertEqual(try "abcdefghij".matches("bc", inRanges: [ .column(start: 2, end: 4) ]), true)
        XCTAssertEqual(try "abcdefghij".matches("bcd", inRanges: [ .column(start: 2, end: 4) ]), true)
        XCTAssertEqual(try "abcdefghij".matches("bcde", inRanges: [ .column(start: 2, end: 4) ]), false)
        XCTAssertEqual(try "abcdefghij".matches("bcd", inRanges: [ .column(start: 1, end: 10) ]), true)
        XCTAssertEqual(try "abcdefghij".matches("bcd", inRanges: [ .column(start: 2, end: 4) ]), true)
        XCTAssertEqual(try "abcdefghij".matches("bcd", inRanges: [ .column(start: 2, end: 5) ]), true)
        XCTAssertEqual(try "abcdefghij".matches("bcd", inRanges: [ .column(start: 3, end: 5) ]), false)
        XCTAssertEqual(try "abcdefghij".matches("BCD", inRanges: [ .column(start: 2, end: 4) ]), false)
        XCTAssertEqual(try "abcdefghij".matches("BCD", inRanges: [ .column(start: 2, end: 4) ], anyCase: true), true)
    }

    func testWordMatches() throws {
        XCTAssertEqual(try "aa bb cc dd ee ff".matches("cc", inRanges: [ .word(start: 3, end: 3) ]), true)
        XCTAssertEqual(try "aa bb cc dd ee ff".matches("cc", inRanges: [ .word(start: 1, end: 3) ]), true)
        XCTAssertEqual(try "aa bb cc dd ee ff".matches("cc", inRanges: [ .word(start: 4, end: .end) ]), false)
        XCTAssertEqual(try "aa bb cc dd ee ff".matches("cc", inRanges: [ .word(start: .end, end: .end) ]), true)
    }

    func testFieldMatches() throws {
        XCTAssertEqual(try "aa\tbb\tcc\tdd\tee\tff".matches("cc", inRanges: [ .field(start: 3, end: 3) ]), true)
        XCTAssertEqual(try "aa\tbb\tcc\tdd\tee\tff".matches("cc", inRanges: [ .field(start: 1, end: 3) ]), true)
        XCTAssertEqual(try "aa\tbb\tcc\tdd\tee\tff".matches("cc", inRanges: [ .field(start: 4, end: .end) ]), false)
        XCTAssertEqual(try "aa\tbb\tcc\tdd\tee\tff".matches("cc", inRanges: [ .field(start: .end, end: .end) ]), true)
    }

    func testSingleRangeParsing() throws {
        XCTAssertEqual(try Args("dummy 5").scanRange(), PipeRange.column(start: 5, end: 5))
        XCTAssertEqual(try Args("dummy 1.3").scanRange(), PipeRange.column(start: 1, end: 3))
        XCTAssertEqual(try Args("dummy 1-3").scanRange(), PipeRange.column(start: 1, end: 3))
        XCTAssertEqual(try Args("dummy 1;3").scanRange(), PipeRange.column(start: 1, end: 3))
        XCTAssertEqual(try Args("dummy 2.3").scanRange(), PipeRange.column(start: 2, end: 4))
        XCTAssertEqual(try Args("dummy 2-3").scanRange(), PipeRange.column(start: 2, end: 3))
        XCTAssertEqual(try Args("dummy 2.*").scanRange(), PipeRange.column(start: 2, end: .end))
        XCTAssertEqual(try Args("dummy 2-*").scanRange(), PipeRange.column(start: 2, end: .end))
        XCTAssertEqual(try Args("dummy *-*").scanRange(), PipeRange.column(start: .end, end: .end))
        XCTAssertEqual(try Args("dummy 5;-4").scanRange(), PipeRange.column(start: 5, end: -4))
        XCTAssertEqual(try Args("dummy -5;-4").scanRange(), PipeRange.column(start: -5, end: -4))

        XCTAssertEqual(try Args("dummy w5").scanRange(), PipeRange.word(start: 5, end: 5))
        XCTAssertEqual(try Args("dummy w1.3").scanRange(), PipeRange.word(start: 1, end: 3))
        XCTAssertEqual(try Args("dummy w1-3").scanRange(), PipeRange.word(start: 1, end: 3))
        XCTAssertEqual(try Args("dummy w1;3").scanRange(), PipeRange.word(start: 1, end: 3))
        XCTAssertEqual(try Args("dummy w2.3").scanRange(), PipeRange.word(start: 2, end: 4))
        XCTAssertEqual(try Args("dummy w2-3").scanRange(), PipeRange.word(start: 2, end: 3))
        XCTAssertEqual(try Args("dummy w2.*").scanRange(), PipeRange.word(start: 2, end: .end))
        XCTAssertEqual(try Args("dummy w2-*").scanRange(), PipeRange.word(start: 2, end: .end))
        XCTAssertEqual(try Args("dummy w*-*").scanRange(), PipeRange.word(start: .end, end: .end))
        XCTAssertEqual(try Args("dummy w5;-4").scanRange(), PipeRange.word(start: 5, end: -4))
        XCTAssertEqual(try Args("dummy w-5;-4").scanRange(), PipeRange.word(start: -5, end: -4))

        XCTAssertEqual(try Args("dummy f5").scanRange(), PipeRange.field(start: 5, end: 5))
        XCTAssertEqual(try Args("dummy f1.3").scanRange(), PipeRange.field(start: 1, end: 3))
        XCTAssertEqual(try Args("dummy f1-3").scanRange(), PipeRange.field(start: 1, end: 3))
        XCTAssertEqual(try Args("dummy f1;3").scanRange(), PipeRange.field(start: 1, end: 3))
        XCTAssertEqual(try Args("dummy f2.3").scanRange(), PipeRange.field(start: 2, end: 4))
        XCTAssertEqual(try Args("dummy f2-3").scanRange(), PipeRange.field(start: 2, end: 3))
        XCTAssertEqual(try Args("dummy f2.*").scanRange(), PipeRange.field(start: 2, end: .end))
        XCTAssertEqual(try Args("dummy f2-*").scanRange(), PipeRange.field(start: 2, end: .end))
        XCTAssertEqual(try Args("dummy f*-*").scanRange(), PipeRange.field(start: .end, end: .end))
        XCTAssertEqual(try Args("dummy f5;-4").scanRange(), PipeRange.field(start: 5, end: -4))
        XCTAssertEqual(try Args("dummy f-5;-4").scanRange(), PipeRange.field(start: -5, end: -4))

        XCTAssertEqual(try Args("dummy words 2-4").scanRange(), PipeRange.word(start: 2, end: 4))
        XCTAssertEqual(try Args("dummy w 2-4").scanRange(), PipeRange.word(start: 2, end: 4))
        XCTAssertEqual(try Args("dummy fields 2-4").scanRange(), PipeRange.field(start: 2, end: 4))
        XCTAssertEqual(try Args("dummy f 2-4").scanRange(), PipeRange.field(start: 2, end: 4))

        XCTAssertEqual(try Args("dummy WS a W 1-1").scanRange(), PipeRange.word(start: 1, end: 1, separator: "a"))
        XCTAssertEqual(try Args("dummy FS b F 1-1").scanRange(), PipeRange.field(start: 1, end: 1, separator: "b"))
        XCTAssertEqual(try Args("dummy WS a 1-1").scanRange(), PipeRange.column(start: 1, end: 1))
        XCTAssertEqual(try Args("dummy FS b 1-1").scanRange(), PipeRange.column(start: 1, end: 1))
        XCTAssertEqual(try Args("dummy WS a FS b 1-1").scanRange(), PipeRange.column(start: 1, end: 1))

        XCTAssertThrows(try Args("dummy ").scanRange(), PipeError.invalidRange(range: ""))
        XCTAssertThrows(try Args("dummy -5--4").scanRange(), PipeError.invalidRange(range: "-5--4"))
        XCTAssertThrows(try Args("dummy xxx").scanRange(), PipeError.invalidRange(range: "xxx"))
        XCTAssertThrows(try Args("dummy words").scanRange(), PipeError.requiredOperandMissing)
    }

    func testMultiRangeParsing() throws {
        XCTAssertEqual(try Args("dummy (1.3)").scanRanges(), [ PipeRange.column(start: 1, end: 3) ])
        XCTAssertEqual(try Args("dummy (1.3 2.4)").scanRanges(), [ PipeRange.column(start: 1, end: 3), PipeRange.column(start: 2, end: 5) ])

        XCTAssertThrows(try Args("dummy ()").scanRanges(), PipeError.noInputRanges)
        XCTAssertThrows(try Args("dummy (xxx)").scanRanges(), PipeError.invalidRange(range: "xxx"))
        XCTAssertThrows(try Args("dummy (").scanRanges(), PipeError.missingEndingParenthesis)
        XCTAssertThrows(try Args("dummy (1.3").scanRanges(), PipeError.missingEndingParenthesis)
        XCTAssertThrows(try Args("dummy (xxx").scanRanges(), PipeError.missingEndingParenthesis)

//        let ranges = try Args("dummy (1.1 3-5 9.4 -2;-1)").scanRanges()
//        XCTAssertEqual("".extract(fromRanges: ranges), "acdeijklyz")
    }

    func testSubstrRangeParsing() throws {
        //        assertEquals("SUBSTR 2-5 OF 1-10", scanRange(new PipeArgs("SUBSTR 2-5 OF 1-10"), true).toString())
        //        assertEquals("SUBSTR 2-5 OF SUBSTR 3-4 OF 1-10", scanRange(new PipeArgs("SUBSTR 2-5 OF SUBSTR 3.2 OF 1-10 "), true).toString())
        //        args = new PipeArgs("SUBSTR 2-5 OF 1-10")
        //        assertEquals("SUBSTR 2-5 OF 1-10", scanRange(args, false).toString())
        //        args = new PipeArgs("SUBSTR 2-5 OF SUBSTR 3.2 OF 1-10 ")
        //        assertEquals("SUBSTR 2-5 OF SUBSTR 3-4 OF 1-10", scanRange(args, false).toString())
        //        args = new PipeArgs("1-5 hello there")
        //        assertEquals("1-5", scanRange(args, false).toString())
        //        assertEquals("hello there", args.getRemainder())
        //        args = new PipeArgs("1-5 hello there")
        //        assertEquals("1-5", scanRange(args, true).toString())
        //        assertEquals("hello there", args.getRemainder())
        //        args = new PipeArgs("words 1-2 words 3-4")
        //        assertEquals("W 1-2", scanRange(args, true).toString())
        //        assertEquals("words 3-4", args.getRemainder())
        //        args = new PipeArgs("SUBSTR 2-5 OF SUBSTR 3.2 OF 1-10 words 3-4")
        //        assertEquals("SUBSTR 2-5 OF SUBSTR 3-4 OF 1-10", scanRange(args, true).toString())
        //        assertEquals("words 3-4", args.getRemainder())
        //        args = new PipeArgs("SUBSTR 2-5 OF SUBSTR 3.2 OF 1-10 SUBSTR 2-5 OF SUBSTR 3.2 OF 1-10")
        //        assertEquals("SUBSTR 2-5 OF SUBSTR 3-4 OF 1-10", scanRange(args, true).toString())
        //        assertEquals("SUBSTR 2-5 OF SUBSTR 3.2 OF 1-10", args.getRemainder())
        //
    }
}
