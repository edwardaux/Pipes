//import Foundation
//
//open class PipeBuilder {
//    enum Node {
//        case stage(Stage, String?)
//        case label(String, UInt)
//        case end
//
//        var stage: Stage? {
//            switch self {
//            case .stage(let stage, _):
//                return stage
//            case .label:
//                return nil
//            case .end:
//                return nil
//            }
//        }
//
//        var label: String? {
//            switch self {
//            case .stage(_, let label):
//                return label
//            case .label(let label, _):
//                return label
//            case .end:
//                return nil
//            }
//        }
//
//        var isEnd: Bool {
//            switch self {
//            case .end:
//                return true
//            default:
//                return false
//            }
//        }
//
//        var streamNo: UInt {
//            switch self {
//            case .stage:
//                return 0
//            case .label(_, let streamNo):
//                return streamNo
//            case .end:
//                return 0
//            }
//        }
//    }
//
//    private var nodes: [Node] = []
//    private var labelRefCount: [String: UInt] = [:]
//    //private var streams: Set<Stream> = []
//
//    public init() {
//    }
//
//    public func add(stage: Stage, label: String? = nil) -> PipeBuilder {
//        nodes.append(.stage(stage, label))
//        if let label = label {
//            labelRefCount[label] = 0
//        }
//        return self
//    }
//
//    public func add(label: String) -> PipeBuilder {
//        guard let prevRef = labelRefCount[label] else { fatalError("Referencing \(label) before definition") }
//        let streamNo = prevRef + 1
//        labelRefCount[label] = streamNo
//        nodes.append(.label(label, streamNo))
//        return self
//    }
//
//    public func end() -> PipeBuilder {
//        nodes.append(.end)
//        return self
//    }
//
//    public func build() -> Pipeline {
//        for i in 0 ..< nodes.count {
//            let previousNode = i == 0 ? .end : nodes[i-1]
//            let currentNode = nodes[i]
//            let nextNode = i == nodes.count - 1 ? .end : nodes[i+1]
//
//            switch currentNode {
//            case .stage(let currentStage, _):
//                if !previousNode.isEnd {
//                    let previousStage = resolvedStage(node: previousNode)
//                    let previousStreamNo = previousNode.streamNo
////                    connect(producer: Stream.EndPoint(stage: previousStage, streamNo: previousStreamNo), consumer: Stream.EndPoint(stage: currentStage, streamNo: 0))
//                }
//                if !nextNode.isEnd {
//                    let nextStage = resolvedStage(node: nextNode)
//                    let nextStreamNo = nextNode.streamNo
////                    connect(producer: Stream.EndPoint(stage: currentStage, streamNo: 0), consumer: Stream.EndPoint(stage: nextStage, streamNo: nextStreamNo))
//                }
//            case .label(_, let referencedStreamNo):
//                let referencedStage = resolvedStage(node: currentNode)
//
//                if !previousNode.isEnd {
//                    let previousStage = resolvedStage(node: previousNode)
//                    let previousStreamNo = previousNode.streamNo
////                    connect(producer: Stream.EndPoint(stage: previousStage, streamNo: previousStreamNo), consumer: Stream.EndPoint(stage: referencedStage, streamNo: referencedStreamNo))
//                }
//                if !nextNode.isEnd {
//                    let nextStage = resolvedStage(node: nextNode)
//                    let nextStreamNo = nextNode.streamNo
////                    connect(producer: Stream.EndPoint(stage: referencedStage, streamNo: referencedStreamNo), consumer: Stream.EndPoint(stage: nextStage, streamNo: nextStreamNo))
//                }
//            case .end:
//                break
//            }
//        }
//        return Pipeline(stages: [], streams: [])
////        return Pipeline(stages: nodes.compactMap { $0.stage }, streams: Array(streams))
//    }
//
//    private func resolvedStage(node: Node) -> Stage {
//        switch node {
//        case .stage(let stage, _):
//            return stage
//        case .label(let label, _):
//            for n in nodes {
//                if case let .stage(s, l) = n, label == l {
//                    return s
//                }
//            }
//            fatalError("Couldn't find stage for label \(label)")
//        case .end:
//            fatalError("Cannot resolve end stage")
//        }
//    }
//
////    private func connect(producer: Stream.EndPoint?, consumer: Stream.EndPoint?) {
////        streams.insert(Stream(producer: producer, consumer: consumer))
////    }
//}
