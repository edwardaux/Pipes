import Foundation

extension Int {
    static public var end = Int.max
}
public indirect enum PipeRange {
    case full
    case column(start: Int, end: Int)
    case word(start: Int, end: Int, separator: Character = " ")
    case field(start: Int, end: Int, separator: Character = "\t")

    // Converts a 1-based start/end indexes into 0-based indexes, bearing in mind the length
    // of the possible input. Note that the both input and output values are deemed to be
    // inclusive. For example, if we get passed 2 and 6 as an input (with an input length of
    // 10, then that gets converted to 1 and 5. If the same input gets passed with a length
    // of 4, then the return values will be 1 and 3.
    fileprivate static func resolve(start originalStart: Int, end originalEnd: Int, length: Int) throws -> (start: Int, end: Int)? {
        // Our indexes are 1-based, so we can do some basic validation here.
        guard originalStart != 0 && originalEnd != 0 else {
            throw PipeError.invalidRange(range: "\(originalStart);\(originalEnd)")
        }

        // Resolve Int.end
        let start = originalStart == .end ? 1 : originalStart
        let end = originalEnd

        // Resolve negative offsets
        let resolvedStart = start > 0 ? start : length + start + 1
        let resolvedEnd = end > 0 ? end : length + end + 1
        if resolvedStart > resolvedEnd {
            throw PipeError.invalidRange(range: "\(originalStart);\(originalEnd)")
        }

        // If the start is beyond the end, there's no point returning sensible
        // indexes, so we just return nil.
        if resolvedStart > length {
            return nil
        } else {
            return (start: max(1, min(length, resolvedStart)) - 1, end: max(1, min(length, resolvedEnd)) - 1)
        }
    }
}

extension String {
    public func extract(fromRange range: PipeRange) throws -> String {
        switch range {
        case .full:
            return self
        case .column(let originalStart, let originalEnd):
            guard let (start, end) = try PipeRange.resolve(start: originalStart, end: originalEnd, length: self.count) else {
                // When resolve() returns a nil, it means the start value
                // is beyond the end of the input, so we can just return an
                // empty string in this case.
                return ""
            }

            // Now let's convert our start/end into indexes into the string
            let startIndex = self.index(self.startIndex, offsetBy: start)
            let endIndex = self.index(self.startIndex, offsetBy: end + 1)

            return String(self[startIndex..<endIndex])
        case .word(let originalStart, let originalEnd, let separator):
            var wordBoundaries = [(Int, Int)]()

            // Are we in the middle of processing a word?
            var inWord = false
            var wordStart = 0
            for (index, char) in self.enumerated() {
                if char != separator {
                    if !inWord {
                        wordStart = index
                    }
                    inWord = true
                } else {
                    if inWord {
                        wordBoundaries.append((wordStart, index))
                    }
                    inWord = false
                }
            }

            if inWord {
                wordBoundaries.append((wordStart, count))
            }

            guard let (start, end) = try PipeRange.resolve(start: originalStart, end: originalEnd, length: wordBoundaries.count) else {
                // When resolve() returns a nil, it means the start value
                // is beyond the end of the input, so we can just return an
                // empty string in this case.
                return ""
            }

            let startIndex = self.index(self.startIndex, offsetBy: wordBoundaries[start].0)
            let endIndex = self.index(self.startIndex, offsetBy: wordBoundaries[end].1)

            return String(self[startIndex..<endIndex])
        default:
            return self
        }
    }

    public func matches(_ searchString: String? = nil, inRange range: PipeRange? = nil, anyCase: Bool = false, anyOf: Bool = false) throws -> Bool {
        let source = anyCase ? self.lowercased() : self
        let target = (anyCase ? searchString?.lowercased() : searchString) ?? ""

        let range = range ?? PipeRange.full
        let extractedSource = try source.extract(fromRange: range)

        if anyOf {
            let allowedChars = CharacterSet(charactersIn: target)
            return extractedSource.rangeOfCharacter(from: allowedChars) != nil
        } else {
            if target.isEmpty {
                return true
            } else {
                return extractedSource.contains(target)
            }
        }
    }
}
