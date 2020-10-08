import Foundation
import Pipes

let argv = CommandLine.arguments
let spec = argv.dropFirst().joined(separator: " ")
try Pipe("literal | literal  | literal there | console").run()
