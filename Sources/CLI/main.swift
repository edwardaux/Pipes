import Foundation
import Pipes

let argv = CommandLine.arguments

let spec: String
if argv.count <= 1 {
    spec = "help"
} else {
    spec = argv.dropFirst().joined(separator: " ")
}

do {
    try Pipe(spec).run()
} catch let error as PipeError {
    print(error.localizedDescription)
} catch let error {
    print("Unexpected error: \(error)")
}
