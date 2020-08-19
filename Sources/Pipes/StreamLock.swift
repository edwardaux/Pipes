//
//  File.swift
//  
//
//  Created by Craig Edwards on 16/8/20.
//

import Foundation

class StreamLock<Message> {
    private enum State {
        case empty
        case full(Message)
        case reading
        case peeking
    }

    private let condition: NSCondition
    private var state: State

    init() {
        self.condition = NSCondition()
        self.state = .empty
    }

    func output(_ message: Message) {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch state {
            case .empty, .full:
                condition.wait()
                continue loop
            case .reading, .peeking:
                state = .full(message)
                condition.signal()
            }
        }
    }

    func readto() -> Message {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch state {
            case .empty:
                state = .reading
                condition.signal()
                condition.wait()
                continue loop
            case let .full(message):
                state = .empty
                condition.signal()
                return message
            case .reading, .peeking:
                condition.wait()
                continue loop
            }
        }
    }

    func peekto() -> Message {
        condition.lock()
        defer { condition.unlock() }

        loop: do {
            switch state {
            case .empty:
                state = .peeking
                condition.signal()
                condition.wait()
                continue loop
            case let .full(message):
                return message
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
