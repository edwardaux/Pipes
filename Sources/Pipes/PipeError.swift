import Foundation

enum PipeError: Error {
    case streamDoesNotExist(streamNo: UInt)
    case endOfFile
}
