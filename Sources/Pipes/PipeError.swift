import Foundation

// Typically, these are conditions that aren't always fatal to the
// running of a stage (but depending on the stage's desired behaviour
// they might be). For example, most stages will propagate endOfFile
// however, there are some stages that will catch that specific return
// code and continue processing.
public enum PipeReturnCode: Error {
    case endOfFile
    case streamDoesNotExist(streamNo: UInt)
}

// A PipeError would normally mean termination of the stage.
public enum PipeError: Error {
    case nullStageFound
    case stageNotFound(stageName: String)
    case labelNotDeclared(label: String)
    case labelAlreadyDeclared(label: String)
    case operandNotValid(keyword: String)
    case requiredKeywordsMissing(keywords: [String])
    case requiredOperandMissing

    private var detail: Detail {
        switch self {
        case .nullStageFound:
            return Detail(code: -17, title: "Null stage found", explanation: "There is a stage separator at the end of a pipeline specification; a stage separator is adjacent to an end character; or there are two stage separators with only blank characters between them.", response: "Ensure that the pipeline specification is complete")
        case .stageNotFound(let stageName):
            return Detail(code: -27, title: "Stage \(stageName) not found", explanation: "The named stage is not a built-in or registered stage.", response: "Verify the spelling of the name of the stage to run, or ensure that your custom stage has been registered prior to running the pipeline.")
        case .labelNotDeclared(let label):
            return Detail(code: -46, title: "Label \(label) not declared", explanation: "No specification for a stage is found the first time the label is used. The first usage of a label defines the stage to run, and any operands it may have. Subsequent references are to the label by itself.", response: "Ensure that the label is spelt correctly. If this is the case, inspect the pipeline specification to see if a stage separator is erroneously put between the label and the verb for the stage.")
        case .labelAlreadyDeclared(let label):
            return Detail(code: -47, title: "Label \(label) already declared", explanation: "A reference is made to a label that is already defined. The label reference should be followed by a stage separator or an end character to indicate reference rather than definition.", response: "Ensure that the label is spelt correctly. If this is the case, add a stage separator after the label to indi- cate that this is a reference to a stream other than the primary one. Note that all references to a label refer to the invocation of the stage that is defined with the first usage of the label.")
        case .operandNotValid(let keyword):
            return Detail(code: -111, title: "Operand \(keyword) is not valid", explanation: "A keyword operand is expected, but the word does not match any keyword that is valid in the context.", response: "")
        case .requiredKeywordsMissing(let keywords):
            return Detail(code: -113, title: "Required keyword missing. Allowed: \(keywords.joined(separator: "/"))", explanation: "A stage is missing a required keyword.", response: "")
        case .requiredOperandMissing:
            return Detail(code: -113, title: "Required operand missing", explanation: "A stage has found some, but not all, required operands.", response: "")
        }
    }

    // This represents the info contained in the IBM Reference error section
    private struct Detail {
        let code: Int
        let title: String
        let explanation: String
        let response: String
    }
}

extension PipeError: LocalizedError {
    public var code: Int { return detail.code }
    public var errorDescription: String? { return detail.title }
    public var failureReason: String? { return detail.explanation }
    public var recoverySuggestion: String? { return detail.response }
}

extension PipeError: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.code == rhs.code
    }
}
