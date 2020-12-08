import Foundation

public final class Count: Stage {
    public enum Metric {
        case bytes
        case characters
        case words
        case lines
        case minLine
        case maxLine
    }

    private let metrics: [Metric]

    init(metrics: [Metric]) {
        self.metrics = metrics
    }

    public override func commit() throws {
        try ensureOnlyPrimaryInputStreamConnected()
        guard !isTertiaryOutputStreamConnected else { throw PipeError.unusedStreamConnected(direction: .output, streamNo: maxOutputStreamNo) }
    }

    override public func run() throws {
        var bytes = 0
        var chars = 0
        var words = 0
        var lines = 0
        var minLine = -1
        var maxLine = -1

        do {
            while true {
                let record = try peekto()

                bytes += record.utf8.count
                chars += record.count
                words += record.split(separator: " ", omittingEmptySubsequences: true).count
                lines += 1
                minLine = min(minLine == -1 ? record.count : minLine, record.count)
                maxLine = max(maxLine, record.count)

                if isSecondaryOutputStreamConnected {
                    try? output(record)
                }
                _ = try readto()
            }
        } catch _ as EndOfFile {
        }

        let counts: [Int] = metrics.map {
            switch $0 {
            case .bytes: return bytes
            case .characters: return chars
            case .words: return words
            case .lines: return lines
            case .minLine: return minLine
            case .maxLine: return maxLine
            }
        }
        let outputRecord = counts.map { "\($0)" }.joined(separator: " ")
        let outputStream: Int = isSecondaryOutputStreamConnected ? 1 : 0
        try output(outputRecord, streamNo: outputStream)
    }
}

extension Count: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "count" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        var metrics: [Metric] = []

        let keywords = [
            "CHARS": { Metric.characters },
            "CHARACTERS": { Metric.characters },
            "BYTES": { Metric.bytes },
            "WORDS": { Metric.words },
            "LINES": { Metric.lines },
            "MINline": { Metric.minLine },
            "MAXline": { Metric.maxLine },
        ]
        while true {
            if let metric = try args.onOptionalKeyword(keywords, throwsOnUnsupportedKeyword: true) {
                metrics.append(metric)
            } else {
                break
            }
        }

        if metrics.isEmpty {
            throw PipeError.requiredOperandMissing
        }

        try args.ensureNoRemainder()

        return Count(metrics: metrics)
    }

    public static var helpSummary: String? {
        """
        Counts the number of input lines, words, characters, or any combination thereof. It can
        also report the length of the shortest or longest record, or both (when there are no records,
        the shortest and longest records are reported as -1). It writes a line with the specified
        counts at end-of-file.

        For example, "literal aa bb cc | count bytes lines words | console" would output a record
        containing "9 1 3".

        Options:
            CHARACTERS - Outputs the number of unicode characters
            CHARS      - Synonym for CHARACTERS
            BYTES      - Outputs the number of bytes
            WORDS      - Outputs the number of blank separated words
            LINES      - Outputs the number of records
            MINline    - Outputs the length of the shortest line (-1 if there are no input records)
            MAXline    - Outputs the length of the longest line (-1 if there are no input records)
        """
    }

    public static var helpSyntax: String? {
        """
                   ┌──────────────┐
        ►►──COUNT──▼┬─CHARACTERS─┬┴──►◄
                    ├─CHARS──────┤
                    ├─BYTES──────┤
                    ├─WORDS──────┤
                    ├─LINES──────┤
                    ├─MINline────┤
                    └─MAXline────┘
        """
    }
}
