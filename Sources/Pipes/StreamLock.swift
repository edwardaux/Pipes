import Foundation

class StreamLock<R> {
    private let condition: NSCondition
    private var lastPeekedStreamIndex: Int?

    init() {
        self.condition = NSCondition()
    }

    func output(_ record: String, stream: Stream) throws {
        // debug(stream.producer!.stage, "About to output: \(record)")
        // debug(stream.producer!.stage, "Waiting for lock")
        condition.lock()
        defer { condition.unlock() }
        // debug(stream.producer!.stage, "Acquired lock")

        loop: do {
            // debug(stream.producer!.stage, "State check: \(stream.lockState)")
            switch stream.lockState {
            case .empty:
                // debug(stream.producer!.stage, "Changing state to: readyToOutput")
                stream.lockState = .readyToOutput
                // debug(stream.producer!.stage, "Signalling...")
                condition.signal()
                // debug(stream.producer!.stage, "Waiting...")
                condition.wait()
                // debug(stream.producer!.stage, "Returned from wait")
                continue loop
            case .full, .readyToOutput:
                // debug(stream.producer!.stage, "Signalling...")
                condition.signal()
                // debug(stream.producer!.stage, "Waiting...")
                condition.wait()
                // debug(stream.producer!.stage, "Returned from wait")
                continue loop
            case .peeking:
                // debug(stream.producer!.stage, "Changing state to: full")
                stream.lockState = .full(record: record)
                // debug(stream.producer!.stage, "Signalling...")
                condition.signal()
                // debug(stream.producer!.stage, "Waiting...")
                condition.wait()
                // debug(stream.producer!.stage, "Returned from wait")
            case .reading:
                // debug(stream.producer!.stage, "Changing state to: full")
                stream.lockState = .full(record: record)
                // debug(stream.producer!.stage, "Signalling...")
                condition.signal()
            case .severed:
                throw EndOfFile()
            }
        }
        // debug(stream.producer!.stage, "Output complete: \(record)")
    }

    func peekto(stream: Stream) throws -> String {
        // debug(stream.consumer!.stage, "About to peekto")
        // debug(stream.consumer!.stage, "Waiting for lock")
        condition.lock()
        defer { condition.unlock() }
        // debug(stream.consumer!.stage, "Acquired lock")

        return try lockedPeekto(stream: stream)
    }

    private func lockedPeekto(stream: Stream) throws -> String {
        loop: do {
            // debug(stream.consumer!.stage, "State check: \(stream.lockState)")
            switch stream.lockState {
            case .empty, .readyToOutput:
                // debug(stream.consumer!.stage, "Changing state to: peeking")
                stream.lockState = .peeking
                // debug(stream.consumer!.stage, "Signalling...")
                condition.signal()
                // debug(stream.consumer!.stage, "Waiting...")
                condition.wait()
                // debug(stream.consumer!.stage, "Returned from wait")
                continue loop
            case .full(let record):
                // debug(stream.consumer!.stage, "Peekto complete: \(record)")
                return record
            case .reading, .peeking:
                // debug(stream.consumer!.stage, "Signalling...")
                condition.signal()
                // debug(stream.consumer!.stage, "Waiting...")
                condition.wait()
                // debug(stream.consumer!.stage, "Returned from wait")
                continue loop
            case .severed:
                throw EndOfFile()
            }
        }
    }

    func readto(stream: Stream) throws -> String {
        // debug(stream.consumer!.stage, "About to readto")
        // debug(stream.consumer!.stage, "Waiting for lock")
        condition.lock()
        defer { condition.unlock() }
        // debug(stream.consumer!.stage, "Acquired lock")

        return try lockedReadto(stream: stream)
    }

