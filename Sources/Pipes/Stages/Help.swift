import Foundation

public final class Help: Stage {
    private let stageName: String

    init(stageName: String) {
        self.stageName = stageName
    }

    override public func run() throws {
        do {
            let stageType = try Pipe.registeredStageType(for: stageName)
            let outputLines = [
                stageType.helpSyntax,
                stageType.helpSummary
            ].compactMap { $0 }

            // Dump to the console
            for line in outputLines {
                print(line)
            }

            // If we're in a pipeline, then send the records down the line.
            if isPrimaryOutputStreamConnected {
                for line in outputLines {
                    try output(line)
                }
            }
        } catch {
            print(PipeError.stageNotFound(stageName: stageName).localizedDescription)
        }
    }
}

extension Help: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "help" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let stageName = try args.scanWord()

        try args.ensureNoRemainder()

        return Help(stageName: stageName)
    }

    public static var helpSummary: String? {
        """
        Outputs help information for the provided stage name to the console
        """
    }

    public static var helpSyntax: String? {
        """
        ►►──HELP─stageName──►◄
        """
    }
}

extension Help {
    public static var inputRangeHelpSyntax: String {
        """
        inputRange:

        ├──┬──────────────────────────────────────────────┬─┬────────┬─┬─range───────────┬──┤
           │ ┌──────────────────────────────────────────┐ │ ├─wrdSep─┤ ├─snumber─────────┤
           └─􏰁▼─┬─WORDSEParator──xorc──────────────────┬─┴─┘ └─fldSep─┘ └─snumber;snumber─┘
               └─FIELDSEParator──xorc─┬─────────────┬─┘
                                      └─Quote──xorc─┘

        wrdSep:

        ├──┬─────────────────────┬─Words──┤
           └─WORDSEParator──xorc─┘

        fldSep:

        ├──┬──────────────────────────────────────┬─Fields──┤
           └─FIELDSEParator──xorc─┬─────────────┬─┘
                                  └─Quote──xorc─┘
        """
    }
}
