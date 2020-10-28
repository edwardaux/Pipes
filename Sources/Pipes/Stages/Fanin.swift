import Foundation

public final class Fanin: Stage {
    private let inputStreamNos: [Int]

    init(inputStreamNos: [Int]) {
        self.inputStreamNos = inputStreamNos
    }

    public override func commit() throws {
        try ensureOnlyPrimaryOutputStreamConnected()

        let streamNos = inputStreamNos.count == 0 ? Array(0...maxInputStreamNo) : inputStreamNos
        for streamNo in streamNos {
            if streamState(.input, streamNo: streamNo) == .notDefined {
                throw PipeError.streamNotDefined(direction: .input, streamNo: streamNo)
            }
        }
    }

    override public func run() throws {
        let streamNos = inputStreamNos.count == 0 ? Array(0...maxInputStreamNo) : inputStreamNos
        for streamNo in streamNos {
            do {
                while true {
                    let record = try peekto(streamNo: streamNo)
                    try output(record)
                    _ = try readto(streamNo: streamNo)
                }
            } catch _ as EndOfFile {
            }
        }
    }
}

extension Fanin: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "fanin" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        var streamNos = [Int]()
        while let streamNo = try args.scanStreamIdentifier() {
            if !streamNos.contains(streamNo) {
                streamNos.append(streamNo)
            }
        }
        return Fanin(inputStreamNos: streamNos)
    }

    public static var helpSummary: String? {
        """
        Passes all records on the primary input stream to the primary output stream, then all records on
        the secondary input stream to the primary output stream, and so on.

        Options:
            stream - An override list of blank separated stream identifiers that define the order that
                     the streams will be read from.
        """
    }

    public static var helpSyntax: String? {
        """
        ►►──FANIN──┬────────────┬──►◄
                   │ ┌────────┐ │
                   └─▼─stream─┴─┘
        """
    }
}
