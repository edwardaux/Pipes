import Foundation

public final class Help: Stage {
    private let term: String?

    public init(term: String?) {
        self.term = term
    }

    override public func run() throws {
        let outputLines = generateHelp(term: term)

        // Dump to the console
        for line in outputLines {
            print("")
            print(line)
        }

        // If we're in a pipeline, then send the records down the line.
        if isPrimaryOutputStreamConnected {
            for line in outputLines {
                try output(line)
            }
        }
    }

    private func generateHelp(term: String?) -> [String] {
        // Has the user provided a help term or are they asking for general help?
        if let term = term {
            switch term.uppercased() {
            case "CONVERSION":
                return [ Help.conversionHelp ]
            case "DELIMITEDSTRING":
                return [ Help.delimitedStringHelp ]
            case "INPUTRANGE":
                return [ Help.inputRangeHelp ]
            case "INPUTRANGES":
                return [ Help.inputRangesHelp ]
            case "NUMBER":
                return [ Help.numberHelp ]
            case "NUMORSTAR":
                return [ Help.numOrStarHelp ]
            case "RANGE":
                return [ Help.rangeHelp ]
            case "SNUMBER":
                return [ Help.snumberHelp ]
            case "STREAM":
                return [ Help.streamHelp ]
            case "XORC":
                return [ Help.xorcHelp ]
            default:
                do {
                    let stageType = try Pipe.registeredStageType(for: term)
                    return [
                        stageType.helpSyntax,
                        stageType.helpSummary
                    ].compactMap { $0 }
                } catch {
                    return [ PipeError.stageNotFound(stageName: term).localizedDescription ]
                }
            }
        } else {
            return [ Help.generalHelp ]
        }
    }
}

extension Help: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "help" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let term = try? args.scanWord()

        try args.ensureNoRemainder()

        return Help(term: term)
    }

    public static var helpSummary: String? {
        """
        Outputs help information for the provided stage name or keyword to the console.

        For example:
           pipe help faninany
           pipe help inputRange
        """
    }

    public static var helpSyntax: String? {
        """
        ►►──HELP─┬─stageName─┬─►◄
                 └─keyword───┘
        """
    }
}

extension Help {
    public static var generalHelp: String {
        """
        A pipeline is generally comprised of a number of cascasing stages with a stage separator
        between each one. For example:

            pipe "stage1 | stage2 | stage 3"

        A very simple pipeline might look something like:

            pipe "literal hello world | console"

        The stage separator can be change using the STAGESEP option. For example:

            pipe "(SEP !) stage1 ! stage2 ! stage 3"

        Syntax:

        ►►──pipe──┤ pipeSpec ├──►◄

        pipeSpec:
                                                ┌───endChar────┐
        ├──┬───────────────────┬──┬──────────┬──▼─┤ pipeline ├─┴──┤
           └─┤ globalOptions ├─┘  ├─stageSep─┤
                                  └─endChar──┘

        globalOptions:
             ┌─────────────────────┐
        ├──(─▼─┬─SEParator──xorc──┬┴──)──┤
               ├─ENDchar──xorc────┤
               └─ESCape──xorc─────┘

        The list of supported stages are:
        \(Pipe.registeredStageNames().map { "   \($0)" }.joined(separator: "\n"))

        Detailed help is available for each stage. For example:

            pipe help locate
        """
    }

    public static var conversionHelp: String {
        """
        Converts from one data type to another.  Supported types are:

            B - Bit string. eg "0100100001101001"
            C - Character. eg "Hi"
            X - Hexadecimal number. eg "4869"

        conversion:

        ├─┬─B2C─┬─┤
          ├─B2X─┤
          ├─C2B─┤
          ├─C2X─┤
          ├─X2B─┤
          └─X2C─┘
        """
    }

    public static var delimitedStringHelp: String {
        """
        A delimited character string is written between two occurrences of a delimiter character,
        as a hexadecimal literal, or as a binary literal. The delimiter cannot be blank and it
        must not occur within the string. Two adjacent delimiter characters represent the null
        string. It is suggested that a special character be used as the delimiter, but this is
        not enforced. However, it is advisable not to use alphanumeric characters.

        A hexadecimal literal is specified by a leading H or X followed by an even number of
        hexadecimal digits. A binary literal is specified by a leading B followed by a string of
        0 and 1; the number of binary digits must an integral multiple of eight.

        Examples:
            /abc/
            ,,
            x616263
            b11000001
        """
    }

