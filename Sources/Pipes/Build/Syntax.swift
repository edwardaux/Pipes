import Foundation

extension String {
    func asNumber() throws -> Int {
        guard let number = Int(self) else {
            throw PipeError.invalidNumber(word: self)
        }
        return number
    }

    func asXorC() throws -> Character {
        let upper = self.uppercased()

        if count == 1, let char = first {
            return char
        } else if count == 2, let asInt = Int(self, radix: 16), let unicodeScalar = UnicodeScalar(asInt) {
            return Character(unicodeScalar)
        } else if upper == "TAB" || upper == "TABULATE" {
            return "\t"
        } else if upper == "BLANK" || upper == "SPACE" {
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
