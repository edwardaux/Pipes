import Foundation

public final class Drop: Stage {
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
            try dropFirst(limit: limit)
        case .last(let limit):
            try dropLast(limit: limit)
        }

    }

    private func dropFirst(limit: Int) throws {
        var spare: String?
        var dropped = 0
        while dropped < limit {
            let record = try peekto()

            switch unit {
            case .lines:
                if isSecondaryOutputStreamConnected {
                    try? output(record, streamNo: 1)
                }
                dropped += 1
            case .characters:
                if dropped + record.count > limit {
                    // This will take us over the limit, so we need to split.
                    let splitIndex = limit - dropped
                    if isSecondaryOutputStreamConnected {
                        try? output(String(record.prefix(splitIndex)), streamNo: 1)
                    }
                    spare = String(record.dropFirst(splitIndex))
                } else {
                    if isSecondaryOutputStreamConnected {
                        try? output(record, streamNo: 1)
                    }
                }
                dropped += record.count
            case .bytes:
                let bytes = record.utf8
                if dropped + bytes.count > limit {
                    // This will take us over the limit, so we need to split.
                    let splitIndex = limit - dropped
                    if let outputString = String(bytes.prefix(splitIndex)) {
                        if isSecondaryOutputStreamConnected {
                            try? output(outputString, streamNo: 1)
                        }
                    } else {
                        throw PipeError.invalidString
                    }
                    if let spareString = String(bytes.dropFirst(splitIndex)) {
                        spare = spareString
                    } else {
                        throw PipeError.invalidString
                    }
                } else {
                    if isSecondaryOutputStreamConnected {
                        try? output(record, streamNo: 1)
                    }
                }
                dropped += bytes.count
            }

            _ = try readto()
        }
        if isSecondaryOutputStreamConnected {
            try sever(.output, streamNo: 1)
        }

        if let spare = spare {
            try output(spare)
        }
        try short(inputStreamNo: 0, outputStreamNo: 0)
    }

    private func dropLast(limit: Int) throws {
        let queue = FixedSizeQueue(size: limit, unit: unit)

        do {
            while true {
                let record = try peekto()

                let oldest = queue.append(record)
                for record in oldest {
                    try output(record)
                }

                _ = try readto()
            }
        } catch _ as EndOfFile {
            let (headRecords, tailRecords) = try queue.finalRecords()
            if isSecondaryOutputStreamConnected {
                for record in tailRecords {
                    try output(record, streamNo: 1)
                }
                try sever(.output, streamNo: 1)
            }
            for record in headRecords {
                try output(record)
            }
        }
    }
}

extension Drop: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "drop" ]
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

        return Drop(count: first ? .first(limit) : .last(limit), unit: unit)
    }

    public static var helpSummary: String? {
        """
        Discards the first n records and selects the remainder. drop LAST discards the last n records
        up to the last n and selects the last n records.

        When BYTES is omitted, drop FIRST copies the specified number of records to the secondary output
        stream, or discards them if the secondary output stream is not connected. It then passes the
        remaining input records to the primary output stream.

        drop LAST stores the specified number of records in a buffer. For each subsequent input record (if
        any), drop LAST writes the record that has been longest in the buffer to the primary output stream
        and then stores the input record in the buffer. At end-of-file, drop LAST flushes the records from
        the buffer into the secondary output stream (or discards them if the secondary output stream is not
        connected).

        When CHARACTERS, CHARS, or BYTES is specified, operation proceeds as described above, but rather
        than counting records, bytes are counted. Record boundaries are considered to be zero bytes wide.
        In general, the specified number of bytes will have been dropped in the middle of a record, which
        is then split after the last byte. When FIRST is specified the first part of the split record is
        discarded and the remainder is selected. When LAST is specified, the first part of the split record
        is selected and the second part is discarded. Care must be taken when using BYTES because the input
        string may contain multi-byte unicode glyphs and splitting on a byte boundary may result in an
        invalid string. This will result in a runtime error.

        Options:
            FIRST      - Drops the first 'n' records (or characters or bytes)
            LAST       - Drops the last 'n' records (or characters or bytes)
            number     - The number of records to drop. Defaults to 1. An asterisk signifies all records.
            LINES      - Count is based on records
            CHARACTERS - Count is based on unicode graphemes
            CHARS      - Synonym for CHARACTERS
            BYTES      - Count is based on the UTF-8 encoded bytes
        """
    }

    public static var helpSyntax: String? {
        """
                 ┌─FIRST─┐ ┌─1──────┐ ┌─LINES──────┐
        ►►──DROP─┼───────┼─┼────────┼─┼────────────┼──►◄
                 └─LAST──┘ ├─number─┤ ├─CHARACTERS─┤
                           └─*──────┘ ├─CHARS──────┤
                                      └─BYTES──────┘
        """
    }
}
