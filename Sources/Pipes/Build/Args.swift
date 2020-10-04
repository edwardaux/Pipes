import Foundation

public class Args {
    private let words: [String]

    init(_ stageSpec: String) {
        words = stageSpec.split(separator: " ").map { String($0) }
    }

    var stageName: String {
        return words[0]
    }

    public func peekWord() throws -> String {
        return words[1]
    }

    public func scanWord() throws -> String {
        return words[1]
    }

    public func scanRemaining() throws -> String {
        return words.dropFirst().joined(separator: " ")
    }
}
