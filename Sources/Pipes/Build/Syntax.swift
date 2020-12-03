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

    // Takes a given string and inserts it into the current string. Note that start
    // is 1-indexed.
    public func insertString(string: String, start: Int) -> String {
        assert(start > 0, "start is expected to be greater than 0")

        let length = string.count

        // If the starting position is at the end of the string, we can simply catenate
        if start == count {
            return self + string
        }
        // If the starting position is beyond the end of the string, we need to add some
        // leading spaces
        if start > count {
            return self + string.aligned(alignment: .right, length: start - 1 - count + length, pad: " ", truncate: true)
        }

        // If the inserted string will be longer than the current string, we can just chop
        // and append
        if start - 1 + length >= count {
            return prefix(start - 1) + string

        }

        // All we've got left here is an overlay
        let r1 = index(startIndex, offsetBy: start - 1);
        let r2 = index(startIndex, offsetBy: start - 1 + length);
        return replacingCharacters(in: r1..<r2, with: string)
    }

    func aligned(alignment: Alignment, length: Int, pad: Character, truncate: Bool) -> String {
        switch alignment {
        case .left:
            return padRight(length: length, pad: pad, truncate: truncate)
        case .right:
            return padLeft(length: length, pad: pad, truncate: truncate)
        case .center:
            if count >= length {
                if truncate {
                    let start = Int((count - length) / 2)
                    let r1 = index(startIndex, offsetBy: start);
                    let r2 = index(startIndex, offsetBy: start + length);
                    return String(self[r1..<r2])
                } else {
                    return self
                }
            }

            let leftPadLength = Int((length - count) / 2)
            return padLeft(length: leftPadLength + count, pad: pad).padRight(length: length, pad: pad)
        }
    }

    private func padLeft(length: Int, pad: Character, truncate: Bool = false) -> String {
        guard length > count else {
            return truncate ? String(suffix(length)) : self
        }
        return String(repeating: pad, count: length - count) + self
    }

    private func padRight(length: Int, pad: Character, truncate: Bool = false) -> String {
        guard length > count else {
            return truncate ? String(prefix(length)) : self
        }
        return self + String(repeating: pad, count: length - count)
    }

    func split(length: Int) -> [Substring] {
        return stride(from: 0, to: self.count, by: length)
            .map { self[self.index(self.startIndex, offsetBy: $0)..<self.index(self.startIndex, offsetBy: min($0 + length, self.count))] }
    }
}
