import Foundation

public final class Lookup: Stage {
    public enum OutputOrder {
        case detail
        case detailMaster
        case detailAllMaster(pairwise: Bool)
        case master
        case masterDetail
        case allMaster
        case allMasterDetail(pairwise: Bool)
    }

    private let count: Bool
    private let pad: Character?
    private let anyCase: Bool
    private let detailRange: PipeRange
    private let masterRange: PipeRange
    private let outputOrder: OutputOrder

    public init(count: Bool = false, pad: Character? = nil, anyCase: Bool = false, detailRange: PipeRange = .full, masterRange: PipeRange = .full, outputOrder: OutputOrder = .detailMaster) {
        self.count = count
        self.pad = pad
        self.anyCase = anyCase
        self.detailRange = detailRange
        self.masterRange = masterRange
        self.outputOrder = outputOrder
    }

    public override func commit() throws {
        try ensurePrimaryInputStreamConnected()
        try ensureSecondaryInputStreamConnected()
    }

    override public func run() throws {

        // Keeps track of how many times a master record has been referenced
        class CountedRecord {
            var count: Int = 0
            let record: String

            init(_ record: String) {
                self.record = record
            }
        }

        let rawMasterRecords = try readtoAll(streamNo: 1)
        let countedMasterRecords = rawMasterRecords.map { CountedRecord($0) }

        do {
            while true {
                let detail = try peekto()

                let matchedCountedMasters = try countedMasterRecords.filter { (countedMasterRecord) in
                    var detailKey = try detail.extract(fromRange: detailRange)
                    var masterKey = try countedMasterRecord.record.extract(fromRange: masterRange)

                    if let pad = pad {
                        detailKey = detailKey.aligned(alignment: .left, length: masterKey.count, pad: pad, truncate: false)
                        masterKey = masterKey.aligned(alignment: .left, length: detailKey.count, pad: pad, truncate: false)
                    }
                    if anyCase {
                        detailKey = detailKey.uppercased()
                        masterKey = masterKey.uppercased()
                    }

                    let matched = detailKey == masterKey
                    if matched {
                        countedMasterRecord.count += 1
                    }
                    return matched
                }

                if matchedCountedMasters.count > 0 {
                    // The current detail record matched at least one master, so we'll write
                    // the appropriate detail/master records into primary output stream
                    let matchedMasters = matchedCountedMasters.map { $0.record }

                    switch outputOrder {
                    case .detail:
                        try output(detail)
                    case .detailMaster:
                        try output(detail)
                        try output(matchedMasters.first!)
                    case .detailAllMaster(let pairwise):
                        if pairwise {
                            try matchedMasters.forEach {
                                try output(detail)
                                try output($0)
                            }
                        } else {
                            try output(detail)
                            try matchedMasters.forEach {
                                try output($0)
                            }
                        }
                    case .master:
                        try output(matchedMasters.first!)
                    case .masterDetail:
                        try output(matchedMasters.first!)
                        try output(detail)
                    case .allMaster:
                        try matchedMasters.forEach {
                            try output($0)
                        }
                    case .allMasterDetail(let pairwise):
                        if pairwise {
                            try matchedMasters.forEach {
                                try output($0)
                                try output(detail)
                            }
                        } else {
                            try matchedMasters.forEach {
                                try output($0)
                            }
                            try output(detail)
                        }
                    }
                } else {
                    // No match for this detail record, so writing to secondary output
                    // stream if connected
                    if isSecondaryOutputStreamConnected {
                        try output(detail, streamNo: 1)
                    }
                }
                _ = try readto()
            }
        } catch _ as EndOfFile {
        }

        if isTertiaryOutputStreamConnected {
            // If the tertiary output stream is connected, we write all the master records
            // that are unmatched
            for countedMasterRecord in countedMasterRecords {
                if count {
                    // If we're counting, we output a count+record for every master
                    let alignedCount = "\(countedMasterRecord.count)".aligned(alignment: .right, length: 10, pad: " ", truncate: true)
                    try output("\(alignedCount)\(countedMasterRecord.record)", streamNo: 2)
                } else {
                    // If we're not counting, then we only output unmatched master records
                    if countedMasterRecord.count == 0 {
                        try output(countedMasterRecord.record, streamNo: 2)
                    }
                }
            }

        }
    }
}

