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
        } else if matchesKeyword("TABulate") {
            return "\t"
        } else if matchesKeyword("BLANK", "SPACE") {
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
    /**
     For a given string, return whether that string matches the passed keyword
     with the rules that the case of the keyword implies how much must match. For
     example, any uppercase characters in the keyword represent the minimum length
     of the string that must be present. All comparisons are case insensitive ie.
     the casing of the keyword purely indicates how much of the string must match.
     eg. where the keyword is "CHARacters", this will match "CHAR", "chAr", "CHARAC",
     "CHARactTERS", but will not match "CHA", "cha", "charx", or "charactersx".
     */
    func matchesKeyword(_ keywords: String...) -> Bool {
        for keyword in keywords {
            var minLength = 0
            for char in keyword {
                if char.isUppercase {
                    minLength += 1
                } else {
                    break
                }
            }
            if matchesKeyword(keyword, minLength: minLength) {
                return true
            }
        }
        return false
    }

    private func matchesKeyword(_ keyword: String, minLength: Int) -> Bool {
        guard self.count >= minLength else { return false }
        guard keyword.count >= self.count else { return false }

        return keyword.uppercased().hasPrefix(self.uppercased())
    }
}
