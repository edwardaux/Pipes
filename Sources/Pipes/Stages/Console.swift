import Foundation

public class Console: Stage {
    override public func run() throws {
        while true {
            let record = try peekto()
            print(record)
            try output(record)
            _ = try readto()
        }
    }
}
