import Foundation

class Builder {
    private var builderNodes: [Node] = []
    private var builderLabelRefCount: [String: Int] = [:]

    public func add(_ stage: Stage, label: String? = nil) throws {
        builderNodes.append(.stage(stage, label: label))
        if let label = label {
            if builderLabelRefCount[label] != nil {
                throw PipeError.labelAlreadyDeclared(label: label)
            }
            builderLabelRefCount[label] = 0
        }
    }

    public func add(label: String) throws {
        guard let prevRef = builderLabelRefCount[label] else {
            throw PipeError.labelNotDeclared(label: label)
        }

        let streamNo = prevRef + 1
        builderLabelRefCount[label] = streamNo
        builderNodes.append(.label(label, streamNo: streamNo))
    }

    public func end() {
        builderNodes.append(.end)
    }

    internal func build() throws -> [Stage] {
        var stageNumber = 0
        var stages: [Stage] = []
        for (index, currentNode) in builderNodes.enumerated() {
            let previousNode = index == 0 ? .end : builderNodes[index - 1]

            stageNumber += 1

            if let currentStage = try resolveStage(node: currentNode) {
                // We must be either a stage or a label reference
                let currentStageInputStreamNo = currentStage.inputStreams.count
                let currentStageOutputStreamNo = currentStage.outputStreams.count

                if let previousStage = try resolveStage(node: previousNode) {
                    // We have a previous stage
                    let previousStageOutputStreamNo = previousStage.inputStreams.count - 1
                    let stream = Pipes.Stream(producer: previousStage, producerStreamNo: previousStageOutputStreamNo, consumer: currentStage, consumerStreamNo: currentStageInputStreamNo)
                    previousStage.outputStreams[previousStageOutputStreamNo] = stream
                    currentStage.inputStreams.append(stream)
                } else {
                    // No previous stage
                    currentStage.inputStreams.append(Pipes.Stream(consumer: currentStage, consumerStreamNo: currentStageInputStreamNo))
                }
                currentStage.outputStreams.append(Pipes.Stream(producer: currentStage, producerStreamNo: currentStageOutputStreamNo))

                // We only assign a stage number if the node is the original
                // stage reference (and not if it is a label reference)
                if currentNode.stage != nil {
                    currentStage.stageNumber = stageNumber
                }

                if case .stage = currentNode {
                    stages.append(currentStage)
                }
            } else {
                // We must be an end, so nothing to do other than restart the stage number
                stageNumber = 0
            }
        }
        return stages
    }

    private func resolveStage(node: Node) throws -> Stage? {
        switch node {
        case .stage(let stage, _):
            return stage
        case .label(let label, _):
            for n in builderNodes {
                if case let .stage(s, l) = n, label == l {
                    return s
                }
            }
            // In theory, this shouldn't be possible, because add() should prevent it,
            // but we'll deal with it just in case
            throw PipeError.labelNotDeclared(label: label)
        case .end:
            return nil
        }
    }
}

private enum Node {
    case stage(Stage, label: String?)
    case label(String, streamNo: Int)
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

    var streamNo: Int {
        switch self {
        case .stage: return 0
        case .label(_, let streamNo): return streamNo
        case .end: return 0
        }
    }
}

