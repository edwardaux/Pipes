import Foundation

public final class Take: Stage {
    public enum Count {
        case first(Int)
        case last(Int)
    }

    private let count: Count
    private let unit: TakeDropUnit

    public init(count: Count = .first(1), unit: TakeDropUnit = .lines) {
        self.count = count
        self.unit = unit
    }

    public override func commit() throws {
        try ensurePrimaryInputStreamConnected()
        try ensureOnlyPrimaryInputStreamConnected()
    }

    override public func run() throws {
        switch count {
        case .first(let limit):
            try takeFirst(limit: limit)
        case .last(let limit):
            try takeLast(limit: limit)
        }

    }

    private func takeFirst(limit: Int) throws {
        var spare: String?
        var taken = 0
        while taken < limit {
            let record = try peekto()

            switch unit {
            case .lines:
                try output(record)
                taken += 1
            case .characters:
                if taken + record.count > limit {
                    // This will take us over the limit, so we need to split.
                    let splitIndex = limit - taken
                    try output(String(record.prefix(splitIndex)))
                    spare = String(record.dropFirst(splitIndex))
                } else {
                    try output(record)
                }
                taken += record.count
            case .bytes:
                let bytes = record.utf8
                if taken + bytes.count > limit {
                    // This will take us over the limit, so we need to split.
                    let splitIndex = limit - taken
                    if let outputString = String(bytes.prefix(splitIndex)) {
                        try output(outputString)
                    } else {
                        throw PipeError.invalidString
                    }
                    if let spareString = String(bytes.dropFirst(splitIndex)) {
                        spare = spareString
                    } else {
                        throw PipeError.invalidString
                    }
                } else {
                    try output(record)
                }
                taken += bytes.count
            }

            _ = try readto()
        }
        if isSecondaryOutputStreamConnected {
            try sever(.output)
            if let spare = spare {
                try output(spare, streamNo: 1)
            }
            try short(inputStreamNo: 0, outputStreamNo: 1)
        }
    }

    private func takeLast(limit: Int) throws {
        let queue = FixedSizeQueue(size: limit, unit: unit)

        do {
            while true {
                let record = try peekto()

                let oldest = queue.append(record)
                if isSecondaryOutputStreamConnected {
                    for record in oldest {
                        try output(record, streamNo: 1)
                    }
                }

                _ = try readto()
            }
        } catch _ as EndOfFile {
            let (headRecords, tailRecords) = try queue.finalRecords()
            if isSecondaryOutputStreamConnected {
                for record in headRecords {
                    try output(record, streamNo: 1)
                }
                try sever(.output, streamNo: 1)
            }
            for record in tailRecords {
                try output(record)
            }
        }
    }
}

extension Take: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "take" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        var first = true
        if args.nextKeywordMatches("FIRST") {
            _ = try args.scanWord()
            first = true
        } else if args.nextKeywordMatches("LAST") {
            _ = try args.scanWord()
            first = false
        }

        var limit = 1
        if let word = args.peekWord() {
            if !word.matchesKeyword("LINEs", "CHARACTERs", "CHARs", "BYTEs") {
                limit = try word.asNumberOrAsterisk()
                _ = try args.scanWord()
            }
        }

        var unit = TakeDropUnit.lines
        if let word = args.peekWord() {
            if word.matchesKeyword("LINEs") {
                _ = try args.scanWord()
                unit = .lines
            } else if word.matchesKeyword("CHARACTERs", "CHARs") {
                _ = try args.scanWord()
                unit = .characters
            } else if word.matchesKeyword("BYTEs") {
                _ = try args.scanWord()
                unit = .bytes
            }
        }

        try args.ensureNoRemainder()

        return Take(count: first ? .first(limit) : .last(limit), unit: unit)
    }

    public static var helpSummary: String? {
        """
        Selects the first n records and discards the remainder. take LAST discards records up to
        the last n and selects the last n records.

        When BYTES is omitted, take FIRST copies the specified number of records to the primary
        output stream, or discards them if the primary output stream is not connected. If the secondary
        output stream is defined, take FIRST then passes the remaining input records to the secondary
        output stream.

        take LAST stores the specified number of records in a buffer. For each subsequent input record
        (if any), take LAST writes the record that has been longest in the buffer to the secondary
        output stream (or discards it if the secondary output stream is not connected). The input record
        is then stored in the buffer. At end-of-file take LAST flushes the records from the buffer into
        the primary output stream (or discards them if the primary output stream is not connected).

        When CHARACTERS, CHARS, or BYTES are specified, operation proceeds as described above, but rather
        than counting records, chars or bytes are counted. Record boundaries are considered to be zero
        width. In general, the specified number of chars/bytes will have been taken in the middle of a
        record, which is then split after the last char/byte. When FIRST is specified the first part of
        the split record is selected and the remainder is discarded. When LAST is specified, the first part
        of the split record is discarded and the second part is selected. Care must be taken when using
        BYTES because the input string may contain multi-byte unicode glyphs and splitting on a byte
        boundary may result in an invalid string. This will result in a runtime error.

        Options:
            FIRST      - Takes the first 'n' records (or characters or bytes)
            LAST       - Takes the last 'n' records (or characters or bytes)
            number     - The number of records to take. Defaults to 1. An asterisk signifies all records.
            LINES      - Count is based on records
            CHARACTERS - Count is based on unicode graphemes
            CHARS      - Synonym for CHARACTERS
            BYTES      - Count is based on the UTF-8 encoded bytes
        """
    }

    public static var helpSyntax: String? {
        """
                 ┌─FIRST─┐ ┌─1──────┐ ┌─LINES──────┐
        ►►──TAKE─┼───────┼─┼────────┼─┼────────────┼──►◄
                 └─LAST──┘ ├─number─┤ ├─CHARACTERS─┤
                           └─*──────┘ ├─CHARS──────┤
                                      └─BYTES──────┘
        """
    }
}
