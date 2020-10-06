import Foundation

public final class Console: Stage {
    public enum EOF {
        // Stop capturing input if the user enters a particular string
        case delimited(String)
        // Keep reading until output stream is disconnected
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
                if streamState(.output).isConnected {
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

    public static func createStage(args: Args) -> Stage {
        return Console()
    }

    public static var helpSummary: String? {
        "When console is first in a pipeline it reads lines from the terminal and writes them into the pipeline (Ctrl-D terminates input). When console is not first in a pipeline it copies lines from the pipeline to the terminal."
    }

    public static var helpSyntax: String? {
        """
        ►►──┬─CONSole──┬──┬──────────────────────┬──►◄
            └─TERMinal─┘  ├─EOF──delimitedString─┤
                          └─NOEOF────────────────┘
        """
    }
}
