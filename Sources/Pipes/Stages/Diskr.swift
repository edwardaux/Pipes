import Foundation

public final class Diskr: Stage {
    private let filename: String

    init(filename: String) {
        self.filename = filename
    }

    override public func run() throws {
        guard stageNumber == 1 else { throw PipeError.mustBeFirstStage }

        let lineReader = try LineReader(path: filename)
        for line in lineReader {
            try output(line)
        }
    }
}

extension Diskr: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "diskr", "<" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let filename = args.scanRemainder()
        if filename.isEmpty {
            throw PipeError.requiredOperandMissing
        }

        return Diskr(filename: filename)
    }

    public static var helpSummary: String? {
        "Reads the contents of a file line by line. The file must exist."
    }

    public static var helpSyntax: String? {
        """
        ►►──DISKR──filename──►◄
        """
    }
}

private class LineReader {
    private let file: UnsafeMutablePointer<FILE>!

    init(path: String) throws {
        guard let file = fopen(path, "r") else { throw PipeError.fileDoesNotExist(filename: path) }

        self.file = file
    }

    public var nextLine: String? {
        var chars: UnsafeMutablePointer<CChar>? = nil
        var linecap: Int = 0

        defer { free(chars) }
        guard getline(&chars, &linecap, file) > 0 else { return nil }

        let line = String(cString: chars!)
        return line.last?.isNewline == true ? String(line.dropLast()) : line
    }

    deinit {
      fclose(file)
    }
}

extension LineReader: Sequence {
   public func  makeIterator() -> AnyIterator<String> {
      return AnyIterator<String> {
         return self.nextLine
      }
   }
}