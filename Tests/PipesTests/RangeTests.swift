import XCTest
@testable import Pipes

final class RangeTests: XCTestCase {
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

    func testRangeExtract() throws {
        XCTAssertThrows(try "".extract(fromRange: PipeRange.column(start: 0, end: 1)), PipeError.invalidRange(range: "0;1"))
        XCTAssertThrows(try "".extract(fromRange: PipeRange.column(start: 2, end: 1)), PipeError.invalidRange(range: "2;1"))
        XCTAssertThrows(try "".extract(fromRange: PipeRange.column(start: -2, end: -3)), PipeError.invalidRange(range: "-2;-3"))

        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 2, end: 2)), "b")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 2, end: 4)), "bcd")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 1, end: 10)), "abcdefghij")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 1, end: 100)), "abcdefghij")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 99, end: 100)), "")
        XCTAssertEqual(try "abcdefghij".extract(fromRange: PipeRange.column(start: 3, end: -3)), "cdefgh")

        XCTAssertEqual(try "abcde".extract(fromRange: PipeRange.column(start: 2, end: -2)), "bcd")
        XCTAssertThrows(try "abcde".extract(fromRange: PipeRange.column(start: 2, end: -5)), PipeError.invalidRange(range: "2;-5"))
        XCTAssertEqual(try "abcdefgh".extract(fromRange: PipeRange.column(start: 2, end: -5)), "bcd")
    }

    func testColumnRanges() throws {
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

    func testWordRanges() throws {

    }

    func testFieldRanges() throws {

    }
}
