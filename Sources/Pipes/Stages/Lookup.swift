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
                if countedMasterRecord.count == 0 {
                    try output(countedMasterRecord.record, streamNo: 2)
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

        var maxCount: Int? = nil
        if args.nextKeywordMatches("MAXcount") {
            _ = try args.scanWord()
            maxCount = try args.scanWord().asNumber(allowNegative: false)
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
        Blah
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
