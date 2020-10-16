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

    public func scanDelimitedString() throws -> String {
        tokenizer.mark()

        guard let firstChar = tokenizer.peekChar() else {
            tokenizer.resetMark()
            throw PipeError.requiredOperandMissing
        }

        switch firstChar {
        case "b", "B":
            _ = tokenizer.scanChar()
            guard let binary = tokenizer.scanWord() else {
                tokenizer.resetMark()
                throw PipeError.binaryDataMissing(prefix: firstChar)
            }
            guard binary.count % 8 == 0 else {
                tokenizer.resetMark()
                throw PipeError.binaryStringNotDivisibleBy8(string: binary)
            }
            guard binary.isBinaryString else {
                tokenizer.resetMark()
                throw PipeError.binaryStringNotBinary(string: binary)
            }

            var index = binary.startIndex
            var string: String = ""
            for _ in 0..<binary.count/8 {
                let nextIndex = binary.index(index, offsetBy: 8)
                let charBits = binary[index..<nextIndex]
                string += String(UnicodeScalar(UInt8(charBits, radix: 2)!))
                index = nextIndex
            }
            return string
        case "h", "H", "x", "X":
            _ = tokenizer.scanChar()
            guard let hex = tokenizer.scanWord() else {
                tokenizer.resetMark()
                throw PipeError.hexDataMissing(prefix: firstChar)
            }
            guard hex.count % 2 == 0 else {
                tokenizer.resetMark()
                throw PipeError.hexStringNotDivisibleBy2(string: hex)
            }
            guard hex.isHexString else {
                tokenizer.resetMark()
                throw PipeError.hexStringNotHex(string: hex)
            }

            var index = hex.startIndex
            var string: String = ""
            for _ in 0..<hex.count/2 {
                let nextIndex = hex.index(index, offsetBy: 2)
                let charBits = hex[index..<nextIndex]
                string += String(UnicodeScalar(UInt8(charBits, radix: 16)!))
                index = nextIndex
            }
            return string
        default:
            guard let string = tokenizer.scan(between: firstChar.first!, and: firstChar.first!) else {
                tokenizer.resetMark()
                throw PipeError.delimiterMissing(delimiter: firstChar)
            }
            return string
        }
    }

    public func scanExpression() throws -> String {
        guard tokenizer.peekChar() == "(" else { throw PipeError.requiredOperandMissing }
        guard let expression = tokenizer.scan(between: "(", and: ")") else { throw PipeError.missingEndingParenthesis }

        return expression
    }

    public func scanRemainder(trimLeading: Bool = true, trimTrailing: Bool = true) -> String {
        return tokenizer.scanRemainder(trimLeading: trimLeading, trimTrailing: trimTrailing)
    }

    public func ensureNoRemainder() throws {
        let remainder = scanRemainder()
        if remainder != "" {
            throw PipeError.excessiveOptions(string: remainder)
        }
    }

    public func undo() {
        tokenizer.undo()
    }
    
    public func onMandatoryKeyword<T>(_ keywords: [String: () throws -> T]) throws -> T {
        guard let keyword = tokenizer.peekWord() else {
            throw PipeError.requiredKeywordsMissing(keywords: keywords.keys.sorted())
        }

        // TODO mixed case input. also, deal with keys of different lengths. eg. STR vs STRing
        guard let closure = keywords[keyword.uppercased()] else {
            throw PipeError.operandNotValid(keyword: keyword)
        }

        // We have a closure that can handle this keyword, so we can safely consume the keyword
        _ = tokenizer.scanWord()

        return try closure()
    }

    public func onOptionalKeyword<T>(_ keywords: [String: () throws -> T], throwsOnUnsupportedKeyword: Bool) throws -> T? {
        guard let keyword = tokenizer.peekWord() else {
            return nil
        }

        guard let closure = keywords[keyword.uppercased()] else {
            if throwsOnUnsupportedKeyword {
                throw PipeError.operandNotValid(keyword: keyword)
            } else {
                return nil
            }
        }

        // We have a closure that can handle this keyword, so we can safely consume the keyword
        _ = tokenizer.scanWord()

        return try closure()
    }
}

extension String {
    var isBinaryString: Bool {
        let binaryChars = CharacterSet(charactersIn: "10")
        return self.rangeOfCharacter(from: binaryChars) != nil
    }
    var isHexString: Bool {
        let binaryChars = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return self.rangeOfCharacter(from: binaryChars) != nil
    }
}
