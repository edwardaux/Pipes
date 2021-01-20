import Foundation

public final class Literal: Stage {
    private let record: String

    public init(_ record: String) {
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
        """
        Writes its argument string into the pipeline and then passes records on the input to the
        output stream. Invoking without a string parameter will pass an empty string.

        Important: the string includes all characters (including whitespace) up to the next
        stage separator. eg. "pipe literal hello | cons" will write "hello " to the next stage.
        If you don't wish to include the trailing space, ensure that the stage separator is
        immediately after the text. eg. "pipe literal hello| cons"
        """
    }

    public static var helpSyntax: String? {
        """
        ►►──LITERAL─┬────────┬──►◄
                    └─string─┘
        """
    }
}

