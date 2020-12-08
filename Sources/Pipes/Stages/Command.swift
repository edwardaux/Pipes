import Foundation

public final class Command: Stage {
    private let program: String
    private let args: String?

    init(program: String, args: String? = nil) {
        self.program = program
        self.args = args
    }

    public override func commit() throws {
        try ensureOnlyPrimaryInputStreamConnected()

        guard FileManager.default.fileExists(atPath: program) else {
            throw PipeError.programUnableToExecute(program: program, reason: "Not found")
        }
    }


    override public func run() throws {
        var records: [String] = []
        if stageNumber > 1 {
            do {
                while true {
                    records.append(try readto())
                }
            } catch _ as EndOfFile {
            }
        }

        let task = Process()
        task.launchPath = program
        if let args = args, args.count > 0 {
            task.arguments = [ args ]
        }

        let inputPipe = Foundation.Pipe()
        let outputPipe = Foundation.Pipe()
        let errorPipe = Foundation.Pipe()

        task.standardInput = inputPipe
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
        } catch let error {
            if FileManager.default.isExecutableFile(atPath: program) {
                throw PipeError.programUnableToExecute(program: program, reason: error.localizedDescription)
            } else {
                throw PipeError.programUnableToExecute(program: program, reason: "Not executable")
            }
        }

        if !records.isEmpty {
            for record in records {
                if let data = "\(record)\n".data(using: .utf8) {
                    inputPipe.fileHandleForWriting.write(data)
                }
            }
            inputPipe.fileHandleForWriting.closeFile()
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if !outputData.isEmpty && isPrimaryOutputStreamConnected {
            if let string = String(data: outputData, encoding: .utf8) {
                let records = string.split(separator: "\n")
                for record in records {
                    try output(String(record))
                }
            }
        }

        if !errorData.isEmpty && isSecondaryOutputStreamConnected {
            if let string = String(data: errorData, encoding: .utf8) {
                let records = string.split(separator: "\n")
                for record in records {
                    try output(String(record), streamNo: 1)
                }
            }
        }
    }
}

extension Command: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "command", "cmd", "shell", "sh" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        let program = try args.scanWord()
        let args = args.scanRemainder()

        return Command(program: program, args: args)
    }

    public static var helpSummary: String? {
        """
        Issues an operating system command and captures the response, which is then written to
        the output of the stage rather than being displayed on the terminal.

        If not the first stage in a pipeline, the input records are buffered and passed into the
        operating system command on stdin. Any output that is written to the operating system
        command's stdout will be passed to output stream. If the secondary output stream is
        connected, stderr will be output on the secondary output stream (otherwise it will be
        discarded).
        """
    }

    public static var helpSyntax: String? {
        """
        ►►──┬─COMMAND─┬─program─┬──────┬──►◄
            ├─CMD─────┤         └─args─┘
            └─SHell───┘
        """
    }
}
