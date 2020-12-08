import Foundation

public final class Fanout: Stage {
    public enum Stop {
        case allEOF
        case anyEOF
        case streamCount(Int)

        func maxDisconnectedStreamCount(maxOutputStreamNo: Int) -> Int {
            switch self {
                case .allEOF: return maxOutputStreamNo + 1
                case .anyEOF: return 1
                case .streamCount(let count): return count
            }
        }
    }

    private let stop: Stop

    init(stop: Stop = .allEOF) {
        self.stop = stop
    }

    public override func commit() throws {
        try ensurePrimaryInputStreamConnected()
        try ensureOnlyPrimaryInputStreamConnected()
    }

    override public func run() throws {
        let maxDisconnectedStreamCount = stop.maxDisconnectedStreamCount(maxOutputStreamNo: maxOutputStreamNo)

        while true {
            var disconnectedCount = 0
            let record = try peekto()
            for i in 0...maxOutputStreamNo {
                do {
                    try output(record, streamNo: i)
                } catch _ as EndOfFile {
                    disconnectedCount += 1
                }
            }
            _ = try readto()

            if disconnectedCount >= maxDisconnectedStreamCount {
                break
            }
        }
    }
}

extension Fanout: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "fanout" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let stop: Stop = try args.onOptionalKeyword(
            [
                "STOP": {
                    let word = try args.scanWord()
                    if word.matchesKeyword("ALLEOF") {
                        return .allEOF
                    } else if word.matchesKeyword("ANYEOF") {
                        return .anyEOF
                    } else {
                        return .streamCount(try word.asNumber())
                    }
                }
            ],
            throwsOnUnsupportedKeyword: true
        ) ?? Stop.allEOF

        try args.ensureNoRemainder()

        return Fanout(stop: stop)
    }

    public static var helpSummary: String? {
        """
        For each input record, fanout writes a copy to the primary output stream, the secondary output
        stream, and so on.

        Options:
            STOP ALLEOF - Specifies that fanout should continue as long as at least one output stream
                          is connected. (default)
            STOP ANYEOF - Specifies that fanout should stop as soon as it determines that an output
                          stream is no longer connected.
            STOP number - Specifies the number of unconnected streams that will cause fanout to terminate.
                          The number 1 is equivalent to ANYEOF.
        """
    }

    public static var helpSyntax: String? {
        """
                    ┌─STOP──ALLEOF───┐
        ►►──FANOUT──┼────────────────┼──►◄
                    └─STOP─┬─ANYEOF──┤
                           └─number──┘
        """
    }
}
