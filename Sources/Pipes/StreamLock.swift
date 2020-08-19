//
//  File.swift
//  
//
//  Created by Craig Edwards on 16/8/20.
//

import Foundation

class StreamLock<R> {
    private enum State {
        case empty
        case full(R)
        case reading
        case peeking
    }

    private let condition: NSCondition
    private var state: State

    init() {
        self.condition = NSCondition()
        self.state = .empty
    }

    func output(_ record: R) {
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
            }
        }
    }

    func readto() -> R {
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
            }
        }
    }

    func peekto() -> R {
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
            }
        }
    }

    deinit {
//        condition.signal()
    }
}
