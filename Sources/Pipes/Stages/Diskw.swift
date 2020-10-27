import Foundation

public final class Diskw: Stage {
    private let filename: String

    init(filename: String) {
        self.filename = filename
    }

    public override func commit() throws {
        guard stageNumber != 1 else { throw PipeError.cannotBeFirstStage }
    }

    override public func run() throws {
        let lineWriter = try LineWriter(path: filename, append: false)

        do {
            while true {
                let record = try peekto()
                lineWriter.write(record)
                do {
                    if isPrimaryOutputStreamConnected {
                        try output(record)
                    }
                } catch _ as EndOfFile {
                    // If the output stream is propagating EOF back, that's OK.
                    // We'll just keep on writing to the file regardless.
                }
                _ = try readto()
            }
        } catch _ as EndOfFile {
            try lineWriter.close()
        }
    }
}

extension Diskw: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "diskw", ">" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let filename = args.scanRemainder()
        if filename.isEmpty {
            throw PipeError.requiredOperandMissing
        }

        return Diskw(filename: filename)
    }

    public static var helpSummary: String? {
        """
        Replaces a file on disk. If the file doesn't exist, it will be created.
        """
    }

    public static var helpSyntax: String? {
        """
        ►►──┬───>───┬──filename──►◄
            └─DISKW─┘
        """
    }
}
