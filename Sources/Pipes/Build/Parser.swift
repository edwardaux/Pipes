import Foundation

class Parser {
    let pipeSpec: String

    init(pipeSpec: String) {
        self.pipeSpec = pipeSpec
    }

    func parse(into pipe: Pipe) throws {
        let stageSpecs = pipeSpec.split(separator: "|").map { String($0) }
        let argsList = stageSpecs.map { Args($0) }
        let stages: [Stage] = try argsList.map { (args: Args) in
            let stageType = try Pipe.registeredStageType(for: args.stageName)
            let stage = stageType.createStage(args: args)
            return stage
        }
        try stages.forEach {
            _ = try pipe.add($0)
        }
    }
}
