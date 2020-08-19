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
    private enum State {
        case empty
        case full(R)
        case reading
        case peeking
        case severed
    }

    private let condition: NSCondition
    private var state: State

    init() {
        self.condition = NSCondition()
        self.state = .empty
    }

    func output(_ record: R) throws {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch state {
            case .empty, .full:
                condition.wait()
                continue loop
            case .reading, .peeking:
                state = .full(record)
                condition.signal()
            case .severed:
                throw StreamLockError.severed
            }
        }
    }

    func readto() throws -> R {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch state {
            case .empty:
                state = .reading
                condition.signal()
                condition.wait()
                continue loop
            case let .full(record):
                state = .empty
                condition.signal()
                return record
            case .reading, .peeking:
                condition.wait()
                continue loop
            case .severed:
                throw StreamLockError.severed
            }
        }
    }

    func peekto() throws -> R {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch state {
            case .empty:
                state = .peeking
                condition.signal()
                condition.wait()
                continue loop
            case let .full(record):
                return record
            case .reading, .peeking:
                condition.wait()
                continue loop
            case .severed:
                throw StreamLockError.severed
            }
        }
    }

    func sever() {
        condition.lock()
        defer { condition.unlock() }

        state = .severed
        condition.signal()
    }

    deinit {
        sever()
    }
}
