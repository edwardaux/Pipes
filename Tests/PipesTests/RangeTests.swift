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
        // String s = "abcdefghijklmnopqrstuvwxyz";
        // assertEquals("abcdefghijklm", scanRange(new PipeArgs("1-13 "), true).extractRange(s));
        // assertEquals("cdefghij", scanRange(new PipeArgs("SUBSTR 3.8 OF 1-13 "), true).extractRange(s));
        // assertEquals("defg", scanRange(new PipeArgs("SUBSTR 2-5 OF SUBSTR 3.8 OF 1-13 "), true).extractRange(s));
    }

    func testRangeExtractWords() throws {
        let s = "  hello there   how   are   you today? I am well thanks  ";
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

        let t = "xxhelloxtherexxxhowxxxarexxxyouxtoday?xIxamxwellxthanksxx";
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
        /*
        s = ",b,,d,eeee,fff,ggg,";
        assertEquals("", scanRange(new PipeArgs("fieldsep , fields 1"), true).extractRange(s));
        assertEquals("b", scanRange(new PipeArgs("fieldsep , fields 2"), true).extractRange(s));
        assertEquals("d,eeee,fff", scanRange(new PipeArgs("fieldsep , fields 4-6"), true).extractRange(s));
        assertEquals(",b,,d,eeee,fff,ggg", scanRange(new PipeArgs("fieldsep , fields 1-7"), true).extractRange(s));
        assertEquals(",b,,d,eeee,fff,ggg,", scanRange(new PipeArgs("fieldsep , fields 1-*"), true).extractRange(s));
        assertEquals(",b,,d,eeee,fff,ggg,", scanRange(new PipeArgs("fieldsep , fields 1-8"), true).extractRange(s));
        assertEquals("", scanRange(new PipeArgs("fieldsep , fields -1"), true).extractRange(s));
        assertEquals("ggg,", scanRange(new PipeArgs("fieldsep , fields -2;-1"), true).extractRange(s));
        assertEquals("ggg,", scanRange(new PipeArgs("fieldsep , fields 7-8"), true).extractRange(s));
        assertEquals("ggg,", scanRange(new PipeArgs("fieldsep , fields 7;-1"), true).extractRange(s));
        */

    }
    func testSimpleMatches() throws {
        XCTAssertEqual(try "".matches(), true)
        XCTAssertEqual(try "xxx".matches(), true)
        XCTAssertEqual(try "".matches(""), true)
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
        XCTAssertEqual(try "abcdefghij".matches("b", inRange: .column(start: 2, end: 2)), true)
        XCTAssertEqual(try "abcdefghij".matches("bc", inRange: .column(start: 2, end: 2)), false)
        XCTAssertEqual(try "abcdefghij".matches("b", inRange: .column(start: 2, end: 4)), true)
        XCTAssertEqual(try "abcdefghij".matches("bc", inRange: .column(start: 2, end: 4)), true)
        XCTAssertEqual(try "abcdefghij".matches("bcd", inRange: .column(start: 2, end: 4)), true)
        XCTAssertEqual(try "abcdefghij".matches("bcde", inRange: .column(start: 2, end: 4)), false)
        XCTAssertEqual(try "abcdefghij".matches("bcd", inRange: .column(start: 1, end: 10)), true)
        XCTAssertEqual(try "abcdefghij".matches("bcd", inRange: .column(start: 2, end: 4)), true)
        XCTAssertEqual(try "abcdefghij".matches("bcd", inRange: .column(start: 2, end: 5)), true)
        XCTAssertEqual(try "abcdefghij".matches("bcd", inRange: .column(start: 3, end: 5)), false)
        XCTAssertEqual(try "abcdefghij".matches("BCD", inRange: .column(start: 2, end: 4)), false)
        XCTAssertEqual(try "abcdefghij".matches("BCD", inRange: .column(start: 2, end: 4), anyCase: true), true)
    }

    func testWordMatches() throws {

    }

    func testFieldMatches() throws {

    }
}
