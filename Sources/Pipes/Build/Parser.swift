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
            if pipelineSpec.trimmingCharacters(in: .whitespaces).isEmpty {
                throw PipeError.noPipelineSpecified
            }

            let argsList = try parsePipeline(pipelineSpec: pipelineSpec, options: options)
            for args in argsList {
                switch args.type {
                case .label(let label):
                    _ = try pipe.add(label: label)
                case .stage(let stageName, let label):
                    let stageType = try Pipe.registeredStageType(for: stageName)
                    let stage = try stageType.createStage(args: args)
                    _ = try pipe.add(stage, label: label)
                }
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

        var stageSep: Character = "|"
        var escape: Character? = nil
        var endChar: Character? = nil

        let optionsTokenizer = StringTokenizer(pipeOptions)
        while let keyword = optionsTokenizer.scanWord() {
            if keyword.matchesKeyword("SEPARATOR", minLength: 3) || keyword.matchesKeyword("STAGESEP") {
                if let word = optionsTokenizer.scanWord() {
                    stageSep = try word.asXorC()
                } else {
                    throw PipeError.valueMissingForOption(keyword: keyword)
                }
            } else if keyword.matchesKeyword("ENDCHAR", minLength: 3) {
                if let word = optionsTokenizer.scanWord() {
                    endChar = try word.asXorC()
                } else {
                    throw PipeError.valueMissingForOption(keyword: keyword)
                }
            } else if keyword.matchesKeyword("ESCAPE", minLength: 3) {
                if let word = optionsTokenizer.scanWord() {
                    escape = try word.asXorC()
                } else {
                    throw PipeError.valueMissingForOption(keyword: keyword)
                }
            } else {
                throw PipeError.optionNotValid(option: keyword)
            }
        }

        let options = Options(stageSep: stageSep, escape: escape, endChar: endChar)
        let remainingPipeSpec = tokenizer.scanRemainder(trimLeading: false, trimTrailing: false)
        return (options, remainingPipeSpec)
    }

    func parsePipe(pipeSpec: String, options: Options) throws -> [String] {
        guard let endChar = options.endChar else { return [pipeSpec] }

        return pipeSpec.split(separator: endChar, escape: options.escape)
    }

    func parsePipeline(pipelineSpec: String, options: Options) throws -> [Args] {
        let stageSpecs = pipelineSpec.split(separator: options.stageSep).map { String($0) }
        let argsList = try stageSpecs.map { try Args($0) }
        return argsList
    }
}
