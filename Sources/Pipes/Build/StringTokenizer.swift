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

    init(_ input: String) {
        self.input = input
        self.currentIndex = input.startIndex
        self.undoIndex = input.startIndex
        self.markIndex = nil
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
        return String(input[firstNonBlankIndex])
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
        return String(input[firstNonBlankIndex..<nextBlankIndex])
    }

    func scan(between start: Character, and end: Character) -> String? {
        undoIndex = currentIndex

        guard let startIndex = findNext(start, consume: true) else { return nil }
        guard let endIndex = findNext(end, startingIndex: startIndex) else { return nil }

        currentIndex = input.index(after: endIndex)

        return String(input[startIndex..<endIndex])
    }

    func scanRemainder(trimLeading: Bool, trimTrailing: Bool) -> String {
        if trimLeading {
            _ = skipChars(" ")
        }
        let remainder = String(input[currentIndex...])
        return trimTrailing ? remainder.trimmingCharacters(in: CharacterSet.whitespaces) : remainder
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

        while currentIndex != input.endIndex, input[currentIndex] == char {
            currentIndex = input.index(after: currentIndex)
        }
        return currentIndex == input.endIndex ? nil : currentIndex
    }

    private func findNext(_ char: Character, consume: Bool = false, startingIndex: String.Index? = nil) -> String.Index? {
        var index = startingIndex ?? currentIndex

        while index != input.endIndex, input[index] != char {
            index = input.index(after: index)
        }
        if index != input.endIndex && consume {
            index = input.index(after: index)
        }
        return index == input.endIndex ? nil : index
    }
}

