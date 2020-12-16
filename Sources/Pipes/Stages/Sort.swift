import Foundation

public final class Sort: Stage {
    public enum Mode {
        case normal
        case count
        case unique
    }

    public struct Key {
        public static let `default` = Key(range: .full, ascending: true, pad: nil)

        public let range: PipeRange
        public let ascending: Bool
        public let pad: Character?

        func inIncreasingOrder(lhs: String, rhs: String, anyCase: Bool, pad: Character?) throws -> Bool {
            var lhsKey = try lhs.extract(fromRange: range)
            var rhsKey = try rhs.extract(fromRange: range)
            if let pad = pad {
                if lhsKey.count < rhsKey.count {
                    lhsKey = lhsKey.aligned(alignment: .left, length: rhsKey.count, pad: pad, truncate: false)
                } else if rhsKey.count < lhsKey.count {
                    rhsKey = rhsKey.aligned(alignment: .left, length: lhsKey.count, pad: pad, truncate: false)
                }
            }
            if anyCase {
                lhsKey = lhsKey.uppercased()
                rhsKey = rhsKey.uppercased()
            }
            return ascending ? lhsKey < rhsKey : lhsKey > rhsKey
        }
    }

    private let mode: Mode
    private let anyCase: Bool
    private let defaultPad: Character?
    private let keys: [Key]

    init(mode: Mode = .normal, anyCase: Bool = false, pad: Character? = nil, keys: [Key] = [Key.default]) {
        self.mode = mode
        self.anyCase = anyCase
        self.defaultPad = pad
        self.keys = keys.isEmpty ? [Key.default] : keys
    }

    public override func commit() throws {
        try ensurePrimaryInputStreamConnected()
        try ensureOnlyPrimaryInputStreamConnected()
    }

    override public func run() throws {
        var records = [String]()
        do {
            while true {
                records.append(try readto())
            }
        } catch _ as EndOfFile {
        }

        switch mode {
        case .normal:
            let sorted = try records.stableSorted { (lhs, rhs) in
                for key in keys {
                    if try key.inIncreasingOrder(lhs: lhs, rhs: rhs, anyCase: anyCase, pad: key.pad ?? defaultPad) { return true }
                    if try key.inIncreasingOrder(lhs: rhs, rhs: lhs, anyCase: anyCase, pad: key.pad ?? defaultPad) { return false }
                }
                return false
            }
            for record in sorted {
                try output(record)
            }
        case .count:
            // TODO implement count
            break
        case .unique:
            // TODO implement unique
            break
        }
    }
}

extension Sort: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "sort" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        var count = false
        var unique = false
        if args.nextKeywordMatches("COUNT") {
            _ = try args.scanWord()
            count = true
        } else if args.nextKeywordMatches("UNIQue") {
            _ = try args.scanWord()
            unique = true
        }

        var pad: Character?
        if args.nextKeywordMatches("PAD") {
            _ = try args.scanWord()
            pad = try args.scanWord().asXorC()
        } else if args.nextKeywordMatches("NOPAD") {
            _ = try args.scanWord()
        }

        var anyCase = false
        if args.nextKeywordMatches("ANYcase") {
            _ = try args.scanWord()
            anyCase = true
        }

        var keys: [Key] = []
        if args.nextKeywordMatches("Ascending") {
            _ = try args.scanWord()
            keys.append(Key(range: .full, ascending: true, pad: pad))
        } else if args.nextKeywordMatches("Descending") {
            _ = try args.scanWord()
            keys.append(Key(range: .full, ascending: false, pad: pad))
        } else {
            while true {
                if let range = args.peekRange() {
                    _ = try args.scanRange()

                    var ascending = true
                    if args.nextKeywordMatches("Ascending") {
                        _ = try args.scanWord()
                    } else if args.nextKeywordMatches("Descending") {
                        _ = try args.scanWord()
                        ascending = false
                    }

                    var pad: Character?
                    if args.nextKeywordMatches("PAD") {
                        _ = try args.scanWord()
                        pad = try args.scanWord().asXorC()
                    } else if args.nextKeywordMatches("NOPAD") {
                        _ = try args.scanWord()
                    }

                    keys.append(Key(range: range, ascending: ascending, pad: pad))
                } else {
                    break
                }
            }
        }

        try args.ensureNoRemainder()

        let mode: Mode = count ? .count : unique ? .unique : .normal
        return Sort(mode: mode, anyCase: anyCase, pad: pad, keys: keys)
    }

    public static var helpSummary: String? {
        """
        Reads all input records and then writes them in a specified order.

        Note in particular that sort performs a binary comparison of key fields from left to right. Thus,
        numeric fields will be sorted “correctly” only when the data to be compared are aligned to the
        right within sort fields of equal size. (Since padding is applied on the right hand side only.)
        Thus, a numeric sort is unlikely to “work”.

        In the case where the values of the sorting key(s) are equal, the original order of the records
        is preserved. ie. the sorting algorithm is stable.

        UNIQUE orders the file and discards records with duplicate keys. Refer to lookup for an example
        of extracting all unique records from a file without altering their order.

        Options:
            COUNT      - A 10-character count of the number of occurrences of the key is prefixed to the
                         output record. Keys are sorted per specification with additional keys beyond the
                         first matching record being discarded.
            UNIQUE     - The first record with a given keys is retained. Subsequent records with duplicate
                         keys are discarded
            PAD/NOPAD  - The keyword NOPAD specifies that key fields that are partially present must have
                         the same length to be considered equal; this is the default. The keyword PAD
                         specifies a pad character that is used to extend the shorter of two key fields.
            ANYcase    - Ignore case when comparing.
            inputRange - An input range to use as a key value
            Ascending  - specifies the number of unconnected streams that will cause fanout to terminate.
            Descending - specifies the number of unconnected streams that will cause fanout to terminate.
                         The number 1 is equivalent to ANYEOF.

        Important: SORT will buffer all records in-memory which may be expensive for large input sources.
        """
    }

    public static var helpSyntax: String? {
        """
                              ┌─NOPAD─────┐
        ►►──SORT──┬────────┬──┼───────────┼──┬─────────┬──►
                  ├─COUNT──┤  └─PAD──xorc─┘  └─ANYcase─┘
                  └─UNIQue─┘

           ┌─Ascending─────────────────────────────────────┐
        ►──┼───────────────────────────────────────────────┼──►◄
           ├─Descending────────────────────────────────────┤
           │ ┌───────────────────────────────────────────┐ │
           │ │             ┌─Ascending──┐  ┌─NOPAD─────┐ │ │
           └─▼─inputRange──┼────────────┼──┼───────────┼─┴─┘
                           └─Descending─┘  └─PAD──xorc─┘
        """
    }
}

extension Sequence {
  fileprivate func stableSorted(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> [Element] {
    return try enumerated().sorted { a, b -> Bool in
        try areInIncreasingOrder(a.element, b.element) || (a.offset < b.offset && !areInIncreasingOrder(b.element, a.element))
    }.map { $0.element }
  }
}