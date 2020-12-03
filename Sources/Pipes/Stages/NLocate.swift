import Foundation

public final class NLocate: Stage {
    private let searchString: String?
    private let inputRanges: [PipeRange]?
    private let anyCase: Bool
    private let anyOf: Bool

    init(_ searchString: String? = nil, inputRanges: [PipeRange]? = nil, anyCase: Bool = false, anyOf: Bool = false) {
        self.searchString = searchString
        self.inputRanges = inputRanges
        self.anyCase = anyCase
        self.anyOf = anyOf
    }

    public override func commit() throws {
        try ensureOnlyPrimaryInputStreamConnected()
    }

    override public func run() throws {
        while true {
            let record = try peekto()
            let matched = try record.matches(searchString, inRanges: inputRanges, anyCase: anyCase, anyOf: anyOf)
            if !matched {
                try output(record)
            } else {
                if isSecondaryOutputStreamConnected {
                    try output(record, streamNo: 1)
                }
            }
            _ = try readto()
        }
    }
}

extension NLocate: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "nlocate" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        var anyCase = false
        if args.nextKeywordMatches("ANYcase") {
            _ = try args.scanWord()
            anyCase = true
        }

        let inputRanges = args.peekRanges()
        if inputRanges != nil {
            _ = try? args.scanRanges()
        }

        var anyOf = false
        if args.nextKeywordMatches("ANYof") {
            _ = try args.scanWord()
            anyOf = true
        }

        let searchString = try? args.scanDelimitedString()

        try args.ensureNoRemainder()

        return NLocate(searchString, inputRanges: inputRanges, anyCase: anyCase, anyOf: anyOf)
    }

    public static var helpSummary: String? {
        """
        Selects discards that contain a specified string or that are at least as long as a specified
        length. It selects records that do not contain the specified string or that are shorter than
        the specified length.

        If no input ranges are provided, the whole record is searched.  Ranges are all 1-based indexes.
        Range columns with a negative value are applied from the end of the input (-1 is last, -2 is
        second-last, and so on).

        Options:
            ANYcase     - ignore case when comparing
            inputRanges - one or more input ranges to search within
            ANYof       - the delimited string contains an enumeration of characters and locate selects
                          records that contain at least one of the enumerated characters within the
                          specified input ranges
        """
    }

    public static var helpSyntax: String? {
        """
        ►►──NLOCATE──┬─────────┬──┬─────────────┬──┬───────┬──┬─────────────────┬──►◄
                     └─ANYcase─┘  └─inputRanges─┘  └─ANYof─┘  └─delimitedString─┘
        """
    }
}
