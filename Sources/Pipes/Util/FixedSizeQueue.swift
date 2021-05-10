public enum TakeDropUnit {
    case lines
    case characters
    case bytes

    func calcLength(_ string: String) -> Int {
        switch self {
        case .lines: return 1
        case .characters: return string.count
        case .bytes: return string.utf8.count
        }
    }

    func split(_ string: String, at index: Int) throws -> (String, String) {
        switch self {
        case .lines:
            return ("", "")
        case .characters:
            return (String(string.prefix(index)), String(string.dropFirst(index)))
        case .bytes:
            let bytes = string.utf8
            if let head = String(bytes.prefix(index)), let tail = String(bytes.dropFirst(index)) {
                return (head, tail)
            } else {
                throw PipeError.invalidString
            }
        }
    }
}

class FixedSizeQueue {
    private let unit: TakeDropUnit
    private let size: Int
    private var records: [String]

    init(size: Int, unit: TakeDropUnit) {
        self.size = size
        self.unit = unit
        self.records = []
    }

    func append(_ record: String) -> [String] {
        records.append(record)

        var poppedRecords = [String]()
        var remaining = [String]()

        // If we only need to keep 0, then we already have enough no
        // matter what. Otherwise, we assume we don't have enough yet.
        var haveEnough = size == 0
        var total = 0
        for r in records.reversed() {
            if haveEnough {
                poppedRecords.append(r)
            } else {
                remaining.insert(r, at: 0)
            }

            total += unit.calcLength(r)
            if total >= size {
                haveEnough = true
            }
        }
        records = remaining
        return poppedRecords
    }

    func finalRecords() throws -> ([String], [String]) {
        var headRecords = [String]()
        var tailRecords = [String]()
        var total = 0
        for record in records.reversed() {
            let length = unit.calcLength(record)
            if total + length <= size {
                tailRecords.insert(record, at: 0)
            } else {
                let need = size - total
                let (head, tail) = try unit.split(record, at: length - need)
                tailRecords.insert(tail, at: 0)
                headRecords.append(head)
            }
            total += length
        }
        return (headRecords, tailRecords)
    }
}
