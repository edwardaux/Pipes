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
    public func add(_ stage: Stage, label: String? = nil) throws -> Pipe {
        builderNodes.append(.stage(stage, label: label))
        if let label = label {
            if builderLabelRefCount[label] != nil {
                throw PipeError.labelAlreadyDeclared(label: label)
            }
            builderLabelRefCount[label] = 0
        }
        return self
    }

    public func add(label: String) throws -> Pipe {
        guard let prevRef = builderLabelRefCount[label] else {
            throw PipeError.labelNotDeclared(label: label)
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
