import Foundation

open class Pipeline {
    let stages: [Stage]

    init(stages: [Stage]) {
        self.stages = stages
    }
}
