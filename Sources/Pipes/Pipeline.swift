import Foundation

open class Pipeline {
    internal let stages: [Stage]
    internal let streams: [Stream]

    init(stages: [Stage], streams: [Stream]) {
        self.stages = stages
        self.streams = streams

        for stage in stages {
            let inputStreams = streams.filter { $0.consumer == stage }
            let outputStreams = streams.filter { $0.producer == stage }
            stage.setup(inputStreams: inputStreams, outputStreams: outputStreams)
        }
    }

    func run() {
        let dispatcher = Dispatcher(pipeline: self)
        dispatcher.run()
    }
}
