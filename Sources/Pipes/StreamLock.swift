//
//  File.swift
//  
//
//  Created by Craig Edwards on 16/8/20.
//

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
        debug(stream.producer, "About to output: \(record)")
        debug(stream.producer, "Waiting for lock")
        condition.lock()
        defer { condition.unlock() }
        debug(stream.producer, "Acquired lock")

        loop: do {
            debug(stream.producer, "State check: \(stream.state)")
            switch stream.state {
            case .empty:
                debug(stream.producer, "Changing state to: readyToOutput")
                stream.state = .readyToOutput
                debug(stream.producer, "Signalling...")
                condition.signal()
                debug(stream.producer, "Waiting...")
                condition.wait()
                debug(stream.producer, "Returned from wait")
                continue loop
            case .full, .readyToOutput:
                debug(stream.consumer, "Signalling...")
                condition.signal()
                debug(stream.producer, "Waiting...")
                condition.wait()
                debug(stream.producer, "Returned from wait")
                continue loop
            case .peeking:
                debug(stream.producer, "Changing state to: full")
                stream.state = .full(record: record)
                debug(stream.producer, "Signalling...")
                condition.signal()
                debug(stream.producer, "Waiting...")
                condition.wait()
                debug(stream.producer, "Returned from wait")
            case .reading:
                debug(stream.producer, "Changing state to: full")
                stream.state = .full(record: record)
                debug(stream.producer, "Signalling...")
                condition.signal()
            case .severed:
                throw StreamLockError.severed
            }
        }
        debug(stream.producer, "Output complete: \(record)")
    }

    func peekto(stream: Stream) throws -> String {
        debug(stream.consumer, "About to peekto")
        debug(stream.consumer, "Waiting for lock")
        condition.lock()
        defer { condition.unlock() }
        debug(stream.consumer, "Acquired lock")

        return try lockedPeekto(stream: stream)
    }

    private func lockedPeekto(stream: Stream) throws -> String {
        loop: do {
            debug(stream.consumer, "State check: \(stream.state)")
            switch stream.state {
            case .empty, .readyToOutput:
                debug(stream.consumer, "Changing state to: reading")
                stream.state = .peeking
                debug(stream.consumer, "Signalling...")
                condition.signal()
                debug(stream.consumer, "Waiting...")
                condition.wait()
                debug(stream.consumer, "Returned from wait")
                continue loop
            case .full(let record):
                debug(stream.consumer, "Peekto complete: \(record)")
                return record
            case .reading, .peeking:
                debug(stream.consumer, "Signalling...")
                condition.signal()
                debug(stream.consumer, "Waiting...")
                condition.wait()
                debug(stream.consumer, "Returned from wait")
                continue loop
            case .severed:
                throw StreamLockError.severed
            }
        }
    }

    func readto(stream: Stream) throws -> String {
        debug(stream.consumer, "About to readto")
        debug(stream.consumer, "Waiting for lock")
        condition.lock()
        defer { condition.unlock() }
        debug(stream.consumer, "Acquired lock")

        return try lockedReadto(stream: stream)
    }

    private func lockedReadto(stream: Stream) throws -> String {
        loop: do {
            debug(stream.consumer, "State check: \(stream.state)")
            switch stream.state {
            case .empty, .readyToOutput:
                debug(stream.consumer, "Changing state to: reading")
                stream.state = .reading
                debug(stream.consumer, "Signalling...")
                condition.signal()
                debug(stream.consumer, "Waiting...")
                condition.wait()
                debug(stream.consumer, "Returned from wait")
                continue loop
            case .full(let record):
                debug(stream.consumer, "Changing state to: empty")
                stream.state = .empty
                debug(stream.consumer, "Signalling...")
                condition.signal()
                debug(stream.consumer, "Readto complete: \(record)")
                return record
            case .reading, .peeking:
                debug(stream.consumer, "Signalling...")
                condition.signal()
                debug(stream.consumer, "Waiting...")
                condition.wait()
                debug(stream.consumer, "Returned from wait")
                continue loop
            case .severed:
                throw StreamLockError.severed
            }
        }
    }

    func peektoAny(streams: [Stream]) throws -> String {
        debug(streams.first?.consumer, "About to readto (any)")
        debug(streams.first?.consumer, "Waiting for lock (any)")
        condition.lock()
        defer { condition.unlock() }
        debug(streams.first?.consumer, "Acquired lock (any)")

        loop: do {
            for (index, stream) in streams.enumerated() {
                debug(stream.consumer, "State check (any): \(stream.state)")
                if case .readyToOutput = stream.state {
                    debug(stream.consumer, "Changing state to: peeking")
                    stream.state = .peeking
                    debug(stream.consumer, "Signalling (any)...")
                    condition.signal()
                    break
                }
                if case .full = stream.state {
                    lastPeekedStreamIndex = index
                    return try lockedPeekto(stream: stream)
                }
            }
            debug(streams.first?.consumer, "Waiting (any)...")
            condition.wait()
            debug(streams.first?.consumer, "Returned from wait (any)")
            continue loop
        }
    }

    func readtoAny(streams: [Stream]) throws -> String {
        debug(streams.first?.consumer, "About to readto (any)")
        debug(streams.first?.consumer, "Waiting for lock (any)")
        condition.lock()
        defer { condition.unlock() }
        debug(streams.first?.consumer, "Acquired lock (any)")

        if let index = lastPeekedStreamIndex {
            lastPeekedStreamIndex = nil
            return try lockedReadto(stream: streams[index])
        }

        loop: do {
            for stream in streams {
                debug(stream.consumer, "State check (any): \(stream.state)")
                switch stream.state {
                case .readyToOutput, .full:
                    return try lockedReadto(stream: stream)
                default:
                    break
                }
            }
            debug(streams.first?.consumer, "Waiting (any)...")
            condition.wait()
            debug(streams.first?.consumer, "Returned from wait (any)")
            continue loop
        }
    }

    func sever(stream: Stream) {
        debug(stream.consumer, "About to sever")
        debug(stream.consumer, "Waiting for lock")
        condition.lock()
        defer { condition.unlock() }
        debug(stream.consumer, "Acquired lock")

        debug(stream.consumer, "Changing state to: severed")
        stream.state = .severed
        debug(stream.consumer, "Signalling...")
        condition.signal()
    }

    private func debug(_ stage: Stage?, _ message: String) {
        guard let stage = stage else { return }
        print(stage.debugIndent+message)
    }
}
