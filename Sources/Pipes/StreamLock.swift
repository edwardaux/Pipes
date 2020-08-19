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
        case readyToReceive
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

      case .readyToReceive:
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
        state = .readyToReceive
        condition.signal()
        condition.wait()
        continue loop

      case .readyToReceive:
        condition.wait()
        continue loop

      case let .full(message):
        state = .empty
        condition.signal()
        return message
      }
    }
  }
}
