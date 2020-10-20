import Foundation

class Parser {
    private let pipeSpec: String
    private let options: Options

    init(pipeSpec: String) throws {
        let (options, remainderPipeSpec) = try Parser.parseOptions(pipeSpec: pipeSpec)
        self.pipeSpec = remainderPipeSpec
        self.options = options
    }

    func parse(into pipe: Pipe) throws {
        let pipelineSpecs = try parsePipe(pipeSpec: pipeSpec, options: options)
        for pipelineSpec in pipelineSpecs {
            let stages = try parsePipeline(pipelineSpec: pipelineSpec, options: options)
            try stages.forEach {
                _ = try pipe.add($0)
            }
            _ = pipe.end()
        }
    }

    static func parseOptions(pipeSpec: String) throws -> (Options, String) {
        let tokenizer = StringTokenizer(pipeSpec)
        guard let firstChar = tokenizer.peekChar(), firstChar == "(" else {
            return (Options.default, pipeSpec)
        }
        guard let pipeOptions = tokenizer.scan(between: "(", and: ")") else {
            throw PipeError.missingEndingParenthesis
        }
        let options = Options(stageSep: "|", escape: nil, endChar: nil)
        let remainingPipeSpec = tokenizer.scanRemainder(trimLeading: false, trimTrailing: false)
        return (options, remainingPipeSpec)
    }

    func parsePipe(pipeSpec: String, options: Options) throws -> [String] {
        guard let endChar = options.endChar else { return [pipeSpec] }

        return pipeSpec.split(separator: endChar, escape: options.escape)
    }

    func parsePipeline(pipelineSpec: String, options: Options) throws -> [Stage] {
        let stageSpecs = pipelineSpec.split(separator: options.stageSep).map { String($0) }
        let argsList = try stageSpecs.map { try Args($0) }
        let stages: [Stage] = try argsList.map { (args: Args) in
            let stageType = try Pipe.registeredStageType(for: args.stageName)
            let stage = try stageType.createStage(args: args)
            return stage
        }
        return stages
    }
}
