import XCTest
@testable import Pipes

final class StringTokenizerTests: XCTestCase {
    func testTokenizing() throws {
        var st: StringTokenizer

        st = StringTokenizer("");
        XCTAssertEqual(nil, st.peekWord());
        XCTAssertEqual(nil, st.scanWord());
        XCTAssertEqual(nil, st.peekChar());
        XCTAssertEqual(nil, st.scanChar());
        XCTAssertEqual(nil, st.scan(between: "(", and: ")"));
        XCTAssertEqual("", st.remainder);

        st = StringTokenizer("hello");
        XCTAssertEqual("hello", st.peekWord());
        XCTAssertEqual("hello", st.scanWord());
        XCTAssertEqual(nil, st.scanWord());
        XCTAssertEqual("", st.remainder);

        st = StringTokenizer("  hello");
        XCTAssertEqual("hello", st.scanWord());
        XCTAssertEqual(nil, st.scanWord());
        XCTAssertEqual("", st.remainder);

        st = StringTokenizer("  hello ");
        XCTAssertEqual("hello", st.scanWord());
        XCTAssertEqual(nil, st.scanWord());
        XCTAssertEqual("", st.remainder);

        st = StringTokenizer("  hello there, how are you  ");
        XCTAssertEqual("hello", st.scanWord());
        XCTAssertEqual("there,", st.scanWord());
        XCTAssertEqual("how", st.scanWord());
        XCTAssertEqual("are you  ", st.remainder);

        st = StringTokenizer("  abc d (e f) g h   i  ")
        XCTAssertEqual("abc", st.peekWord());
        XCTAssertEqual("abc", st.scanWord());
        st.undo()
        XCTAssertEqual("abc", st.scanWord());
        XCTAssertEqual("d", st.scanWord());
        XCTAssertEqual("e f", st.scan(between: "(", and: ")"));
        XCTAssertEqual("g", st.scanWord());
        XCTAssertEqual("h", st.scanWord());
        XCTAssertEqual("i", st.scanWord());
        XCTAssertEqual("", st.remainder);

        st = StringTokenizer("  abc d (e f) g h   i  ")
        XCTAssertEqual("e f", st.scan(between: "(", and: ")"));

        st = StringTokenizer("  (abc")
        XCTAssertEqual(nil, st.scan(between: "(", and: ")"));

        st = StringTokenizer("  abc")
        XCTAssertEqual(nil, st.scan(between: "(", and: ")"));

        st = StringTokenizer("  abc def  ")
        XCTAssertEqual("a", st.peekChar());
        XCTAssertEqual("abc", st.peekWord());
        XCTAssertEqual("a", st.scanChar());
        XCTAssertEqual("bc", st.scanWord());
        XCTAssertEqual("d", st.scanChar());
        XCTAssertEqual("e", st.scanChar());
        XCTAssertEqual("f", st.scanChar());
        XCTAssertEqual(nil, st.scanChar());
    }

