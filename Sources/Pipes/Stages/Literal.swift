import Foundation

public class Literal: Stage {
    private let record: String

    init(_ record: String) {
        self.record = record
    }

    override public func run() throws {
        try output(record)

        while true {
            let record = try peekto()
            print(record)
            try output(record)
            _ = try readto()
        }
    }
}