extension Lookup: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "lookup" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        var count = false
        if args.nextKeywordMatches("COUNT") {
            _ = try args.scanWord()
            count = true
        }

        var pad: Character? = nil
        if args.nextKeywordMatches("NOPAD") {
            _ = try args.scanWord()
        } else if args.nextKeywordMatches("PAD") {
            _ = try args.scanWord()
            pad = try args.scanWord().asXorC()
        }

        var anyCase = false
        if args.nextKeywordMatches("ANYcase") {
            _ = try args.scanWord()
            anyCase = true
        }

        let detailRange: PipeRange
        if let range = args.peekRange() {
            _ = try args.scanRange()
            detailRange = range
        } else {
            detailRange = .full
        }
        let masterRange: PipeRange
        if let range = args.peekRange() {
            _ = try args.scanRange()
            masterRange = range
        } else {
            masterRange = detailRange
        }

        var outputOrder: OutputOrder = .detailMaster
        if args.nextKeywordMatches("DETAIL") {
            _ = try args.scanWord()
            if args.nextKeywordMatches("MASTER") {
                _ = try args.scanWord()
                outputOrder = .detailMaster
            } else if args.nextKeywordMatches("ALLMASTER") {
                _ = try args.scanWord()
                if args.nextKeywordMatches("PAIRWISE") {
                    _ = try args.scanWord()
                    outputOrder = .detailAllMaster(pairwise: true)
                } else {
                    outputOrder = .detailAllMaster(pairwise: false)
                }
            } else {
                outputOrder = .detail
            }
        } else if args.nextKeywordMatches("MASTER") {
            _ = try args.scanWord()
            if args.nextKeywordMatches("DETAIL") {
                _ = try args.scanWord()
                outputOrder = .masterDetail
            } else {
                outputOrder = .master
            }
        } else if args.nextKeywordMatches("ALLMASTER") {
            _ = try args.scanWord()
            if args.nextKeywordMatches("DETAIL") {
                _ = try args.scanWord()
                if args.nextKeywordMatches("PAIRWISE") {
                    _ = try args.scanWord()
                    outputOrder = .allMasterDetail(pairwise: true)
                } else {
                    outputOrder = .allMasterDetail(pairwise: false)
                }
            } else {
                outputOrder = .allMaster
            }
        }

        try args.ensureNoRemainder()

        return Lookup(count: count, pad: pad, anyCase: anyCase, detailRange: detailRange, masterRange: masterRange, outputOrder: outputOrder)
    }

    public static var helpSummary: String? {
        """
        lookup processes an input stream of detail records against a reference that contains master
        records, comparing a key field:

            * When a detail record has the same key as a master record, the detail record or the master
              record (or both) are passed to the primary output stream.
            * When a detail record has a key that is not present in any master record, it is passed to
              the secondary output stream.
            * When all detail records have been processed, master records are passed to the tertiary
              output stream. If COUNT is specified, all master records are written; each one is prefixed
              by the count of matching detail records. If COUNT is omitted, only those master records for
              which there was no corresponding detail record are written.

        The reference is comprised of records from the secondary input stream; this stream is read to
        end-of-file before processing detail records. When ALLMASTERS is specified, the reference contains
        all records from the secondary input stream, including those that have duplicate keys; when ALLMASTERS
        is omitted, lookup uses the first record that has a particular key in the reference.

        The secondary input stream is read and stored as the initial reference before the primary input
        stream is read. When ALLMASTER is specified, all master records are compared. When a record is read
        on the primary input stream, the contents of the first input range are used as the key. The key field
        of this detail record is looked up in the reference. When there is no matching master record, the
        detail record is passed to the secondary output stream (if it is connected). When there is a matching
        master record, one or more records are written to the primary output stream in the order specified by
        the keywords DETAIL, MASTER, ALLMASTER, or PAIRWISE. The default is to write the detail record followed
        by the master record.

        At end-of-file on the primary input stream, all streams other than the tertiary output stream are
        severed. The contents of the reference (originally from the secondary input stream) are then written
        to the tertiary output stream (if it is connected). Without the COUNT option, only unreferenced master
        records are written (those not matched by at least one detail record). When COUNT is specified, all
        master records are written to the tertiary output stream; they have a 10-byte prefix containing the
        count of primary input records that matched the key of the master record. Unreferenced records have a
        count of zero.

        Options:
            COUNT                     - A count of matching details is kept with the master record. The count
                                        is prefixed to the master record before it is written to the tertiary
                                        output stream. When COUNT is omitted, only master records that have a
                                        count of zero are written to these two output streams.
            UNIQUE                    - The first record with a given keys is retained. Subsequent records with
                                        duplicate keys are written to the secondary stream if connected
                                        (discarded otherwise).
            PAD/NOPAD                 - The keyword NOPAD specifies that key fields that are partially present
                                        must have the same length to be considered equal; this is the default.
                                        The keyword PAD specifies a pad character that is used to extend the
                                        shorter of two key fields.
            ANYcase                   - Ignore case when comparing.
            inputRange                - An input range to use as a key value
            DETAIL                    - Write only detail records to the primary output stream.
            DETAIL MASTER             - Duplicate master records are discarded. Write the detail record followed
                                        by the matching reference to the primary output stream.
            DETAIL ALLMASTER          - Duplicate master records are kept. Write the detail record followed by
                                        all matching masters to the primary output stream.
            DETAIL ALLMASTER PAIRWISE - Duplicate master records are kept. For each master record having the
                                        selected key, write a copy of the detail record followed by the master
                                        record to the primary output stream.
            MASTER                    - Duplicate master records are discarded. Write the matching reference to
                                        the primary output stream. The matching detail record is discarded.
            MASTER DETAIL             - Duplicate master records are discarded. Write the matching reference
                                        followed by the detail record to the primary output stream.
            ALLMASTER                 - Duplicate master records are kept. Write all matching master records to
                                        the primary output stream. The matching detail record is discarded.
            ALLMASTER DETAIL          - Duplicate master records are kept. Write all matching master records
                                        followed by the detail record to the primary output stream.
            ALLMASTER DETAIL PAIRWISE - Duplicate master records are kept. For each master record having the
                                        selected key, write the master record followed by a copy of the detail
                                        record to the primary output stream.
        """
    }

    public static var helpSyntax: String? {
        """
                               ┌─NOPAD─────┐
        ►►──LOOKUP──┬───────┬──┼───────────┼──►
                    └─COUNT─┘  └─PAD──xorc─┘

        ►──┬─────────┬──┬────────────────────────────┬──►
           └─ANYcase─┘  └─inputRange──┬────────────┬─┘
                                      └─inputRange─┘

           ┌─DETAIL──MASTER──────────────────────┐
        ►──┼─────────────────────────────────────┼──►◄
           ├─DETAIL──────────────────────────────┤
           ├─DETAIL──ALLMASTER──┬──────────┬─────┤
           │                    └─PAIRWISE─┘     │
           ├─MASTER──────────────────────────────┤
           ├─MASTER──DETAIL──────────────────────┤
           └─ALLMASTER──┬──────────────────────┬─┘
                        └─DETAIL──┬──────────┬─┘
                                  └─PAIRWISE─┘
        """
    }
}
