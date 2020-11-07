import Foundation

public indirect enum PipeRange {
    case full
    case column(start: Int, end: Int)
    case word(start: Int, end: Int, separator: Character = " ")
    case field(start: Int, end: Int, separator: Character = "\t")
}

extension String {
    public func extract(fromRange range: PipeRange) throws -> String {
        switch range {
        case .full:
            return self
        case .column(let start, let end):
            // Start cannot be negative and our indexes are 1-based, so
            // we can do some basic validation here.
            guard start > 0 && end != 0 else {
                throw PipeError.invalidRange(range: "\(start);\(end)")
            }

            // Resolve negative offsets
            let resolvedStart = start
            let resolvedEnd = end > 0 ? end : self.count + end + 1
            if resolvedStart > resolvedEnd {
                throw PipeError.invalidRange(range: "\(start);\(end)")
            }

            // If the start is beyond the end of the string, we know we're
            // not going to be able to extract anything
            if resolvedStart > self.count {
                return ""
            }

            // Now let's convert our start/end into indexes into the string
            let startIndex = self.index(self.startIndex, offsetBy: max(1, min(self.count, resolvedStart)) - 1)
            let endIndex = self.index(self.startIndex, offsetBy: max(1, min(self.count, resolvedEnd)))

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
