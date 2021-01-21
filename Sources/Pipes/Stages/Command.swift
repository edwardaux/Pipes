import Foundation

public final class Command: Stage {
    private let commandLine: String

    public init(commandLine: String) {
        self.commandLine = commandLine
    }

    public override func commit() throws {
        try ensureOnlyPrimaryInputStreamConnected()
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
        task.launchPath = "/usr/bin/env"
        task.arguments = [ "-S", commandLine ]

        let inputPipe = Foundation.Pipe()
        let outputPipe = Foundation.Pipe()
        let errorPipe = Foundation.Pipe()

        task.standardInput = inputPipe
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
        } catch let error {
            throw PipeError.programUnableToExecute(program: commandLine, reason: error.localizedDescription)
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

        task.waitUntilExit()
        if task.terminationStatus == 126 {
            throw PipeError.programUnableToExecute(program: commandLine, reason: "Not executable")
        } else if task.terminationStatus == 127 {
            throw PipeError.programUnableToExecute(program: commandLine, reason: "Not found")
        }

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
        let commandLine = args.scanRemainder().trimmingCharacters(in: .whitespaces)
        guard !commandLine.isEmpty else {
            throw PipeError.requiredOperandMissing
        }

        return Command(commandLine: commandLine)
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
