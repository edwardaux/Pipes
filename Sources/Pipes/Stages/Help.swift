import Foundation

public final class Help: Stage {
    private let stageName: String

    init(stageName: String) {
        self.stageName = stageName
    }

    override public func run() throws {
        do {
            let stageType = try Pipe.registeredStageType(for: stageName)
            let outputLines = [
                stageType.helpSyntax,
                stageType.helpSummary
            ].compactMap { $0 }

            // Dump to the console
            for line in outputLines {
                print(line)
            }

            // If we're in a pipeline, then send the records down the line.
            if streamState(.output).isConnected {
                for line in outputLines {
                    try output(line)
                }
            }
        } catch {
            print(PipeError.stageNotFound(stageName: stageName).localizedDescription)
        }
    }
}

extension Help: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "help" ]
    }

    public static func createStage(args: Args) throws -> Stage {
        return Help(stageName: try args.scanWord())
    }

    public static var helpSummary: String? {
        "Outputs help information for the provided stage name to the console"
    }

    public static var helpSyntax: String? {
        """
        ►►──HELP──stageName──►◄
        """
    }
}
