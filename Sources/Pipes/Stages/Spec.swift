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

        try args.ensureNoRemainder()

        return Spec(items)
    }

    public static var helpSummary: String? {
        """
        Builds output records from the contents of input records and literal fields. It does this
        by processing a list of specifications (a specification list) for each input record.

        The specification of a field in the output record consists of:

         * The source of the data to be loaded. It can refer to the input record; it can refer to
            symbolic fields maintained by spec; or it can be a literal argument. When the input
            record is the source of the data, the extent of the input field can be specified as a
            column range, a range of blank-delimited words, or a range of tab-delimited fields. The
            input field can also consist of a single column (or word or field); its position can be
            relative to the beginning or the end of the input record.
          * An optional keyword to specify that the input field is to be stripped of leading and
            trailing blanks before further processing.
          * An optional conversion routine. A conversion routine is specified as three characters
            that has the digit 2 (an abbreviation for the word “to”) in the middle. The first and
            the last character must both be one of the characters BCX. The first letter specifies
            the format of the input field; the last letter specifies the format to which the field
            is to be converted.
          * The position of the field in the output record. This can be a column number, a range,
            or the keywords NEXT or NEXTWORD.
          * An optional keyword to specify the placement of the data within the output field. This
            can be LEFT, CENTRE, or RIGHT.

        The output record is built in the order the items are specified. The length of a literal
        field is given by the length of the literal itself. A copied input field extends to the end
        of the input record or the ending column of the input field, whichever occurs first. The
        output record is at least long enough to contain all literal fields and all output fields
        defined with a range. It is longer if there is an input data field beyond the last literal
        field, and the input record does contain at least part of the input field.

        Padding: Pad characters (blank by default) are filled in positions not loaded with characters
        from a literal or an input field. The keyword PAD sets the pad character to be used when
        processing subsequent specification items.

        Input field: An input range specification defines a substring of an input record. Depending
        on the length of a record, an input range may be present in full, partially, or not at all.
        Input ranges not present in a record are considered to be empty; that is, of length zero.
        The beginning and end of an input range are, in general, defined by a pair of numbers
        separated by a semicolon (for example, 5;8). An unsigned number is relative to the beginning
        of the record; a negative number is relative to the end of the record. None, any one, or both
        of the numbers may be negative. When the two numbers have the same sign, the first number must
        be less than or equal to the second number. When both numbers in the range are unsigned, a
        hyphen may be used as the separator rather than a semicolon. A range relative to the beginning
        of a record may also be specified as two numbers separated by a period, denoting the beginning
        of the range and its length, respectively. An input range with no further qualification denotes
        a range of columns. WORDS may be prefixed to indicate a word range; FIELDS may be prefixed to
        indicate a field range.

        Record number: You can put the number of each record into the record, for instance, to generate
        a sequence field. The keyword NUMBER (with synonym RECNO) describes a 10-byte input field
        generated internally; it contains the number of the current record, right aligned with leading
        blanks (no leading zeros). Records are numbered from 1 with the increment 1 when no further
        keywords are specified. The word after the keyword FROM specifies the number for the first
        record; it can be negative. The word after the keyword BY specifies the increment; it too can
        be negative. The keywords apply to a particular instance of NUMBER. When the record number is
        negative, a leading minus sign is inserted in front of the most significant digit in the
        record number.

        Literal field: This is a constant that appears in all output records. A literal character
        string is written as:
         * A delimited string (delimitedString) consisting of a character string between two occurrences
           of a delimiter character, which cannot occur in the string. The delimiter character cannot
           be blank. It is suggested that a special character be used for the delimiter, but this is not
           enforced.
         * A hexadecimal literal consisting of a leading “x” or “h” (in lower case or upper case)
           followed by an even number of hex characters.
         * A binary literal consisting of a leading “b” (in lower case or upper case) followed by zero
           and one characters in multiples of eight.

        Stripping: The keyword STRIP specifies that the field (input field, sequence number, time of day,
        or literal) is to be stripped of leading and trailing blanks before conversion (if any) and
        before the default output field size is determined.

        Conversion: A field (input or literal) is put in the output record as it is when no conversion
        is requested for the item. Put the name of a conversion routine between the input and output
        specifications when you wish to change the format of a field. Supported conversion types are:
         * B - Bit string. eg "0100100001101001"
         * C - Character. eg "Hi"
         * X - Hexadecimal number. eg "4869"

        Output field position: The output specification can consist of the keywords NEXT or NEXTWORD, a
        column number, or a column range. NEXT indicates that the item is put immediately after the
        rightmost item that has been put in the output buffer so far. NEXTWORD appends a blank to a
        buffer that is not empty before appending the item. (A field placed with NEXT or NEXTWORD can
        be overlaid by a subsequent specification indicating a specific output column.) Append a period
        and a number to specify an explicit field length with the keywords NEXT and NEXTWORD.

        Output field length: Fields for which an explicit length is specified are always present in the
        output record. Input fields that are not present in the input record or have become empty after
        stripping caused by the STRIP keyword are not stored in the output record. An empty literal
        field is stored in the output record. The default length of the output field is the length of
        the input field after conversion (but before placement). When an output range is specified
        without a placement option, the input field after conversion is aligned on the left (possibly
        with leading blank characters), truncated or padded on the right with pad characters.

        A placement keyword (LEFT, CENTRE, CENTER, or RIGHT) is optional in the output field definition.
        If a placement option is specified, the input field after conversion (and thus after the length
        of the output field is determined) is stripped of leading and trailing blank characters.
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
