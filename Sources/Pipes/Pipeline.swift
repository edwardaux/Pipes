import Foundation

open class Pipeline {
    internal let stages: [Stage]
    internal let streams: [Stream]

    init(stages: [Stage], streams: [Stream]) {
        self.stages = stages
        self.streams = streams

        for stage in stages {
            let inputStreams = streams.filter { $0.consumer?.stage == stage }.sorted { ($0.consumer?.streamNo ?? 9999999) < ($1.consumer?.streamNo ?? 9999999)}
            let outputStreams = streams.filter { $0.producer?.stage == stage }.sorted { ($0.producer?.streamNo ?? 9999999) < ($1.producer?.streamNo ?? 9999999) }
            stage.setup(inputStreams: inputStreams, outputStreams: outputStreams)
        }
    }
}
