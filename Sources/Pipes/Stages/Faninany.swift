import Foundation

public final class Faninany: Stage {
    public override func commit() throws {
        try ensureOnlyPrimaryOutputStreamConnected()
    }

    override public func run() throws {
        do {
            while true {
                let record = try peekto(streamNo: Stream.ANY)
                try output(record)
                _ = try readto(streamNo: Stream.ANY)
            }
        } catch _ as EndOfFile {
        }
    }
}

extension Faninany: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "faninany" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        return Faninany()
    }

    public static var helpSummary: String? {
        """
        Copies records from its input streams to the primary output stream. It reads records from whatever
        input stream has one ready. It is unspecified which stream is read next when two or more input
        streams have a record ready.
        """
    }

    public static var helpSyntax: String? {
        """
        ►►──FANINANY──►◄
        """
    }
}
