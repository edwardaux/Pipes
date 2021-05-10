import Foundation

public final class Regex: Stage {
    private let regex: NSRegularExpression
    private let inputRanges: [PipeRange]?

    public init(_ regex: NSRegularExpression, inputRanges: [PipeRange]? = nil) {
        self.regex = regex
        self.inputRanges = inputRanges
    }

    public override func commit() throws {
        try ensureOnlyPrimaryInputStreamConnected()
    }

    override public func run() throws {
        while true {
            let record = try peekto()
            let matched = try record.matches(regex, inRanges: inputRanges)
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

extension Regex: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "regex" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let inputRanges = args.peekRanges()
        if inputRanges != nil {
            _ = try? args.scanRanges()
        }

        let regexString = try args.scanDelimitedString()
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: regexString, options: [])
        } catch let error {
            throw PipeError.invalidRegex(regex: regexString, error: error.localizedDescription)
        }

        try args.ensureNoRemainder()

        return Regex(regex, inputRanges: inputRanges)
    }

    public static var helpSummary: String? {
        """
        Selects records that match a regular expression. Records that do not match are discarded (and
        written to the secondary output stream, if connected). No transformation of the record is
        performed, this stage is purely about matching against a regular expression.

        If no input ranges are provided, the whole record is searched.

        Options:
            inputRanges - One or more input ranges to search within
        """
    }

    public static var helpSyntax: String? {
        """
        ►►──REGEX─┬─────────────┬─delimitedString──►◄
                  └─inputRanges─┘
        """
    }
}
