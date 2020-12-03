import Foundation

public final class Spec: Stage {
    private let items: [Item]

    private var pad: Character = " "
    private var recno: Int = 0
    private var timestamp: Date = Date()

    convenience init(_ items: Item...) {
        self.init(items)
    }

    init(_ items: [Item]) {
        self.items = items
    }

    public override func commit() throws {
        guard items.count > 0 else { throw PipeError.emptyParameterList }

        try ensureOnlyPrimaryOutputStreamConnected()
    }

    override public func run() throws {
        while true {
            let inputRecord = try peekto()
            var outputRecord = ""
            for item in items {
                switch item {
                case .pad(let char):
                    pad = char
                case .field(let input, let strip, let conversion, let output, let alignment):
                    outputRecord = try evaluate(
                        input: input,
                        strip: strip,
                        conversion: conversion,
                        recno: recno,
                        timestamp: timestamp,
                        output: output,
                        alignment: alignment,
                        pad: pad,
                        inputRecord:
                        inputRecord,
                        outputSoFar: outputRecord
                    )
                }
            }
            try output(outputRecord)
            _ = try readto()
            recno += 1
        }
    }

    private func evaluate(input: Item.Input, strip: Bool, conversion: Conversion?, recno: Int, timestamp: Date, output: Item.Output, alignment: Alignment, pad: Character, inputRecord: String, outputSoFar: String) throws -> String {
        var inputString = try input.extract(from: inputRecord, recno: recno, timestamp: timestamp)
        if strip {
            inputString = inputString.trimmingCharacters(in: .whitespaces)
        }
        if let conversion = conversion {
            inputString = try conversion.convert(inputString)
        }
        return try output.place(inputString, outputSoFar: outputSoFar, alignment: alignment, pad: pad)
    }

    public enum Item {
        public enum Input {
            case range(PipeRange)
            case literal(String)
            case number(start: Int = 1, by: Int = 1)
            case timestamp(formatter: DateFormatter)

            func extract(from string: String, recno: Int, timestamp: Date) throws -> String {
                switch self {
                case .range(let range):
                    return try string.extract(fromRange: range)
                case .literal(let literal):
                    return literal
                case .number(let start, let by):
                    return "\(start + (recno * by))"
                case .timestamp(let formatter):
                    return formatter.string(from: timestamp)
                }
            }
        }
        public enum Output {
            case next(width: Int? = nil)
            case nextWord(width: Int? = nil)
            case nextField(width: Int? = nil)
            case offset(Int, width: Int? = nil)
            case range(PipeRange)

            func place(_ string: String, outputSoFar: String, alignment: Alignment, pad: Character) throws -> String {
                let width = try calculateWidth(string: string)

                var adjusted = string.aligned(alignment: alignment, length: width, pad: pad, truncate: true)
                var metrics = try calculateMetrics(outputSoFar: outputSoFar, string: adjusted)

                if case .nextWord = self {
                    // We only prepend a blank if the new string is non-blank, and also if there's
                    // already some content in the output buffer
                    adjusted = !adjusted.isEmpty && !outputSoFar.isEmpty ? " \(adjusted)" : adjusted
                    metrics = (start: metrics.start, width: metrics.width + 1)
                } else if case .nextField = self {
                    // We only prepend a tab if the new string is non-blank, and also if there's
                    // already some content in the output buffer
                    adjusted = !adjusted.isEmpty && !outputSoFar.isEmpty ? "\t\(adjusted)" : adjusted
                    metrics = (start: metrics.start, width: metrics.width + 1)
                }


                return outputSoFar.insertString(string: adjusted, start: metrics.start)
            }

            func calculateWidth(string: String) throws -> Int {
                switch self {
                case .next(let width):
                    return width ?? string.count
                case .nextWord(let width):
                    return width ?? string.count
                case .nextField(let width):
                    return width ?? string.count
                case .offset(_, let width):
                    return width ?? string.count
                case .range(let range):
                    if range.end == .end {
                        throw PipeError.outputRangeEndInvalid
                    }
                    return range.end - range.start + 1
                }
            }

            func calculateMetrics(outputSoFar: String, string: String) throws -> (start: Int, width: Int) {
                let width = try calculateWidth(string: string)

                switch self {
                case .next, .nextWord, .nextField:
                    return (start: outputSoFar.count + 1, width: width)
                case .offset(let offset, _):
                    return (start: offset, width: width)
                case .range(let range):
                    return (start: range.start, width: width)
                }
            }
        }

        case pad(Character)
        case field(input: Input, strip: Bool = false, conversion: Conversion? = nil, output: Output, alignment: Alignment = .left)
    }
}

