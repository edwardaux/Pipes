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
}
