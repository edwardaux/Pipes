import Foundation

internal enum Node {
    case stage(Stage, label: String?)
    case label(String, streamNo: UInt)
    case end

    var stage: Stage? {
        switch self {
        case .stage(let stage, _): return stage
        case .label: return nil
        case .end: return nil
        }
    }

    var label: String? {
        switch self {
        case .stage(_, let label): return label
        case .label(let label, _): return label
        case .end: return nil
        }
    }

    var isEnd: Bool {
        switch self {
        case .end: return true
        default: return false
        }
    }

    var streamNo: UInt {
        switch self {
        case .stage: return 0
        case .label(_, let streamNo): return streamNo
        case .end: return 0
        }
    }
}

extension Pipe {
    public func add(_ stage: Stage, label: String? = nil) -> Pipe {
        builderNodes.append(.stage(stage, label: label))
        if let label = label {
            builderLabelRefCount[label] = 0
        }
        return self
    }

    public func add(label: String) -> Pipe {
        guard let prevRef = builderLabelRefCount[label] else {
            // TODO error handling
            fatalError("Referencing \(label) before definition")
        }

        let streamNo = prevRef + 1
        builderLabelRefCount[label] = streamNo
        builderNodes.append(.label(label, streamNo: streamNo))
        return self
    }

    public func end() -> Pipe {
        builderNodes.append(.end)
        return self
    }
}
