import Foundation

extension Int {
    static public var end = Int.max
}

public indirect enum PipeRange: Equatable {
    case full
    case column(start: Int, end: Int)
    case word(start: Int, end: Int, separator: Character = " ")
    case field(start: Int, end: Int, separator: Character = "\t", quoteCharacter: Character? = nil)

    var start: Int {
        switch self {
        case .full: return .end
        case .column(let start, _): return start
        case .word(let start, _, _): return start
        case .field(let start, _, _, _): return start
        }
    }

    var end: Int {
        switch self {
        case .full: return .end
        case .column(_, let end): return end
        case .word(_, let end, _): return end
        case .field(_, let end, _, _): return end
        }
    }

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
        case .field(let originalStart, let originalEnd, let separator, let quoteCharacter):
            var fieldBoundaries = [(Int, Int, Bool)]()
            var fieldStart = 0

            // When we have a quoteCharacter, the quote needs to be the very first character after
            // the separator. That is, it needs to be:
            //   ,"hello",
            // and not:
            //   , "hello",
            // In the latter case, we treat this field as if it were an unquoted field and any quotes
            // are effectively ignored.  The hasStartedField keeps track of whether we've processed
            // any non-quote characters.
            var hasStartedField = false

            // Keeps track of whether we're currently inside a quoted string.
            var inQuotedString = false

            // Keeps track of whether the current field was a quoted string, because quoted strings
            // get added to the list of boundaries when the quote ends, whereas unquoted strings get
            // added when the separator is encountered.
            var wasQuotedString = false

            for (index, char) in self.enumerated() {
                if char == quoteCharacter {
                    if inQuotedString {
                        // The current quote is ending the string that we're in, so we can
                        // add the latest boundaries to our list.
                        fieldBoundaries.append((fieldStart, index+1, true))

                        // Consume the quote character.
                        fieldStart = index + 1

                        // We are no longer in a quoted string, but we mark that the current
                        // field was indeed a quoted string.
                        inQuotedString = false
                        wasQuotedString = true
                    } else if hasStartedField {
                        // We've encountered the first quote character (because inQuotedString=false)
                        // but because hasStartedField=true it means that we are treating this field
                        // as an unquoted field.
                        wasQuotedString = false
                    } else {
                        // We've encountered the first quote character, so we're opening a quoted string.
                        inQuotedString = true
                    }

                    // Consuming this quote means we've started processing this field.
                    hasStartedField = true
                } else if char == separator && !inQuotedString {
                    // We've encountered a separator character (that is outside a quoted string). If it
                    // was a quoted string, then the boundary is added when the end quote is hit, so we
                    // don't need to do it here. Otherwise, if it wasn't a quoted string, we'll add the
                    // boundary info now.
                    if !wasQuotedString {
                        fieldBoundaries.append((fieldStart, index, false))
                        hasStartedField = false
                    }

                    // Consume the separator charater.
                    fieldStart = index + 1

                    // Reset these for the next field.
                    hasStartedField = false
                    inQuotedString = false
                    wasQuotedString = false
                } else {
                    // We're encountered a character that isn't a quote or a separator. If wasQuotedString
                    // is true, then it means there's characters after the ending quote (which is invalid).
                    if wasQuotedString {
                        throw PipeError.unexpectedCharacters(expected: "\(separator)", found: "\(char)")
                    }

                    // Consuming this character means we've started processing this field.
                    hasStartedField = true
                }
            }

            if let quoteCharacter = quoteCharacter, inQuotedString {
                // If we're still in a quoted string by the time we have processed all the input, then it
                // means there's a missing trailing quote.
                throw PipeError.delimiterMissing(delimiter: "\(quoteCharacter)")
            }

            if !wasQuotedString {
                // Quoted string boundaries are added when the closing quote is encountered. However, we
                // need to add the last field for non-quoted strings.
                fieldBoundaries.append((fieldStart, count, false))
            }

            guard let (start, end) = try PipeRange.resolve(start: originalStart, end: originalEnd, length: fieldBoundaries.count) else {
                // When resolve() returns a nil, it means the start value
                // is beyond the end of the input, so we can just return an
                // empty string in this case.
                return ""
            }

            let fieldBoundaryStart = fieldBoundaries[start]
            let fieldBoundaryEnd = fieldBoundaries[end]
            if start == end && fieldBoundaryStart.2 && fieldBoundaryEnd.2 {
                let startIndex = self.index(self.startIndex, offsetBy: fieldBoundaryStart.0 + 1)
                let endIndex = self.index(self.startIndex, offsetBy: fieldBoundaryEnd.1 - 1)

                return String(self[startIndex..<endIndex])
            } else {
                let startIndex = self.index(self.startIndex, offsetBy: fieldBoundaryStart.0)
                let endIndex = self.index(self.startIndex, offsetBy: fieldBoundaryEnd.1)

                return String(self[startIndex..<endIndex])
            }
        }
    }

    public func matches(_ searchString: String? = nil, inRanges ranges: [PipeRange]? = nil, anyCase: Bool = false, anyOf: Bool = false) throws -> Bool {
        if let ranges = ranges {
            for range in ranges {
                if try matches(searchString, inRange: range, anyCase: anyCase, anyOf: anyOf) {
                    return true
                }
            }
            return false
        } else {
            return try matches(searchString, inRange: nil, anyCase: anyCase, anyOf: anyOf)
        }
    }

    private func matches(_ searchString: String? = nil, inRange range: PipeRange? = nil, anyCase: Bool = false, anyOf: Bool = false) throws -> Bool {
        let source = anyCase ? self.lowercased() : self
        let target = (anyCase ? searchString?.lowercased() : searchString) ?? ""

        let range = range ?? PipeRange.full
        let extractedSource = try source.extract(fromRange: range)

        if anyOf {
            if target.isEmpty {
                return extractedSource.count > 0
            } else {
                let allowedChars = CharacterSet(charactersIn: target)
                return extractedSource.rangeOfCharacter(from: allowedChars) != nil
            }
        } else {
            if target.isEmpty {
                return extractedSource.count > 0
            } else {
                return extractedSource.contains(target)
            }
        }
    }

    public func matches(_ regex: NSRegularExpression, inRanges ranges: [PipeRange]? = nil) throws -> Bool {
        if let ranges = ranges {
            for range in ranges {
                if try matches(regex, inRange: range) {
                    return true
                }
            }
            return false
        } else {
            return try matches(regex, inRange: nil)
        }
    }

    private func matches(_ regex: NSRegularExpression, inRange range: PipeRange? = nil) throws -> Bool {
        let range = range ?? PipeRange.full
        let extractedSource = try extract(fromRange: range)
        return regex.firstMatch(in: extractedSource, options: [], range: NSRange(location: 0, length: extractedSource.utf16.count)) != nil
    }
}
