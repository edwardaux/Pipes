import Foundation

enum StreamState: Equatable {
    case empty
    case readyToOutput
    case full(record: String)
    case reading
    case peeking
    case severed
}

class Stream {
    struct Endpoint: Equatable {
        public let stage: Stage
        public let streamNo: UInt
    }

    public static let ANY = UInt.max

    var state: StreamState
    let producer: Endpoint?
    let consumer: Endpoint?

    var isProducerConnected: Bool {
        return producer != nil
    }
    var isConsumerConnected: Bool {
        return consumer != nil
    }
    
    init(producer: Stage, producerStreamNo: UInt, consumer: Stage, consumerStreamNo: UInt) {
        self.state = .empty
        self.producer = Endpoint(stage: producer, streamNo: producerStreamNo)
        self.consumer = Endpoint(stage: consumer, streamNo: consumerStreamNo)
    }

    init(consumer: Stage, consumerStreamNo: UInt) {
        self.state = .empty
        self.producer = nil
        self.consumer = Endpoint(stage: consumer, streamNo: consumerStreamNo)
    }

    init(producer: Stage, producerStreamNo: UInt) {
        self.state = .empty
        self.producer = Endpoint(stage: producer, streamNo: producerStreamNo)
        self.consumer = nil
    }
}
