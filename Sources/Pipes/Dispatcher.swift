import Foundation

class Dispatcher {
    private let pipeline: Pipeline

    init(pipeline: Pipeline) {
        self.pipeline = pipeline
    }

    func run() {
        let group = DispatchGroup()
        pipeline.stages.forEach { stage in
            group.enter()
            DispatchQueue.global().async {
                stage.dispatch(dispatcher: self)
                group.leave()
            }
        }
        group.wait()
    }

    public func output(_ record: String, stage: Stage, streamNo: UInt) throws {
        try stage.outputStreams[Int(streamNo)].output(record)
    }

    public func readto(stage: Stage, streamNo: UInt) throws -> String {
        return try stage.inputStreams[Int(streamNo)].readto()
    }

    public func peekto(stage: Stage, streamNo: UInt) throws -> String {
        return try stage.inputStreams[Int(streamNo)].peekto()
    }
}