extension Spec: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "spec", "specs" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        var items: [Item] = []

        while true {
            if args.nextKeywordMatches("PAD") {
                _ = try args.scanWord()
                let padChar = try args.scanWord().asXorC()
                items.append(.pad(padChar))
            } else {
                var input: Item.Input
                if let range = args.peekRange() {
                    _ = try args.scanRange()
                    input = .range(range)
                } else if args.nextKeywordMatches("TIMEstamp") {
                    _ = try args.scanWord()
                    var pattern = "yyyy-MM-dd'T'HH:mm:ssZ"
                    if args.nextKeywordMatches("PATTERN") {
                        _ = try args.scanWord()
                        if let patternOverride = try? args.scanDelimitedString() {
                            pattern = patternOverride
                        } else {
                            throw PipeError.valueMissingForOption(keyword: "PATTERN")
                        }
                    }
                    let formatter = DateFormatter()
                    formatter.dateFormat = pattern
                    formatter.timeZone = TimeZone.current
                    input = .timestamp(formatter: formatter)
                } else if args.nextKeywordMatches("NUMBER") || args.nextKeywordMatches("RECNO") {
                    _ = try args.scanWord()
                    var start = 1
                    var by = 1
                    if args.nextKeywordMatches("FROM") {
                        _ = try args.scanWord()
                        start = try args.scanWord().asNumber(allowNegative: true)
                    }
                    if args.nextKeywordMatches("BY") {
                        _ = try args.scanWord()
                        by = try args.scanWord().asNumber(allowNegative: true)
                    }
                    input = .number(start: start, by: by)
                } else if let string = args.peekDelimitedString() {
                    _ = try args.scanDelimitedString()
                    input = .literal(string)
                } else {
                    if let word = args.peekWord() {
                        throw PipeError.invalidRange(range: word)
                    } else {
                        // No more input, let's break out of the loop
                        break
                    }
                }

                var inputIsRecno = false
                if case .number = input {
                    inputIsRecno = true
                }

                var strip = false
                if args.nextKeywordMatches("STRIP") {
                    _ = try args.scanWord()
                    strip = true
                }

                var conversion: Conversion?
                if let word = args.peekWord(), let conv = Conversion.from(word) {
                    _ = try args.scanWord()
                    conversion = conv
                }

                let output: Item.Output
                if let word = args.peekWord() {
                    let pieces = word.components(separatedBy: ".")
                    if pieces[0].matchesKeyword("Next") {
                        _ = try args.scanWord()
                        if pieces.count == 1 {
                            if inputIsRecno && !strip {
                                output = .next(width: 10)
                            } else {
                                output = .next()
                            }
                        } else if pieces.count == 2 {
                            let width = try pieces[1].asNumber(allowNegative: false)
                            output = .next(width: width)
                        } else {
                            throw PipeError.invalidNumber(word: word)
                        }
                    } else if pieces[0].matchesKeyword("NEXTWord", "NW") {
                        _ = try args.scanWord()
                        if pieces.count == 1 {
                            if inputIsRecno && !strip {
                                output = .nextWord(width: 10)
                            } else {
                                output = .nextWord()
                            }
                        } else if pieces.count == 2 {
                            let width = try pieces[1].asNumber(allowNegative: false)
                            output = .nextWord(width: width)
                        } else {
                            throw PipeError.invalidNumber(word: word)
                        }
                    } else if pieces[0].matchesKeyword("NEXTField", "NF") {
                        _ = try args.scanWord()
                        if pieces.count == 1 {
                            if inputIsRecno && !strip {
                                output = .nextField(width: 10)
                            } else {
                                output = .nextField()
                            }
                        } else if pieces.count == 2 {
                            let width = try pieces[1].asNumber(allowNegative: false)
                            output = .nextField(width: width)
                        } else {
                            throw PipeError.invalidNumber(word: word)
                        }
                    } else if pieces.count == 1, let offset = try? pieces[0].asNumber(allowNegative: false) {
                        _ = try args.scanWord()
                        if inputIsRecno && !strip {
                            output = .offset(offset, width: 10)
                        } else {
                            output = .offset(offset)
                        }
                    } else {
                        if let range = args.peekRange() {
                            _ = try args.scanRange()
                            output = .range(range)
                        } else {
                            throw PipeError.outputSpecificationInvalid(word: word)
                        }
                    }
                } else {
                    throw PipeError.outputSpecificationMissing
                }

                var alignment: Alignment = .left
                if inputIsRecno {
                    alignment = .right
                }
                if let word = args.peekWord() {
                    if word.matchesKeyword("Left") {
                        _ = try args.scanWord()
                        alignment = .left
                    } else if word.matchesKeyword("Center", "Centre") {
                        _ = try args.scanWord()
                        alignment = .center
                    } else if word.matchesKeyword("Right") {
                        _ = try args.scanWord()
                        alignment = .right
                    }
                }

                let item = Item.field(input: input, strip: strip, conversion: conversion, output: output, alignment: alignment)
                items.append(item)
             }
        }

        return Spec(items)
    }

    public static var helpSummary: String? {
        """
        Builds output records from the contents of input records and literal fields. It does this
        by processing a list of specifications (a specification list) for each input record.
        """
    }

    public static var helpSyntax: String? {
        """
                   ┌──────────────┐
        ►►──SPECs──▼─┬─┤ field ├┬─┴──►◄
                     └─PAD xorc─┘

        field:

        ├──┬─inputRange─────────────────────────────────────┬──┬───────┬──►
           ├─┬─NUMBER─┬──┬───────────────┬──┬─────────────┬─┤  └─STRIP─┘
           │ └─RECNO──┘  └─FROM──snumber─┘  └─BY──snumber─┘ │
           ├─TIMEstamp───┬──────────────────────────┬───────┤
           │             └─PATTERN──delimitedString─┘       │
           └─delimitedString────────────────────────────────┘

        ►──┬────────────────┬──┬─┬─Next──────┬──┬───────────┬─┬──┬────────┬──┤
           └─┤ conversion ├─┘  │ ├─NEXTWord──┤  └─.──number─┘ │  ├─Left───┤
                               │ └─NEXTField─┘                │  ├─Center─┤
                               ├─number───────────────────────┤  └─Right──┘
                               └─range────────────────────────┘
        """
    }
}
