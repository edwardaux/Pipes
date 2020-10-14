import Pipes
import XCTest

func XCTAssertThrows<T>(_ expression: @autoclosure () throws -> T, _ expectedError: PipeError) {
    XCTAssertThrowsError(try expression()) { (error) in
        XCTAssertEqual(error as? PipeError, expectedError)
    }
}

func withTempFileContaining(_ contents: String, block: (String) throws -> Void) throws {
    let tmpFile = NSTemporaryDirectory() + "/" + UUID().uuidString

    defer { try? FileManager.default.removeItem(atPath: tmpFile) }
    FileManager.default.createFile(atPath: tmpFile, contents: contents.data(using: .utf8), attributes: nil)

    try block(tmpFile)
}
func withFileContentsFor(_ pipeSpec: String, filename: String, remove: Bool = true, block: (String) throws -> Void) throws {
    defer {
        if remove {
            try? FileManager.default.removeItem(atPath: filename)
        }
    }

    try Pipe(pipeSpec).run()
    let contents = String(data: FileManager.default.contents(atPath: filename)!, encoding: .utf8)!
    try block(contents)
}
