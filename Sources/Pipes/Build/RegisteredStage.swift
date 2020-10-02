import Foundation

public protocol RegisteredStage {
    static var allowedStageNames: [String] { get }
    static func createStage(args: Args) -> Stage

    static var helpSummary: String? { get }
    static var helpSyntax: String? { get }
}
