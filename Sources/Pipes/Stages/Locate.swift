import Foundation

public final class Locate: Stage {
    private let searchString: String?
    private let inputRange: PipeRange?
    private let anyCase: Bool
    private let anyOf: Bool

    init(_ searchString: String? = nil, inputRange: PipeRange? = nil, anyCase: Bool = false, anyOf: Bool = false) {
        self.searchString = searchString
        self.inputRange = inputRange
        self.anyCase = anyCase
        self.anyOf = anyOf
    }

    public override func commit() throws {
        try ensureOnlyPrimaryInputStreamConnected()
    }

    override public func run() throws {
        while true {
            let record = try peekto()
            let matched = try record.matches(searchString)
            if matched {
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

extension Locate: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "locate" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let searchString = try args.scanWord()

        try args.ensureNoRemainder()

        return Locate(searchString)
    }

    public static var helpSummary: String? {
        """
        Selects records that contain a specified string or that are at least as long as a specified
        length. It discards records that do not contain the specified string or that are shorter than
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
        ►►──LOCATE──┬─────────┬──┬─────────────┬──┬───────┬──┬─────────────────┬──►◄
                    └─ANYcase─┘  └─inputRanges─┘  └─ANYof─┘  └─delimitedString─┘
        """
    }
}
