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
    private let maxCount: Int?
    private let pad: Character?
    private let anyCase: Bool
    private let detailRange: PipeRange
    private let masterRange: PipeRange
    private let outputOrder: OutputOrder

    public init(count: Bool = false, maxCount: Int? = nil, pad: Character? = nil, anyCase: Bool = false, detailRange: PipeRange = .full, masterRange: PipeRange = .full, outputOrder: OutputOrder = .detailMaster) {
        self.count = count
        self.maxCount = maxCount
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
        // TODO
//        self.count = count
//        self.maxCount = maxCount
        let masterRecords = try readtoAll(streamNo: 1)

        do {
            while true {
                let detail = try peekto()

                let masters = try masterRecords.filter { (master) in
                    var detailKey = try detail.extract(fromRange: detailRange)
                    var masterKey = try master.extract(fromRange: masterRange)

                    if let pad = pad {
                        detailKey = detailKey.aligned(alignment: .left, length: masterKey.count, pad: pad, truncate: false)
                        masterKey = masterKey.aligned(alignment: .left, length: detailKey.count, pad: pad, truncate: false)
                    }
                    if anyCase {
                        detailKey = detailKey.uppercased()
                        masterKey = masterKey.uppercased()
                    }

                    return detailKey == masterKey
                }

                if masters.count > 0 {
                    switch outputOrder {
                    case .detail:
                        try output(detail)
                    case .detailMaster:
                        try output(detail)
                        try output(masters.first!)
                    case .detailAllMaster(let pairwise):
                        if pairwise {
                            try masters.forEach {
                                try output(detail)
                                try output($0)
                            }
                        } else {
                            try output(detail)
                            try masters.forEach {
                                try output($0)
                            }
                        }
                    case .master:
                        try output(masters.first!)
                    case .masterDetail:
                        try output(masters.first!)
                        try output(detail)
                    case .allMaster:
                        try masters.forEach {
                            try output($0)
                        }
                    case .allMasterDetail(let pairwise):
                        if pairwise {
                            try masters.forEach {
                                try output($0)
                                try output(detail)
                            }
                        } else {
                            try masters.forEach {
                                try output($0)
                            }
                            try output(detail)
                        }
                    }
                } else {
                    if isSecondaryOutputStreamConnected {
                        try output(detail, streamNo: 1)
                    }
                }
                _ = try readto()
            }
        } catch _ as EndOfFile {
        }

        if isTertiaryOutputStreamConnected {
            //TODO unmatched masters

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

        return Lookup(count: count, maxCount: maxCount, pad: pad, anyCase: anyCase, detailRange: detailRange, masterRange: masterRange, outputOrder: outputOrder)
    }

    public static var helpSummary: String? {
        """
        Blah
        """
    }

    public static var helpSyntax: String? {
        """
                                                     ┌─NOPAD─────┐
        ►►──LOOKUP──┬───────┬──┬──────────────────┬──┼───────────┼──►
                    └─COUNT─┘  └─MAXcount──number─┘  └─PAD──xorc─┘

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
