import Foundation

private func synchronized<T>(_ lock: AnyObject, _ body: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try body()
}

class Stream {
    struct EndPoint: Equatable, Hashable {
        let stage: Stage
        let streamNo: UInt
    }

    let producer: EndPoint?
    let consumer: EndPoint?

    init(producer: EndPoint?, consumer: EndPoint?) {
        self.producer = producer
        self.consumer = consumer
    }
}

extension Stream: Equatable, Hashable {
    static func == (lhs: Stream, rhs: Stream) -> Bool {
        return lhs.producer == rhs.producer && lhs.consumer == rhs.consumer
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(producer)
        hasher.combine(consumer)
    }
}
