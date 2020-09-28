import Foundation

public class Pipe {
    internal var builderNodes: [Node] = []
    internal var builderLabelRefCount: [String: UInt] = [:]

    public func run() {
        let stages = build()

        let group = DispatchGroup()
        stages.forEach { stage in
            group.enter()
            DispatchQueue.global().async {
                stage.dispatch()
                group.leave()
            }
        }
        group.wait()
    }

    internal func build() -> [Stage] {
        var stages: [Stage] = []
        for (index, currentNode) in builderNodes.enumerated() {
            let previousNode = index == 0 ? .end : builderNodes[index - 1]

            if let currentStage = resolveStage(node: currentNode) {
                // We must be either a stage or a label reference
                let currentStageInputStreamNo = UInt(currentStage.inputStreams.count)
                let currentStageOutputStreamNo = UInt(currentStage.outputStreams.count)

                if let previousStage = resolveStage(node: previousNode) {
                    // We have a previous stage
                    let previousStageOutputStreamNo = previousStage.inputStreams.count - 1
                    let stream = Pipes.Stream(producer: previousStage, producerStreamNo: UInt(previousStageOutputStreamNo), consumer: currentStage, consumerStreamNo: currentStageInputStreamNo)
                    previousStage.outputStreams[previousStageOutputStreamNo] = stream
                    currentStage.inputStreams.append(stream)
                } else {
                    // No previous stage
                    currentStage.inputStreams.append(Pipes.Stream(consumer: currentStage, consumerStreamNo: currentStageInputStreamNo))
                }
                currentStage.outputStreams.append(Pipes.Stream(producer: currentStage, producerStreamNo: currentStageOutputStreamNo))

                if case .stage = currentNode {
                    stages.append(currentStage)
                }
            } else {
                // We must be an end, so nothing to do
            }
        }
        return stages
    }

    private func resolveStage(node: Node) -> Stage? {
        switch node {
        case .stage(let stage, _):
            return stage
        case .label(let label, _):
            for n in builderNodes {
                if case let .stage(s, l) = n, label == l {
                    return s
                }
            }
            // TODO error handling
            fatalError("Couldn't find stage for label \(label)")
        case .end:
            return nil
        }
    }

}
