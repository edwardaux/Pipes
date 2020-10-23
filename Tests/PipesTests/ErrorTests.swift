import XCTest
@testable import Pipes

final class ErrorTests: XCTestCase {
    func testNoError() throws {
        try Pipe()
            .add(RunnableStage { })
            .add(RunnableStage { })
            .run()
    }

    func testWorstErrorNumber() throws {
        do {
            try Pipe()
                .add(RunnableStage { throw EndOfFile() })
                .add(RunnableStage { throw PipeError.labelNotDeclared(label: "") })
                .add(RunnableStage { throw PipeError.labelAlreadyDeclared(label: "") })
                .add(RunnableStage { throw PipeError.labelNotDeclared(label: "") })
                .run()
        } catch let error as PipeError {
            XCTAssertEqual(error, PipeError.labelAlreadyDeclared(label: ""))
        }
    }

    func testIgnoringEOF() throws {
        try Pipe()
            .add(RunnableStage { })
            .add(RunnableStage { throw EndOfFile() })
            .add(RunnableStage { })
            .run()
    }
}
