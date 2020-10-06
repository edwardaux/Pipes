import Foundation

public class Args {
    let tokenizer: StringTokenizer
    let stageName: String

    init(_ stageSpec: String) throws {
        tokenizer = StringTokenizer(stageSpec)
        guard let stageName = tokenizer.scanWord() else {
            throw PipeError.nullStageFound
        }
        self.stageName = stageName
    }

    public func peekWord() throws -> String? {
        return tokenizer.peekWord()
    }

    public func scanWord() throws -> String {
        guard let word = tokenizer.scanWord() else { throw PipeError.requiredOperandMissing }
        return word
    }

    func onMandatoryKeyword<T>(_ keywords: [String: () throws -> T]) throws -> T {
        guard let keyword = tokenizer.peekWord() else { throw PipeError.requiredKeywordsMissing(keywords: keywords.keys.sorted()) }
        guard let closure = keywords[keyword] else { throw PipeError.operandNotValid(keyword: keyword) }

        // We have a closure that can handle this keyword, so we can safely consume the keyword
        _ = tokenizer.scanWord()

        return try closure()
    }

    func onOptionalKeyword<T>(_ keywords: [String: () throws -> T], defaultValue: T) throws -> T {
        guard let keyword = tokenizer.peekWord() else { return defaultValue }
        guard let closure = keywords[keyword] else { return defaultValue }

        // We have a closure that can handle this keyword, so we can safely consume the keyword
        _ = tokenizer.scanWord()

        return try closure()
    }

    public func scanRemaining() throws -> String {
        return tokenizer.remainder
    }
}
