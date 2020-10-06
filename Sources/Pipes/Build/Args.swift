import Foundation

public class Args {
    private let tokenizer: StringTokenizer
    let stageName: String

    init(_ stageSpec: String) throws {
        tokenizer = StringTokenizer(stageSpec)
        guard let stageName = tokenizer.scanWord() else {
            throw PipeError.nullStageFound
        }
        self.stageName = stageName
    }

    public func peekWord() throws -> String {
        return tokenizer.peekWord() ?? ""
    }

    public func scanWord() throws -> String {
        return tokenizer.scanWord() ?? ""
    }

    public func scanRemaining() throws -> String {
        return tokenizer.remainder
    }
}
