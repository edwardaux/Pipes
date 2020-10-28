import Foundation

extension String {
    func asNumber(allowNegative: Bool = false) throws -> Int {
        guard let number = Int(self) else {
            throw PipeError.invalidNumber(word: self)
        }
        if !allowNegative && number < 0 {
            throw PipeError.numberCannotBeNegative(number: number)
        }
        return number
    }

    func asNumberOrAsterisk(allowNegative: Bool = false) throws -> Int {
        if self == "*" {
            return Int.max
        } else {
            return try asNumber(allowNegative: allowNegative)
        }
    }

    func asXorC() throws -> Character {
        if count == 1, let char = first {
            return char
        } else if count == 2, let asInt = Int(self, radix: 16), let unicodeScalar = UnicodeScalar(asInt) {
            return Character(unicodeScalar)
        } else if matchesKeyword("TABULATE", minLength: 3) {
            return "\t"
        } else if matchesKeyword("BLANK") || matchesKeyword("SPACE") {
            return " "
        } else {
            throw PipeError.invalidCharacterRepresentation(word: self)
        }
    }

    func asStreamIdentifier() throws -> Int {
        guard let streamIdentifier = Int(self), streamIdentifier >= 0 else {
            throw PipeError.invalidStreamIdentifier(identifier: self)
        }
        return streamIdentifier
    }
}

extension String {
    func matchesKeyword(_ keyword: String) -> Bool {
        return matchesKeyword(keyword, minLength: keyword.count)
    }

    func matchesKeyword(_ keyword: String, minLength: Int) -> Bool {
        guard self.count >= minLength else { return false }
        guard keyword.count >= self.count else { return false }

        return keyword.uppercased().hasPrefix(self.uppercased())
    }
}
