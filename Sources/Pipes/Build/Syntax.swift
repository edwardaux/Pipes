import Foundation

extension String {
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
}
