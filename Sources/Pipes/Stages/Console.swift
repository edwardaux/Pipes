import Foundation

public final class Console: Stage {
    public enum EOF {
        case delimited(String)
        case none
    }

    private let eof: EOF

    init(eof: EOF = .none) {
        self.eof = eof
    }

    override public func run() throws {
        if stageNumber == 1 {
            var record = readLine(strippingNewline: true)
            while record != nil {
                if case let .delimited(eofString) = eof, record == eofString {
                    break
                } else {
                    try output(record!)
                }
                record = readLine(strippingNewline: true)
            }
        } else {
            while true {
                let record = try peekto()
                print(record)
                if isPrimaryOutputStreamConnected {
                    try output(record)
                }
                _ = try readto()
            }
        }
    }
}

extension Console: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "cons", "console", "term", "terminal" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let eof: EOF = try args.onOptionalKeyword(
            [
                "EOF": { EOF.delimited(try args.scanDelimitedString()) },
                "NOEOF": { EOF.none }
            ],
            throwsOnUnsupportedKeyword: true
        ) ?? EOF.none

        try args.ensureNoRemainder()

        return Console(eof: eof)
    }

    public static var helpSummary: String? {
        """
        When console is first in a pipeline it reads lines from the terminal and writes them into the
        pipeline. When console is not first in a pipeline it copies lines from the pipeline to the
        terminal. By default, Ctrl-D triggers end of file.

        Options:
            EOF delimitedString - Specifies a delimited string that will cause end of file to be
                                  triggered when this string is entered (with leading or trailing
                                  blanks, or both).
            NOEOF               - Specifies that input data are not inspected for an end-of-file
                                  indication; console stops only when it finds that its output
                                  stream is not connected
        """
    }

    public static var helpSyntax: String? {
        """
        ►►──┬─CONSole──┬──┬──────────────────────┬──►◄
            └─TERMinal─┘  ├─EOF──delimitedString─┤
                          └─NOEOF────────────────┘
        """
    }
}
