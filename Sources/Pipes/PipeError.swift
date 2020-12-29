import Foundation

// Typically, these are conditions that aren't always fatal to the
// running of a stage (but depending on the stage's desired behaviour
// they might be). For example, most stages will propagate endOfFile
// however, there are some stages that will catch that specific return
// code and continue processing.
public struct EndOfFile: Error {
}

// A PipeError would normally mean termination of the stage.
public enum PipeError: Error, Equatable {
    case streamNotDefined(direction: StreamDirection, streamNo: Int)
    case streamNotConnected(direction: StreamDirection, streamNo: Int)
    case emptyParameterList
    case optionNotValid(option: String)
    case valueMissingForOption(keyword: String)
    case nullStageFound
    case stageNotFound(stageName: String)
    case programUnableToExecute(program: String, reason: String)
    case labelNotDeclared(label: String)
    case labelAlreadyDeclared(label: String)
    case invalidCharacterRepresentation(word: String)
    case invalidRange(range: String)
    case noInputRanges
    case invalidNumber(word: String)
    case delimiterMissing(delimiter: String)
    case outputSpecificationMissing
    case outputSpecificationInvalid(word: String)
    case hexDataMissing(prefix: String)
    case hexStringNotHex(string: String)
    case mustBeFirstStage
    case invalidStreamIdentifier(identifier: String)
    case operandNotValid(keyword: String)
    case excessiveOptions(string: String)
    case requiredKeywordsMissing(keywords: [String])
    case requiredOperandMissing
    case cannotBeFirstStage
    case fileDoesNotExist(filename: String)
    case missingEndingParenthesis
    case noPipelineSpecified
    case numberCannotBeNegative(number: Int)
    case hexStringNotDivisibleBy2(string: String)
    case binaryStringNotDivisibleBy8(string: String)
    case binaryDataMissing(prefix: String)
    case binaryStringNotBinary(string: String)
    case conversionError(type: String, reason: String, input: String)
    case outputRangeEndInvalid
    case unableToWriteToFile(path: String, error: String)
    case unusedStreamConnected(direction: StreamDirection, streamNo: Int)
    case unexpectedCharacters(expected: String, found: String)
    case commandNotPermitted(command: String)
    case invalidString