    func testDelimitedString() throws {
        var args: Args

        args = Args("");
        XCTAssertEqual("", try args.scanDelimitedString());
        XCTAssertEqual("", try args.scanDelimitedString());
        XCTAssertEqual("", try args.scanRemaining());

        args = Args("/hello/");
        XCTAssertEqual("hello", try args.scanDelimitedString());
        XCTAssertEqual("", try args.scanDelimitedString());
        XCTAssertEqual("", try args.scanRemaining());

        args = Args("  /hello/");
        XCTAssertEqual("hello", try args.scanDelimitedString());
        XCTAssertEqual("", try args.scanDelimitedString());
        XCTAssertEqual("", try args.scanRemaining());

        args = Args("  /hello/ ");
        XCTAssertEqual("hello", try args.scanDelimitedString());
        XCTAssertEqual("", try args.scanDelimitedString());
        XCTAssertEqual(" ", try args.scanRemaining());

        args = Args("  ,hello,  ");
        XCTAssertEqual("hello", try args.scanDelimitedString());
        XCTAssertEqual("", try args.scanDelimitedString());
        XCTAssertEqual("  ", try args.scanRemaining());

        args = Args("  ,hello, /there,/ /how/ /are/ /you/  ");
        XCTAssertEqual("hello", try args.scanDelimitedString());
        XCTAssertEqual("there,", try args.scanDelimitedString());
        XCTAssertEqual("how", try args.scanDelimitedString());
        XCTAssertEqual(" /are/ /you/  ", try args.scanRemaining());

        args = Args("/hello");
        do {
            _ = try args.scanDelimitedString()
        }
        catch let e as PipeError {
            XCTAssertEqual(-60, e.code);
        }

        args = Args("b00111000");
        XCTAssertEqual("8", try args.scanDelimitedString());

        args = Args("b11000010");
        XCTAssertEqual("\u{00C2}", try args.scanDelimitedString());

        args = Args("  b00111000  ");
        XCTAssertEqual("8", try args.scanDelimitedString());
        XCTAssertEqual("  ", try args.scanRemaining());

        args = Args("  b00111000 b00111000 /a/  ");
        XCTAssertEqual("8", try args.scanDelimitedString());
        XCTAssertEqual("8", try args.scanDelimitedString());
        XCTAssertEqual("a", try args.scanDelimitedString());
        XCTAssertEqual("  ", try args.scanRemaining());

        args = Args("b001110000011100100111010");
        XCTAssertEqual("89:", try args.scanDelimitedString());

        args = Args("b");
        do {
            try _ = args.scanDelimitedString();
        }
        catch let e as PipeError {
            XCTAssertEqual(-337, e.code);
        }

        args = Args(" b ");
        do {
            try _ = args.scanDelimitedString();
        }
        catch let e as PipeError {
            XCTAssertEqual(-337, e.code);
        }

        args = Args("b1111");
        do {
            try _ = args.scanDelimitedString();
        }
        catch let e as PipeError {
            XCTAssertEqual(-336, e.code);
        }

        args = Args("bxxxxxxxx");
        do {
            try _ = args.scanDelimitedString();
        }
        catch let e as PipeError {
            XCTAssertEqual(-338, e.code);
        }

        args = Args("x20");
        XCTAssertEqual(" ", try args.scanDelimitedString());

        args = Args("x4D");
        XCTAssertEqual("M", try args.scanDelimitedString());

        args = Args("x4D204D204D");
        XCTAssertEqual("M M M", try args.scanDelimitedString());

        args = Args("x");
        do {
            try _ = args.scanDelimitedString();
        }
        catch let e as PipeError {
            XCTAssertEqual(-64, e.code);
        }

        args = Args(" x ");
        do {
            try _ = args.scanDelimitedString();
        }
        catch let e as PipeError {
            XCTAssertEqual(-64, e.code);
        }

        args = Args("xA");
        do {
            try _ = args.scanDelimitedString();
        }
        catch let e as PipeError {
            XCTAssertEqual(-335, e.code);
        }

        args = Args("xxxxxxxxx");
        do {
            try _ = args.scanDelimitedString();
        }
        catch let e as PipeError {
            XCTAssertEqual(-65, e.code);
        }

    }
//        args = Args("hello there, /how/ are you  ");
//        XCTAssertEqual("hello", args.nextWord());
//        XCTAssertEqual("there,", args.nextWord());
//        XCTAssertEqual("/how/", args.nextWord());
//        args.undo();
//        XCTAssertEqual("/how/", args.nextWord());
//        args.undo();
//        XCTAssertEqual("how", try args.scanDelimitedString());
//
//        args = Args("hello there");
//        XCTAssertEqual("", args.nextExpression());
//        XCTAssertEqual("hello", args.nextWord());
//        XCTAssertEqual("there", args.nextWord());
//        args = Args("hello (hi there) there");
//        XCTAssertEqual("", args.nextExpression());
//        XCTAssertEqual("hello", args.nextWord());
//        XCTAssertEqual("(hi", args.nextWord());
//        XCTAssertEqual("there)", args.nextWord());
//        XCTAssertEqual("there", args.nextWord());
//        args = Args("(hi there) there");
//        XCTAssertEqual("hi there", args.nextExpression());
//        XCTAssertEqual("there", args.nextWord());
//        try {
//            args = Args("(hi");
//            args.nextExpression();
//        }
//        catch let e as PipeError {
//            XCTAssertEqual(-200, e.code);
//        }
}
