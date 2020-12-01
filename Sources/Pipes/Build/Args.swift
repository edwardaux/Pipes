import Foundation

public class Args {
    enum ArgsType {
        case label(String)
        case stage(stageName: String, label: String?)
    }
    let tokenizer: StringTokenizer
    let type: ArgsType

    init(_ stageSpec: String) throws {
        tokenizer = StringTokenizer(stageSpec)
        guard let word = tokenizer.scanWord() else {
            throw PipeError.nullStageFound
        }
        if word.trimmingCharacters(in: .whitespaces).hasSuffix(":") {
            if let stageName = tokenizer.scanWord() {
                type = .stage(stageName: stageName, label: word)
            } else {
                type = .label(word)
            }
        } else {
            type = .stage(stageName: word, label: nil)
        }
    }

    public func peekWord() -> String? {
        return tokenizer.peekWord()
    }

    public func scanWord() throws -> String {
        guard let word = tokenizer.scanWord() else { throw PipeError.requiredOperandMissing }
        return word
    }

    // TODO apply this to other stages
    public func nextKeywordMatches(_ keyword: String) -> Bool {
        return peekWord()?.matchesKeyword(keyword) == true
    }

    public func peekDelimitedString() -> String? {
        tokenizer.mark()
        defer { tokenizer.resetMark() }

        return try? scanDelimitedString()
    }

    public func scanDelimitedString() throws -> String {
        guard let firstChar = tokenizer.peekChar() else {
            throw PipeError.requiredOperandMissing
        }

        switch firstChar {
        case "b", "B":
            _ = tokenizer.scanChar()
            guard let binary = tokenizer.scanWord() else {
                throw PipeError.binaryDataMissing(prefix: firstChar)
            }
            guard binary.count % 8 == 0 else {
                throw PipeError.binaryStringNotDivisibleBy8(string: binary)
            }
            guard binary.isBinaryString else {
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
                throw PipeError.hexDataMissing(prefix: firstChar)
            }
            guard hex.count % 2 == 0 else {
                throw PipeError.hexStringNotDivisibleBy2(string: hex)
            }
            guard hex.isHexString else {
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
                throw PipeError.delimiterMissing(delimiter: firstChar)
            }
            return string
        }
    }

    public func peekRange() -> PipeRange? {
        tokenizer.mark()
        defer { tokenizer.resetMark() }

        return try? scanRange()
    }
    
    public func scanRange() throws -> PipeRange {
        enum ParsedRangeType { case full, column, word, field }

        var start: Int = .end
        var end: Int = .end
        var fieldSep: Character?
        var wordSep: Character?
        var type: ParsedRangeType = .column

        guard var word = try? scanWord() else {
            throw PipeError.invalidRange(range: "")
        }

        while word.matchesKeyword("FIELDSEParator", "FS", "WORDSEParator", "WS") {
            if word.matchesKeyword("FIELDSEParator", "FS") {
                fieldSep = try scanWord().asXorC()
                word = try scanWord()
            }
            if word.matchesKeyword("WORDSEParator", "WS") {
                wordSep = try scanWord().asXorC()
                word = try scanWord()
            }
        }

        if word.matchesKeyword("Words") {
            type = .word
            word = try scanWord()
        } else if word.matchesKeyword("Fields") {
            type = .field
            word = try scanWord()
        }

        // TODO syntax check for range
        if word.uppercased().starts(with: "W") && word.count >= 2 {
            type = .word
            word = String(word.dropFirst())
        } else if word.uppercased().starts(with: "F") && word.count >= 2 {
            type = .field
            word = String(word.dropFirst())
        }

        if word.contains(";") {
            let components = word.split(separator: ";", escape: nil)
            guard components.count == 2 else {
                throw PipeError.invalidRange(range: word)
            }
            start = try components[0].asNumberOrAsterisk(allowNegative: true)
            end = try components[1].asNumberOrAsterisk(allowNegative: true)
        } else if word.contains("-") {
            let components = word.split(separator: "-", escape: nil)
            guard components.count == 2 else {
                throw PipeError.invalidRange(range: word)
            }
            start = try components[0].asNumberOrAsterisk(allowNegative: true)
            end = try components[1].asNumberOrAsterisk(allowNegative: true)
        } else if word.contains(".") {
            let components = word.split(separator: ".", escape: nil)
            guard components.count == 2 else {
                throw PipeError.invalidRange(range: word)
            }
            start = try components[0].asNumberOrAsterisk(allowNegative: true)
            end = try components[1].asNumberOrAsterisk(allowNegative: true)
            if end != Int.end {
                end = start + end - 1
            }
        } else {
            do {
                start = try word.asNumberOrAsterisk(allowNegative: true)
                end = start
            } catch {
                throw PipeError.invalidRange(range: word)
            }
        }

        switch type {
        case .full:
            return .full
        case .column:
            return .column(start: start, end: end)
        case .word:
            return .word(start: start, end: end, separator: wordSep ?? " ")
        case .field:
            return .field(start: start, end: end, separator: fieldSep ?? "\t")
        }
    }

    public func peekRanges() -> [PipeRange]? {
        tokenizer.mark()
        defer { tokenizer.resetMark() }

        return try? scanRanges()
    }

    public func scanRanges() throws -> [PipeRange] {
        guard let char = tokenizer.peekChar() else {
            throw PipeError.invalidRange(range: "")
        }

        if char == "(" {
            guard let rangesText = tokenizer.scan(between: "(", and: ")") else { throw PipeError.missingEndingParenthesis }
            guard rangesText.trimmingCharacters(in: .whitespaces).count > 0 else { throw PipeError.noInputRanges }

            let tmpArgs = try Args("dummy \(rangesText)")
            var ranges = [PipeRange]()
            while tmpArgs.peekWord() != nil {
                ranges.append(try tmpArgs.scanRange())
            }
            return ranges
        } else {
            return try [scanRange()]
        }
    }

    public func scanExpression() throws -> String {
        guard tokenizer.peekChar() == "(" else { throw PipeError.requiredOperandMissing }
        guard let expression = tokenizer.scan(between: "(", and: ")") else { throw PipeError.missingEndingParenthesis }

        return expression
    }

    public func scanStreamIdentifier() throws -> Int? {
        guard let word = peekWord() else { return nil }

        _ = try scanWord()
        return try word.asStreamIdentifier()
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

        for key in keywords.keys {
            if keyword.matchesKeyword(key) {
                guard let closure = keywords[key] else { throw PipeError.operandNotValid(keyword: keyword) }

                // We have a closure that can handle this keyword, so we can safely consume the keyword
                _ = tokenizer.scanWord()

                return try closure()
            }
        }
        throw PipeError.operandNotValid(keyword: keyword)
    }

    public func onOptionalKeyword<T>(_ keywords: [String: () throws -> T], throwsOnUnsupportedKeyword: Bool) throws -> T? {
        guard let keyword = tokenizer.peekWord() else {
            return nil
        }

        for key in keywords.keys {
            if keyword.matchesKeyword(key) {
                guard let closure = keywords[key] else { throw PipeError.operandNotValid(keyword: keyword) }

                // We have a closure that can handle this keyword, so we can safely consume the keyword
                _ = tokenizer.scanWord()

                return try closure()
            }
        }

        if throwsOnUnsupportedKeyword {
            throw PipeError.operandNotValid(keyword: keyword)
        } else {
            return nil
        }
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
