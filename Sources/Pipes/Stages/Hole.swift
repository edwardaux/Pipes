import Foundation

public final class Hole: Stage {
    override public func run() throws {
        for i in 0..<maxInputStreamNo {
            do {
                while true {
                    _ = try readto(streamNo: UInt(i))
                }
            } catch _ as PipeReturnCode {
            }
        }
    }
}

extension Hole: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "hole" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        try args.ensureNoRemainder()

        return Hole()
    }

    public static var helpSummary: String? {
        "Hole reads and discards records without writing any. It can be used to consume output from stages that would terminate prematurely if their output stream were not connected."
    }

    public static var helpSyntax: String? {
        """
        ►►──HOLE──►◄
        """
    }
}
