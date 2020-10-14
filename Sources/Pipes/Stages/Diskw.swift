import Foundation

public final class Diskw: Stage {
    private let filename: String

    init(filename: String) {
        self.filename = filename
    }

    override public func run() throws {
        guard stageNumber != 1 else { throw PipeError.cannotBeFirstStage }

        let lineWriter = try FileWriter(path: filename)

        do {
            while true {
                let record = try peekto()
                lineWriter.write(record)
                do {
                    if streamState(.output).isConnected {
                        try output(record)
                    }
                } catch _ as PipeReturnCode {
                    // If the output stream is propagating EOF back, that's OK.
                    // We'll just keep on writing to the file regardless.
                }
                _ = try readto()
            }
        } catch _ as PipeReturnCode {
            try lineWriter.close()
        }
    }
}

extension Diskw: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "diskw", ">" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let filename = args.scanRemainder()
        if filename.isEmpty {
            throw PipeError.requiredOperandMissing
        }

        return Diskw(filename: filename)
    }

    public static var helpSummary: String? {
        "Replaces a file on disk. If the file doesn't exist, it will be created."
    }

    public static var helpSyntax: String? {
        """
        ►►──DISKW──filename──►◄
        """
    }
}

class FileWriter {
    private let path: String
    private let tmpHandle: FileHandle
    private let tmpURL: URL

    init(path: String) throws {
        let url = URL(fileURLWithPath: path)
        do {
            let tmpDir = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)

            self.tmpURL = tmpDir.appendingPathComponent("PIP_\(UUID().uuidString)")
            self.path = path

            FileManager.default.createFile(atPath: tmpURL.path, contents: nil, attributes: nil)
            self.tmpHandle = try FileHandle(forWritingTo: tmpURL)
        } catch let error {
            throw PipeError.unableToWriteToFile(path: path, error: error)
        }

    }

    func write(_ record: String) {
        let line = "\(record)\n"
        tmpHandle.write(line.data(using: .utf8)!)
    }

    func close() throws {
        if #available(OSX 10.15, *) {
            try tmpHandle.close()
        } else {
            tmpHandle.closeFile()
        }

        do {
            let url = URL(fileURLWithPath: path)
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmpURL)
        } catch let error {
            throw PipeError.unableToWriteToFile(path: path, error: error)
        }
    }
}
