//
//  File.swift
//  
//
//  Created by Craig Edwards on 16/8/20.
//

import Foundation

enum StreamLockError: Error {
    case severed
    case endOfFile
}

class StreamLock<R> {
    private struct PendingRecord {
        let consumerStreamNo: UInt
        let record: R
    }

    private let condition: NSCondition
    private var pendingRecords: [PendingRecord]

    init() {
        self.condition = NSCondition()
        self.pendingRecords = []
    }

    func output(_ record: R, stream: Stream) throws {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch stream.state {
            case .empty, .full:
                condition.wait()
                continue loop
            case .peeking:
                stream.state = .full
                pendingRecords.append(PendingRecord(consumerStreamNo: stream.consumerStreamNo, record: record))
                condition.signal()
                condition.wait()
            case .reading:
                stream.state = .full
                pendingRecords.append(PendingRecord(consumerStreamNo: stream.consumerStreamNo, record: record))
                condition.signal()
            case .severed:
                throw StreamLockError.severed
            }
        }
    }

    func readto(stream: Stream) throws -> R {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch stream.state {
            case .empty:
                stream.state = .reading
                condition.signal()
                condition.wait()
                continue loop
            case .full:
                if let index = pendingRecords.firstIndex(where: { $0.consumerStreamNo == stream.consumerStreamNo }) {
                    let pendingRecord = pendingRecords.remove(at: index)
                    stream.state = .empty
                    condition.signal()
                    return pendingRecord.record
                }
                condition.wait()
                continue loop
            case .reading, .peeking:
                condition.wait()
                continue loop
            case .severed:
                throw StreamLockError.severed
            }
        }
    }

    func peekto(stream: Stream) throws -> R {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch stream.state {
            case .empty:
                stream.state = .peeking
                condition.signal()
                condition.wait()
                continue loop
            case .full:
                if let pendingRecord = pendingRecords.first(where: { $0.consumerStreamNo == stream.consumerStreamNo }) {
                    return pendingRecord.record
                }
                condition.wait()
                continue loop
            case .reading, .peeking:
                condition.wait()
                continue loop
            case .severed:
                throw StreamLockError.severed
            }
        }
    }

    func sever(stream: Stream) {
        condition.lock()
        defer { condition.unlock() }

        stream.state = .severed
        pendingRecords = []
        condition.signal()
    }
}
