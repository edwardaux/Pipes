import Foundation

public final class Help: Stage {
    override public func run() throws {
        print("Some help goes here")
    }
}

extension Help: RegisteredStage {
    public static var allowedStageNames: [String] {
        [ "help" ]
    }

    public static func createStage(args: Args) -> Stage {
        return Help()
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
