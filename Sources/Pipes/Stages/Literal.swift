import Foundation

public final class Literal: Stage {
    private let record: String

    init(_ record: String) {
        self.record = record
    }

    override public func run() throws {
        try output(record)

        while true {
            let record = try peekto()
            try output(record)
            _ = try readto()
        }
    }
}

extension Literal: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "literal" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        var literal = args.scanRemainder(trimLeading: false, trimTrailing: false)
        if literal.first == " " {
            literal = String(literal.dropFirst())
        }
        return Literal(literal)
    }

    public static var helpSummary: String? {
        "literal writes its argument string into the pipeline and then passes records on the input to the output stream"
    }

    public static var helpSyntax: String? {
        """
        ►►────LITERAL──┬────────┬────►◄
                       └─string─┘
        """
    }
}

