import Foundation

public final class Console: Stage {
    override public func run() throws {
        while true {
            let record = try peekto()
            print(record)
            try output(record)
            _ = try readto()
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
        "When console is first in a pipeline it reads lines from the terminal and writes them into the pipeline. When console is not first in a pipeline it copies lines from the pipeline to the terminal."
    }

    public static var helpSyntax: String? {
        """
        ►►──┬─CONSole──┬──┬──────────────────────┬──►◄
            └─TERMinal─┘  ├─EOF──delimitedString─┤
                          └─NOEOF────────────────┘
        """
    }
}