    public static var inputRangeHelp: String {
        """
        An input range is specified as a column range, a word range, or a field range.

        A single column is specified by a signed number. Negative numbers are relative to the
        end of the record; thus, -1 is the last column of the record. A column range is specified
        as two signed numbers separated by a semicolon or as a range. When a semicolon is used,
        the first number specifies the beginning column and the second number specifies the ending
        column. When the beginning and end of a field are relative to the opposite ends of the record,
        the input field is treated as a null field if the ending column is left of the beginning column.

        A word range is specified by the keyword WORDS, which can be abbreviated down to W. Words are
        separated by one or more blanks. The default blank character is X'20'. Specify the keyword
        WORDSEPARATOR to specify a different word separator character. WORDSEPARATOR can be abbreviated
        down to WORDSEP; WS is a synonym.

        A field range is specified by the keyword FIELDS, which can be abbreviated down to F. Fields
        are separated by tabulate characters. Two adjacent tabulate characters enclose a null field.
        (Note the difference from words.) The default horizontal tab character is X'08'. Specify the
        keyword FIELDSEPARATOR to specify a different field separator character. FIELDSEPARATOR can be
        abbreviated down to FIELDSEP; FS is a synonym.

        The default separator characters are in effect at the beginning of a stage’s operands; once a
        separator character is changed, the change remains in effect for subsequent input ranges.

        Examples:
            1-*
            word 5
            1;-1
            -18;28
            field 4

        inputRange:

        ├──┬──────────────────────────────────────────────┬─┬────────┬─┬─range───────────┬──┤
           │ ┌──────────────────────────────────────────┐ │ ├─wrdSep─┤ ├─snumber─────────┤
           └􏰁─▼─┬─WORDSEParator──xorc──────────────────┬─┴─┘ └─fldSep─┘ └─snumber;snumber─┘
               └─FIELDSEParator──xorc─┬─────────────┬─┘
                                      └─Quote──xorc─┘

        wrdSep:

        ├──┬─────────────────────┬─Words──┤
           └─WORDSEParator──xorc─┘

        fldSep:

        ├──┬──────────────────────────────────────┬─Fields──┤
           └─FIELDSEParator──xorc─┬─────────────┬─┘
                                  └─Quote──xorc─┘
        """
    }

    public static var inputRangesHelp: String {
        """
        A list of input ranges is a single inputRange or a space-separated list of input ranges
        in parentheses. If the keyword WORDSEPARATOR or FIELDSEPARATOR is specified, it remains
        in effect for subsequent words or fields.

        Examples:
            7
            1-*
            (4-* w6)
            (f3 w7)

        inputRanges:

        ├──┬─────inputRange──────┬──┤
           │   ┌────────────┐    │
           └─(─▼─inputRange─┴──)─┘
        """
    }

    public static var numberHelp: String {
        """
        A number is a sequence of decimal digits. A number is unsigned; that is, zero or positive.
        """
    }

    public static var numOrStarHelp: String {
        """
        Column numbers are positive integers; the first (leftmost) column is number 1. An asterisk
        ('*') refers to the first or last column of a record.

        numOrStar:

        ├──┬─number─┬──┤
           └─*──────┘
        """
    }

    public static var rangeHelp: String {
        """
        A range is often used to specify a range of columns in a record or a range of record numbers
        in a file. It is a single number, the beginning and end of the range with a hyphen ('-')
        between them, or the beginning number and the count with a period ('.') between them.
        10-12 and 10.3 express the same range. No blanks are allowed between the numbers and the
        delimiters because CMS Pipelines scans for a word before scanning the word for the range.

        The first number in a range must be positive. The last number in a range specified with a
        hyphen must be larger than or equal to the first one. An asterisk in the first position is
        equivalent to the number 1. An asterisk after a hyphen specifies infinity, the end of the
        record, or all records in a file.

        Some syntax diagrams show range as an alternative to number. Though redundant, this alerts
        you to a difference in semantics when a number is processed differently than a range consisting
        of a single column.

        range:

        ├──┬─number──────────────┬──┤
           ├─number-number───────┤
           ├─number.number───────┤
           ├─numorstar-numorstar─┤
           └─numorstar.number────┘
        """
    }

    public static var snumberHelp: String {
        """
        A signed number can be positive, zero, or negative. Negative numbers have a leading hyphen;
        zero and positive numbers have no sign.

        snumber:

        ├──┬───number───┬──┤
           └──-number───┘
        """
    }

    public static var streamHelp: String {
        """
        A number or a stream identifier. You can always refer to a particular stream by the number
        (the primary stream is number 0, the secondary stream number 1, and so on).

        stream:

        ├──number──┤
        """
    }

    public static var xorcHelp: String {
        """
        A character specified as itself (a word that is one character) or its hexadecimal
        representation (a word that is two characters). The blank is represented by the keyword BLANK,
        which has the synonym SPACE, or with its hex value, X'40'. The default horizontal tabulate
        character (X'08') is represented by the keyword TABULATE, which can be abbreviated down to TAB.

        Examples:
            1
            61
            20
            BLANK
            TABulate
        """
    }
}
