import Foundation

class StreamLock<R> {
    private let condition: NSCondition
    private var lastPeekedStreamIndex: Int?

    init() {
        self.condition = NSCondition()
    }

    func output(_ record: String, stream: Stream) throws {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch stream.lockState {
            case .empty:
                stream.lockState = .readyToOutput
                condition.signal()
                condition.wait()
                continue loop
            case .full, .readyToOutput:
                condition.signal()
                condition.wait()
                continue loop
            case .peeking:
                stream.lockState = .full(record: record)
                condition.signal()
                condition.wait()
            case .reading:
                stream.lockState = .full(record: record)
                condition.signal()
            case .severed:
                throw EndOfFile()
            }
        }
    }

    func peekto(stream: Stream) throws -> String {
        condition.lock()
        defer { condition.unlock() }

        return try lockedPeekto(stream: stream)
    }

    private func lockedPeekto(stream: Stream) throws -> String {
        loop: do {
            switch stream.lockState {
            case .empty, .readyToOutput:
                stream.lockState = .peeking
                condition.signal()
                condition.wait()
                continue loop
            case .full(let record):
                return record
            case .reading, .peeking:
                condition.signal()
                condition.wait()
                continue loop
            case .severed:
                throw EndOfFile()
            }
        }
    }

    func readto(stream: Stream) throws -> String {
        condition.lock()
        defer { condition.unlock() }

        return try lockedReadto(stream: stream)
    }

    private func lockedReadto(stream: Stream) throws -> String {
        loop: do {
            switch stream.lockState {
            case .empty, .readyToOutput:
                stream.lockState = .reading
                condition.signal()
                condition.wait()
                continue loop
            case .full(let record):
                stream.lockState = .empty
                condition.signal()
                return record
            case .reading, .peeking:
                condition.signal()
                condition.wait()
                continue loop
            case .severed:
                throw EndOfFile()
            }
        }
    }

    func peektoAny(streams: [Stream]) throws -> String {
        condition.lock()
        defer { condition.unlock() }

        if let index = lastPeekedStreamIndex {
            return try lockedPeekto(stream: streams[index])
        }

        loop: do {
            for (index, stream) in streams.enumerated() {
                if case .readyToOutput = stream.lockState {
                    stream.lockState = .peeking
                    condition.signal()
                    break
                }
                if case .full = stream.lockState {
                    lastPeekedStreamIndex = index
                    return try lockedPeekto(stream: stream)
                }
            }
            condition.wait()
            continue loop
        }
    }

    func readtoAny(streams: [Stream]) throws -> String {
        condition.lock()
        defer { condition.unlock() }

        if let index = lastPeekedStreamIndex {
            lastPeekedStreamIndex = nil
            return try lockedReadto(stream: streams[index])
        }

        loop: do {
            for stream in streams {
                switch stream.lockState {
                case .readyToOutput, .full:
                    return try lockedReadto(stream: stream)
                default:
                    break
                }
            }
            condition.wait()
            continue loop
        }
    }

    func sever(stream: Stream) {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch stream.lockState {
            case .full:
                // If we're in full state, it means that the producer has made the
                // record available and its stage has ended (and this severing its
                // streams) before the consumer has had a chance to grab the record.
                // So we give the consumer a chance to read the record before we
                // totally sever the producer's streams.
                condition.signal()
                condition.wait()
                continue loop
            default:
                stream.lockState = .severed
                condition.signal()
            }
        }
    }
}
