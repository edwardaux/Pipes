import Foundation

public final class Diskr: Stage {
    private let filename: String

    init(filename: String) {
        self.filename = filename
    }

    public override func commit() throws {
        guard stageNumber == 1 else { throw PipeError.mustBeFirstStage }
    }

    override public func run() throws {
        let lineReader = try LineReader(path: filename)
        for line in lineReader {
            try output(line)
        }
    }
}

extension Diskr: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "diskr", "<" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let filename = args.scanRemainder()
        if filename.isEmpty {
            throw PipeError.requiredOperandMissing
        }

        return Diskr(filename: filename)
    }

    public static var helpSummary: String? {
        "Reads the contents of a file line by line. The file must exist."
    }

    public static var helpSyntax: String? {
        """
        ►►──┬───<───┬──filename──►◄
            └─DISKR─┘
        """
    }
}
