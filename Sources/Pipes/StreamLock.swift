import Foundation

private let debugStreams = true

enum StreamLockError: Error {
    case severed
    case endOfFile
}

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
            switch stream.state {
            case .empty:
                stream.state = .readyToOutput
                condition.signal()
                condition.wait()
                continue loop
            case .full, .readyToOutput:
                condition.signal()
                condition.wait()
                continue loop
            case .peeking:
                stream.state = .full(record: record)
                condition.signal()
                condition.wait()
            case .reading:
                stream.state = .full(record: record)
                condition.signal()
            case .severed:
                throw StreamLockError.severed
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
            switch stream.state {
            case .empty, .readyToOutput:
                stream.state = .peeking
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
                throw StreamLockError.severed
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
            switch stream.state {
            case .empty, .readyToOutput:
                stream.state = .reading
                condition.signal()
                condition.wait()
                continue loop
            case .full(let record):
                stream.state = .empty
                condition.signal()
                return record
            case .reading, .peeking:
                condition.signal()
                condition.wait()
                continue loop
            case .severed:
                throw StreamLockError.severed
            }
        }
    }

    func peektoAny(streams: [Stream]) throws -> String {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            for (index, stream) in streams.enumerated() {
                if case .readyToOutput = stream.state {
                    stream.state = .peeking
                    condition.signal()
                    break
                }
                if case .full = stream.state {
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
                switch stream.state {
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

        stream.state = .severed
        condition.signal()
    }
}
