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

//        // delim string
//        args = new PipeArgs("");
//        XCTAssertEqual("", args.nextDelimString(false));
//        XCTAssertEqual("", args.nextDelimString(false));
//        XCTAssertEqual("", args.remainder);
//
//        args = new PipeArgs("/hello/");
//        XCTAssertEqual("hello", args.nextDelimString(false));
//        XCTAssertEqual("", args.nextDelimString(false));
//        XCTAssertEqual("", args.remainder);
//
//        args = new PipeArgs("  /hello/");
//        XCTAssertEqual("hello", args.nextDelimString(false));
//        XCTAssertEqual("", args.nextDelimString(false));
//        XCTAssertEqual("", args.remainder);
//
//        args = new PipeArgs("  /hello/ ");
//        XCTAssertEqual("hello", args.nextDelimString(false));
//        XCTAssertEqual("", args.nextDelimString(false));
//        XCTAssertEqual(" ", args.remainder);
//
//        args = new PipeArgs("  ,hello,  ");
//        XCTAssertEqual("hello", args.nextDelimString(false));
//        XCTAssertEqual("", args.nextDelimString(false));
//        XCTAssertEqual("  ", args.remainder);
//
//        args = new PipeArgs("  ,hello, /there,/ /how/ /are/ /you/  ");
//        XCTAssertEqual("hello", args.nextDelimString(false));
//        XCTAssertEqual("there,", args.nextDelimString(false));
//        XCTAssertEqual("how", args.nextDelimString(false));
//        XCTAssertEqual(" /are/ /you/  ", args.remainder);
//
//        args = new PipeArgs("/hello");
//        try {
//            args.nextDelimString(true);
//        }
//        catch(PipeException e) {
//            XCTAssertEqual(-60, e.getMessageNo());
//        }
//
//        args = new PipeArgs("b00111000");
//        XCTAssertEqual("8", args.nextDelimString(false));
//
//        args = new PipeArgs("b11000010");
//        XCTAssertEqual("\u00C2", args.nextDelimString(false));
//
//        args = new PipeArgs("  b00111000  ");
//        XCTAssertEqual("8", args.nextDelimString(false));
//        XCTAssertEqual("  ", args.remainder);
//
//        args = new PipeArgs("  b00111000 b00111000 /a/  ");
//        XCTAssertEqual("8", args.nextDelimString(false));
//        XCTAssertEqual("8", args.nextDelimString(false));
//        XCTAssertEqual("a", args.nextDelimString(false));
//        XCTAssertEqual("  ", args.remainder);
//
//        args = new PipeArgs("b001110000011100100111010");
//        XCTAssertEqual("89:", args.nextDelimString(false));
//
//        args = new PipeArgs("b");
//        try {
//            args.nextDelimString(false);
//        }
//        catch(PipeException e) {
//            XCTAssertEqual(-337, e.getMessageNo());
//        }
//
//        args = new PipeArgs(" b ");
//        try {
//            args.nextDelimString(false);
//        }
//        catch(PipeException e) {
//            XCTAssertEqual(-337, e.getMessageNo());
//        }
//
//        args = new PipeArgs("b1111");
//        try {
//            args.nextDelimString(false);
//        }
//        catch(PipeException e) {
//            XCTAssertEqual(-336, e.getMessageNo());
//        }
//
//        args = new PipeArgs("bxxxxxxxx");
//        try {
//            args.nextDelimString(false);
//        }
//        catch(PipeException e) {
//            XCTAssertEqual(-338, e.getMessageNo());
//        }
//
//        args = new PipeArgs("x20");
//        XCTAssertEqual(" ", args.nextDelimString(false));
//
//        args = new PipeArgs("x4D");
//        XCTAssertEqual("M", args.nextDelimString(false));
//
//        args = new PipeArgs("x4D204D204D");
//        XCTAssertEqual("M M M", args.nextDelimString(false));
//
//        args = new PipeArgs("x");
//        try {
//            args.nextDelimString(false);
//        }
//        catch(PipeException e) {
//            XCTAssertEqual(-64, e.getMessageNo());
//        }
//
//        args = new PipeArgs(" x ");
//        try {
//            args.nextDelimString(false);
//        }
//        catch(PipeException e) {
//            XCTAssertEqual(-64, e.getMessageNo());
//        }
//
//        args = new PipeArgs("xA");
//        try {
//            args.nextDelimString(false);
//        }
//        catch(PipeException e) {
//            XCTAssertEqual(-335, e.getMessageNo());
//        }
//
//        args = new PipeArgs("xxxxxxxxx");
//        try {
//            args.nextDelimString(false);
//        }
//        catch(PipeException e) {
//            XCTAssertEqual(-65, e.getMessageNo());
//        }
//
//        args = new PipeArgs("hello there, /how/ are you  ");
//        XCTAssertEqual("hello", args.nextWord());
//        XCTAssertEqual("there,", args.nextWord());
//        XCTAssertEqual("/how/", args.nextWord());
//        args.undo();
//        XCTAssertEqual("/how/", args.nextWord());
//        args.undo();
//        XCTAssertEqual("how", args.nextDelimString(false));
//
//        args = new PipeArgs("hello there");
//        XCTAssertEqual("", args.nextExpression());
//        XCTAssertEqual("hello", args.nextWord());
//        XCTAssertEqual("there", args.nextWord());
//        args = new PipeArgs("hello (hi there) there");
//        XCTAssertEqual("", args.nextExpression());
//        XCTAssertEqual("hello", args.nextWord());
//        XCTAssertEqual("(hi", args.nextWord());
//        XCTAssertEqual("there)", args.nextWord());
//        XCTAssertEqual("there", args.nextWord());
//        args = new PipeArgs("(hi there) there");
//        XCTAssertEqual("hi there", args.nextExpression());
//        XCTAssertEqual("there", args.nextWord());
//        try {
//            args = new PipeArgs("(hi");
//            args.nextExpression();
//        }
//        catch(PipeException e) {
//            XCTAssertEqual(-200, e.getMessageNo());
//        }
}