    private var detail: Detail {
        switch self {
        case .streamNotDefined(let direction, let streamNo):
            return Detail(code: -4, title: "\(direction) stream \(streamNo) is not defined", explanation: "Stream is not defined.")
        case .streamNotConnected(let direction, let streamNo):
            return Detail(code: -12, title: "\(direction) stream \(streamNo) is not connected", explanation: "Stream is not connected.")
        case .emptyParameterList:
            return Detail(code: -11, title: "Blank parameter list", explanation: "A null parameter list is found by the pipeline command processor or a stage needing parameters.")
        case .optionNotValid(let word):
            return Detail(code: -14, title: "Option \(word) not valid", explanation: "The word substituted is not recognised as one of the global options supported. Defined global options are: NAME TRACE LISTRC LISTERR LISTCMD STOP SEPARATOR ENDCHAR ESCAPE MSGLEVEL.")
        case .valueMissingForOption(let keyword):
            return Detail(code: -15, title: "Value missing for keyword \(keyword)", explanation: "An operand is specified that requires a value (for instance, NAME), but the following non-blank character is the right parenthesis that ends the global options, or the operand is the last word of the argument string to a stage.")
        case .nullStageFound:
            return Detail(code: -17, title: "Null stage found", explanation: "There is a stage separator at the end of a pipeline specification; a stage separator is adjacent to an end character; or there are two stage separators with only blank characters between them.")
        case .stageNotFound(let stageName):
            return Detail(code: -27, title: "Stage \(stageName) not found", explanation: "The named stage is not a built-in or registered stage. Verify the spelling of the name of the stage to run, or ensure that your custom stage has been registered prior to running the pipeline.")
        case .programUnableToExecute(let program, let reason):
            return Detail(code: -40, title: "Program \"\(program)\" unable to executed: \(reason)", explanation: "No specification for a stage is found the first time the label is used. The first usage of a label defines the stage to run, and any operands it may have. Subsequent references are to the label by itself.")
        case .labelNotDeclared(let label):
            return Detail(code: -46, title: "Label \(label) not declared", explanation: "No specification for a stage is found the first time the label is used. The first usage of a label defines the stage to run, and any operands it may have. Subsequent references are to the label by itself.")
        case .labelAlreadyDeclared(let label):
            return Detail(code: -47, title: "Label \(label) already declared", explanation: "A reference is made to a label that is already defined. The label reference should be followed by a stage separator or an end character to indicate reference rather than definition.")
        case .invalidCharacterRepresentation(let word):
            return Detail(code: -50, title: "Not a character or hexadecimal representation: \(word)", explanation: "\(word) is not a character or a two-digit hexadecimal representation of a character.")
        case .invalidRange(let range):
            return Detail(code: -54, title: "Range \"\(range) not valid", explanation: "The specific range values are invalid.")
        case .noInputRanges:
            return Detail(code: -55, title: "No input ranges in list", explanation: "A left parenthesis is found, which indicates the beginning of a list of input ranges. The next non-blank character is a right parenthesis, which indicates that the list contains no ranges.")
        case .invalidNumber(let word):
            return Detail(code: -58, title: "Number expected, but \(word) was found", explanation: "\(word) contains a character that is not a digit.")
        case .delimiterMissing(let delimiter):
            return Detail(code: -60, title: "Delimiter \(delimiter) missing after string", explanation: "No closing delimiter found for a delimited string.")
        case .outputSpecificationMissing:
            return Detail(code: -61, title: "Output specification missing", explanation: "The output column is not specified for the last item.")
        case .outputSpecificationInvalid(let word):
            return Detail(code: -63, title: "Output specification \(word) is not valid", explanation: "The word specifies where to put a field in the output record; it is not a positive number or a column range.")
        case .hexDataMissing(let prefix):
            return Detail(code: -64, title: "Hexadecimal data missing after \(prefix)", explanation: "A prefix is found, indicating that a hexadecimal constant should follow, but the next character is blank or the end of the argument string. Do not use letters as delimiters for a delimited string.")
        case .hexStringNotHex(let string):
            return Detail(code: -65, title: "\"\(string)\" is not hexadecimal", explanation: "An h, H, x, or X is found in the first character of a specification item to specify a hexadecimal literal, but the remainder of the word is not composed of hexadecimal digits. Do not use letters as delimiters for a delimited string.")
        case .mustBeFirstStage:
            return Detail(code: -87, title: "This stage must be the first stage of a pipeline", explanation: "A program that cannot process input records is not in the first position of the pipeline.")
        case .invalidStreamIdentifier(let identifier):
            return Detail(code: -102, title: "Stream \(identifier) is not valid", explanation: "Invalid stream identifier.")
        case .operandNotValid(let keyword):
            return Detail(code: -111, title: "Operand \(keyword) is not valid", explanation: "A keyword operand is expected, but the word does not match any keyword that is valid in the context.")
        case .excessiveOptions(let string):
            return Detail(code: -112, title: "Excessive options \"\(string)", explanation: "A stage has scanned all options it recognises; the string shown remains.")
        case .requiredKeywordsMissing(let keywords):
            return Detail(code: -113, title: "Required keyword missing. Allowed: \(keywords.joined(separator: "/"))", explanation: "A stage is missing a required keyword.")
        case .requiredOperandMissing:
            return Detail(code: -113, title: "Required operand missing", explanation: "A stage has found some, but not all, required operands.")
        case .cannotBeFirstStage:
            return Detail(code: -127, title: "This stage cannot be the first stage of a pipeline", explanation: "A device driver that requires an input stream is first in a pipeline, where there can be no input to read")
        case .fileDoesNotExist(let filename):
            return Detail(code: -146, title: "File \(filename) does not exist.", explanation: "A file does not exist.")
        case .missingEndingParenthesis:
            return Detail(code: -200, title: "Missing ending parenthesis in expression", explanation: "More left parentheses are met than can be paired with right parentheses in the expression.")
        case .noPipelineSpecified:
            return Detail(code: -256, title: "No pipeline specified on pipe command", explanation: "The PIPE command is issued without arguments.")
        case .numberCannotBeNegative(let number):
            return Detail(code: -287, title: "Number \(number) cannot be ngative", explanation: "A negative number is specified for an operand to a stage that only supports zero or positive numbers.")
        case .hexStringNotDivisibleBy2(let string):
            return Detail(code: -335, title: "Odd number of characters in hex data: \(string)", explanation: "A prefix indicating a hexadecimal constant is found, but the remainder of the word does not contain an even number of characters.")
        case .binaryStringNotDivisibleBy8(let string):
            return Detail(code: -336, title: "String length not divisible by 8: \(string)", explanation: "A prefix indicating a binary constant is found, but the number of characters in the remainder of the word is not divisible by eight.")
        case .binaryDataMissing(let prefix):
            return Detail(code: -337, title: "Binary data missing after \(prefix)", explanation: "A prefix indicating a binary constant is found, but there are no more characters in the argument string or the next character is blank.")
        case .binaryStringNotBinary(let string):
            return Detail(code: -338, title: "Not binary data: \(string)", explanation: "A prefix indicating a binary constant is found, but the remainder of the word contains a character that is neither 0 nor 1.")
        case .conversionError(let type, let reason, let input):
            return Detail(code: -392, title: "Conversion error in routine \(type), reason: \(reason), input: \(input)", explanation: "The string shown has a value that is not valid for the conversion requested.")
        case .outputRangeEndInvalid:
            return Detail(code: -556, title: "Asterisk cannot end output column range", explanation: "Write a single column to put a field at a particular position, extending as far as required. Use a range to put the field into a particular range of columns, padding or truncating as necessary")
        case .unableToWriteToFile(let path, let error):
            return Detail(code: -780, title: "You are not allowed to write to \(path). Reason: \(error)", explanation: "The directory record for an existing file indicates that you cannot write to it.")
        case .unusedStreamConnected(let direction, let streamNo):
            return Detail(code: -1196, title: "\(direction) stream \(streamNo) is unexpectedly connected.", explanation: "A stream is connected that the stage does not use. This is often a symptom of an incorrect placement of a label reference.")
        case .unexpectedCharacters(let expected, let found):
            return Detail(code: -1458, title: "Expected \(expected) but found \(found)", explanation: "Unexpected input because \(expected) was expected but \(found) was encountered instead.")
        case .commandNotPermitted(let command):
            return Detail(code: -2000, title: "Command \(command) not permitted during commit() phase.", explanation: "Stream operations are only permitted in the run() function.")
        case .invalidString:
            return Detail(code: -2001, title: "Splitting on byte boundary results in invalid UTF-8 string", explanation: "Choose a different length that does not split in the middle of a Unicode character.")
        }
    }

    // This represents the info contained in the IBM Reference error section
    private struct Detail {
        let code: Int
        let title: String
        let explanation: String
    }
}

extension PipeError: LocalizedError {
    public var code: Int { return detail.code }
    public var errorDescription: String? { return detail.title }
    public var failureReason: String? { return detail.explanation }
}
