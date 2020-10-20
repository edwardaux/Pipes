import Foundation

class StringTokenizer {
    /// Original input string
    private let input: String

    /// Current cursor offset into input string
    private var currentIndex: String.Index

    /// The offset that we will reset to if the undo() function is called
    private var undoIndex: String.Index

    /// A single mark that can be set to mark the current location, and
    /// return to it a later state (useful for undoing multiple reads)
    private var markIndex: String.Index?

    private let escape: Character?

    init(_ input: String, escape: Character? = nil) {
        self.input = input
        self.currentIndex = input.startIndex
        self.undoIndex = input.startIndex
        self.markIndex = nil
        self.escape = escape
    }

    func peekChar() -> String? {
        let char = scanChar()
        undo()
        return char
    }

    func scanChar() -> String? {
        undoIndex = currentIndex

        guard let firstNonBlankIndex = skipChars(" ") else { return nil }

        currentIndex = input.index(after: firstNonBlankIndex)
        return String(input[firstNonBlankIndex]).unescaped(escape)
    }

    func peekWord() -> String? {
        let word = scanWord()
        undo()
        return word
    }

    func scanWord() -> String? {
        undoIndex = currentIndex

        guard let firstNonBlankIndex = skipChars(" ") else { return nil }

        let nextBlankIndex = findNext(" ") ?? input.endIndex
        currentIndex = nextBlankIndex
        return String(input[firstNonBlankIndex..<nextBlankIndex]).unescaped(escape)
    }

    func scan(between start: Character, and end: Character) -> String? {
        undoIndex = currentIndex

        guard let startIndex = findNext(start, consume: true) else { return nil }
        guard let endIndex = findNext(end, startingIndex: startIndex) else { return nil }

        currentIndex = input.index(after: endIndex)

        return String(input[startIndex..<endIndex]).unescaped(escape)
    }

    func scanRemainder(trimLeading: Bool, trimTrailing: Bool) -> String {
        if trimLeading {
            _ = skipChars(" ")
        }
        let remainder = String(input[currentIndex...])
        return (trimTrailing ? remainder.trimmingCharacters(in: CharacterSet.whitespaces) : remainder).unescaped(escape)
    }

    func undo() {
        currentIndex = undoIndex
    }

    func mark() {
        markIndex = currentIndex
    }

    func resetMark() {
        if let markIndex = markIndex {
            currentIndex = markIndex
        }
        markIndex = nil
    }

    private func skipChars(_ char: Character) -> String.Index? {
        guard currentIndex != input.endIndex else { return nil }

        while currentIndex != input.endIndex {
            if input[currentIndex] == escape {
                currentIndex = safelyAdvance(currentIndex)
            }
            if currentIndex != input.endIndex && input[currentIndex] == char {
                currentIndex = safelyAdvance(currentIndex)
            } else {
                break
            }
        }
        return currentIndex == input.endIndex ? nil : currentIndex
    }

    private func findNext(_ char: Character, consume: Bool = false, startingIndex: String.Index? = nil) -> String.Index? {
        var index = startingIndex ?? currentIndex

        while index != input.endIndex {
            if input[index] == escape {
                index = safelyAdvance(index)
                index = safelyAdvance(index)
            }
            if index != input.endIndex && input[index] != char {
                index = safelyAdvance(index)
            } else {
                break
            }
        }
        if index != input.endIndex && consume {
            index = input.index(after: index)
        }
        return index == input.endIndex ? nil : index
    }

    private func safelyAdvance(_ index: String.Index) -> String.Index {
        guard index != input.endIndex else { return index }
        return input.index(after: index)
    }
}

extension String {
    func unescaped(_ escape: Character?) -> String {
        guard let escape = escape else { return self }

        var output = ""
        var chars = makeIterator()
        while let char = chars.next() {
            if char == escape, let escaped = chars.next() {
                output.append(escaped)
            } else {
                output.append(char)
            }
        }
        return output
    }

    func split(separator: Character, escape: Character?) -> [String] {
        var token = ""
        var tokens = [String]()
        var chars = makeIterator()

        while let char = chars.next() {
            switch char {
            case separator:
                tokens.append(token)
                token = ""
            case escape:
                if let next = chars.next() {
                    token.append(next)
                }
            case _:
                token.append(char)
            }
        }
        tokens.append(token)

        return tokens
    }
}
