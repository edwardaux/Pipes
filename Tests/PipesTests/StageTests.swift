import XCTest
@testable import Pipes

final class StageTests: XCTestCase {
    override class func setUp() {
        Pipe.register(ZZZTestGeneratorStage.self)
        Pipe.register(ZZZTestCheckerStage.self)
    }

    func testZZZ() throws {
        try Pipe("zzzgen // | zzzcheck //").run()
        try Pipe("zzzgen /a/b/c/ | zzzcheck /a/b/c/").run()
    }
}