    private func lockedReadto(stream: Stream) throws -> String {
        loop: do {
            // debug(stream.consumer!.stage, "State check: \(stream.lockState)")
            switch stream.lockState {
            case .empty, .readyToOutput:
                // debug(stream.consumer!.stage, "Changing state to: reading")
                stream.lockState = .reading
                // debug(stream.consumer!.stage, "Signalling...")
                condition.signal()
                // debug(stream.consumer!.stage, "Waiting...")
                condition.wait()
                // debug(stream.consumer!.stage, "Returned from wait")
                continue loop
            case .full(let record):
                // debug(stream.consumer!.stage, "Changing state to: empty")
                stream.lockState = .empty
                // debug(stream.consumer!.stage, "Signalling...")
                condition.signal()
                // debug(stream.consumer!.stage, "Readto complete: \(record)")
                return record
            case .reading, .peeking:
                // debug(stream.consumer!.stage, "Signalling...")
                condition.signal()
                // debug(stream.consumer!.stage, "Waiting...")
                condition.wait()
                // debug(stream.consumer!.stage, "Returned from wait")
                continue loop
            case .severed:
                throw EndOfFile()
            }
        }
    }

    func peektoAny(streams: [Stream]) throws -> String {
        // debug(streams.first?.consumer!.stage, "About to readto (any)")
        // debug(streams.first?.consumer!.stage, "Waiting for lock (any)")
        condition.lock()
        defer { condition.unlock() }

        // debug(streams.first?.consumer!.stage, "Acquired lock (any)")
        if let index = lastPeekedStreamIndex {
            return try lockedPeekto(stream: streams[index])
        }

        loop: do {
            for (index, stream) in streams.enumerated() {
                // debug(stream.consumer!.stage, "State check (any): \(stream.lockState)")
                if case .readyToOutput = stream.lockState {
                    // debug(stream.consumer!.stage, "Changing state to: peeking")
                    stream.lockState = .peeking
                    // debug(stream.consumer!.stage, "Signalling (any)...")
                    condition.signal()
                    break
                }
                if case .full = stream.lockState {
                    lastPeekedStreamIndex = index
                    return try lockedPeekto(stream: stream)
                }
            }
            let allSevered = streams.reduce(true) { $0 && $1.lockState == .severed }
            if allSevered {
                // debug(streams.first?.consumer!.stage, "All severed. End of file.")
                throw EndOfFile()
            }
            // debug(streams.first?.consumer!.stage, "Waiting peekToAny (any)...")
            condition.wait()
            // debug(streams.first?.consumer!.stage, "Returned from wait (any)")
            continue loop
        }
    }

    func readtoAny(streams: [Stream]) throws -> String {
        // debug(streams.first?.consumer!.stage, "About to readto (any)")
        // debug(streams.first?.consumer!.stage, "Waiting for lock (any)")
        condition.lock()
        defer { condition.unlock() }
        // debug(streams.first?.consumer!.stage, "Acquired lock (any)")

        if let index = lastPeekedStreamIndex {
            lastPeekedStreamIndex = nil
            return try lockedReadto(stream: streams[index])
        }

        loop: do {
            for stream in streams {
                // debug(stream.consumer!.stage, "State check (any): \(stream.lockState)")
                switch stream.lockState {
                case .readyToOutput, .full:
                    return try lockedReadto(stream: stream)
                default:
                    break
                }
            }
            let allSevered = streams.reduce(true) { $0 && $1.lockState == .severed }
            if allSevered {
                // debug(streams.first?.consumer!.stage, "All severed. End of file.")
                throw EndOfFile()
            }
            // debug(streams.first?.consumer!.stage, "Waiting readToAny (any)...")
            condition.wait()
            // debug(streams.first?.consumer!.stage, "Returned from wait (any)")
            continue loop
        }
    }

    func sever(stream: Stream) {
        // debug(stream.consumer!.stage, "About to sever")
        // debug(stream.consumer!.stage, "Waiting for lock")
        condition.lock()
        defer { condition.unlock() }
        // debug(stream.consumer!.stage, "Acquired lock")

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
                // debug(stream.consumer!.stage, "Changing state to: severed")
                stream.lockState = .severed
                condition.signal()
                // debug(stream.consumer!.stage, "Signalling...")
            }
        }
    }

    private func debug(_ stage: Stage?, _ message: String) {
        guard let stage = stage else { return }
        let indent = String(repeating: "   ", count: stage.stageNumber)
        print(indent+message)
    }
}
