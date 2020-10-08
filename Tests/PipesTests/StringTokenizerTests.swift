import XCTest
@testable import Pipes

func XCTAssertThrows<T>(_ expression: @autoclosure () throws -> T, _ expectedError: PipeError) {
    XCTAssertThrowsError(try expression()) { (error) in
        XCTAssertEqual(error as? PipeError, expectedError)
    }
}

final class StringTokenizerTests: XCTestCase {
    func testTokenizing() throws {
        var st: StringTokenizer

        st = StringTokenizer("")
        XCTAssertEqual(nil, st.peekWord())
        XCTAssertEqual(nil, st.scanWord())
        XCTAssertEqual(nil, st.peekChar())
        XCTAssertEqual(nil, st.scanChar())
        XCTAssertEqual(nil, st.scan(between: "(", and: ")"))
        XCTAssertEqual("", st.remainder)

        st = StringTokenizer("hello")
        XCTAssertEqual("hello", st.peekWord())
        XCTAssertEqual("hello", st.scanWord())
        XCTAssertEqual(nil, st.scanWord())
        XCTAssertEqual("", st.remainder)

        st = StringTokenizer("  hello")
        XCTAssertEqual("hello", st.scanWord())
        XCTAssertEqual(nil, st.scanWord())
        XCTAssertEqual("", st.remainder)

        st = StringTokenizer("  hello ")
        XCTAssertEqual("hello", st.scanWord())
        XCTAssertEqual(nil, st.scanWord())
        XCTAssertEqual("", st.remainder)

        st = StringTokenizer("  hello there, how are you  ")
        XCTAssertEqual("hello", st.scanWord())
        XCTAssertEqual("there,", st.scanWord())
        XCTAssertEqual("how", st.scanWord())
        XCTAssertEqual("are you  ", st.remainder)

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
        XCTAssertEqual("", st.remainder)

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
        XCTAssertEqual("", try args.scanRemaining())

        args = try Args("dummy /hello/")
        XCTAssertEqual("hello", try args.scanDelimitedString())
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.requiredOperandMissing)
        XCTAssertEqual("", try args.scanRemaining())

        args = try Args("dummy   /hello/")
        XCTAssertEqual("hello", try args.scanDelimitedString())
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.requiredOperandMissing)
        XCTAssertEqual("", try args.scanRemaining())

        args = try Args("dummy   /hello/ ")
        XCTAssertEqual("hello", try args.scanDelimitedString())
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.requiredOperandMissing)
        XCTAssertEqual("", try args.scanRemaining())

        args = try Args("dummy   ,hello,  ")
        XCTAssertEqual("hello", try args.scanDelimitedString())
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.requiredOperandMissing)
        XCTAssertEqual("", try args.scanRemaining())

        args = try Args("dummy   ,hello, /there,/ /how/ /are/ /you/  ")
        XCTAssertEqual("hello", try args.scanDelimitedString())
        XCTAssertEqual("there,", try args.scanDelimitedString())
        XCTAssertEqual("how", try args.scanDelimitedString())
        XCTAssertEqual("/are/ /you/  ", try args.scanRemaining())

        args = try Args("dummy /hello")
        XCTAssertThrows(try args.scanDelimitedString(), PipeError.delimiterMissing(delimiter: "/"))

        args = try Args("dummy b00111000")
        XCTAssertEqual("8", try args.scanDelimitedString())

        args = try Args("dummy b11000010")
        XCTAssertEqual("\u{00C2}", try args.scanDelimitedString())

        args = try Args("dummy   b00111000  ")
        XCTAssertEqual("8", try args.scanDelimitedString())
        XCTAssertEqual("", try args.scanRemaining())

        args = try Args("dummy   b00111000 b00111000 /a/  ")
        XCTAssertEqual("8", try args.scanDelimitedString())
        XCTAssertEqual("8", try args.scanDelimitedString())
        XCTAssertEqual("a", try args.scanDelimitedString())
        XCTAssertEqual("", try args.scanRemaining())

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
}