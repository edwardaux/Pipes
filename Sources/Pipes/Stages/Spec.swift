import Foundation

public final class Spec: Stage {
    private let items: [Item]

    private var pad: Character = " "
    private var recno: Int = 0
    private var timestamp: Date = Date()

    init(_ items: Item...) {
        self.items = items
    }

    public override func commit() throws {
        try ensureOnlyPrimaryOutputStreamConnected()
    }

    override public func run() throws {
        while true {
            let inputRecord = try peekto()
            var outputRecord = ""
            for item in items {
                switch item {
                case .pad(let char):
                    pad = char
                case .field(let input, let strip, let conversion, let output, let alignment):
                    outputRecord = try evaluate(
                        input: input,
                        strip: strip,
                        conversion: conversion,
                        recno: recno,
                        timestamp: timestamp,
                        output: output,
                        alignment: alignment,
                        pad: pad,
                        inputRecord:
                        inputRecord,
                        outputSoFar: outputRecord
                    )
                }
            }
            try output(outputRecord)
            _ = try readto()
            recno += 1
        }
    }

    private func evaluate(input: Item.Input, strip: Bool, conversion: Conversion?, recno: Int, timestamp: Date, output: Item.Output, alignment: Alignment, pad: Character, inputRecord: String, outputSoFar: String) throws -> String {
        var inputString = try input.extract(from: inputRecord, recno: recno, timestamp: timestamp)
        if strip {
            inputString = inputString.trimmingCharacters(in: .whitespaces)
        }
        if let conversion = conversion {
            inputString = conversion.convert(inputString)
        }
        return try output.place(inputString, outputSoFar: outputSoFar, alignment: alignment, pad: pad)
    }

    public enum Item {
        public enum Input {
            case range(PipeRange)
            case literal(String)
            case number(start: Int = 1, by: Int = 1)
            case timestamp(formatter: DateFormatter)

            func extract(from string: String, recno: Int, timestamp: Date) throws -> String {
                switch self {
                case .range(let range):
                    return try string.extract(fromRange: range)
                case .literal(let literal):
                    return literal
                case .number(let start, let by):
                    return "\(start + (recno * by))"
                case .timestamp(let formatter):
                    return formatter.string(from: timestamp)
                }
            }
        }
        public enum Output {
            case next(length: Int? = nil)
            case nextWord(length: Int? = nil)
            case offset(Int)
            case range(PipeRange)

            func place(_ string: String, outputSoFar: String, alignment: Alignment, pad: Character) throws -> String {
                let length = try calculateLength(string: string)

                var adjusted = string.aligned(alignment: alignment, length: length, pad: pad)
                var metrics = try calculateMetrics(outputSoFar: outputSoFar, string: adjusted)

                if case .nextWord = self {
                    adjusted = adjusted.isEmpty ? adjusted : " \(adjusted)"
                    metrics = (start: metrics.start, length: metrics.length + 1)
                }

                return outputSoFar.insertString(string: adjusted, start: metrics.start)
            }

            func calculateLength(string: String) throws -> Int {
                switch self {
                case .next(let length):
                    return length ?? string.count
                case .nextWord(let length):
                    return length ?? string.count
                case .offset:
                    return string.count
                case .range(let range):
                    if range.end == .end {
                        throw PipeError.outputRangeEndInvalid
                    }
                    return range.end - range.start + 1
                }
            }

            func calculateMetrics(outputSoFar: String, string: String) throws -> (start: Int, length: Int) {
                let length = try calculateLength(string: string)

                switch self {
                case .next:
                    return (start: outputSoFar.count + 1, length: length)
                case .nextWord:
                    return (start: outputSoFar.count + 1, length: length)
                case .offset(let offset):
                    return (start: offset, length: length)
                case .range(let range):
                    return (start: range.start, length: length)
                }
            }
        }

        case pad(Character)
        case field(input: Input, strip: Bool = false, conversion: Conversion? = nil, output: Output, alignment: Alignment = .left)
    }
}

extension Spec: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "spec" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        return Spec()
    }

    public static var helpSummary: String? {
        """
        Builds output records from the contents of input records and literal fields. It does this
        by processing a list of specifications (a specification list) for each input record.
        """
    }

    public static var helpSyntax: String? {
        """
                  ┌──────────────┐
        ►►──SPEC──▼─┬─┤ field ├┬─┴──►◄
                    └─PAD xorc─┘

        field:

        ├──┬─inputRange─────────────────────────────────────┬──┬───────┬──►
           ├─┬─NUMBER─┬──┬───────────────┬──┬─────────────┬─┤  └─STRIP─┘
           │ └─RECNO──┘  └─FROM──snumber─┘  └─BY──snumber─┘ │
           ├─TIMEstamp───┬────────┬─────────────────────────┤
           │             └─format─┘                         │
           └─delimitedString────────────────────────────────┘

        ►──┬────────────────┬──┬─┬─Next─────┬──┬───────────┬─┬──┬────────┬──┤
           └─┤ conversion ├─┘  │ └─NEXTWord─┘  └─.──number─┘ │  ├─Left───┤
                               ├─number──────────────────────┤  ├─Center─┤
                               └─range───────────────────────┘  └─Right──┘
        """
    }
}
