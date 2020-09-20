import Foundation

// TODO hide this and create getters
let NOT_CONNECTED: UInt = 9999999

enum StreamState: Equatable {
    case empty
    case readyToOutput
    case full(record: String)
    case reading
    case peeking
    case severed
}

class Stream {
    public static let ANY = UInt.max

    var state: StreamState

    let producer: Stage?
    let producerStreamNo: UInt
    let consumer: Stage?
    let consumerStreamNo: UInt

    init(producer: Stage, producerStreamNo: UInt, consumer: Stage, consumerStreamNo: UInt) {
        self.state = .empty
        self.producer = producer
        self.producerStreamNo = producerStreamNo
        self.consumer = consumer
        self.consumerStreamNo = consumerStreamNo
    }

    init(producer: Stage?, consumer: Stage, consumerStreamNo: UInt) {
        self.state = .empty
        self.producer = producer
        self.producerStreamNo = NOT_CONNECTED
        self.consumer = consumer
        self.consumerStreamNo = consumerStreamNo
    }

    init(producer: Stage, producerStreamNo: UInt, consumer: Stage?) {
        self.state = .empty
        self.producer = producer
        self.producerStreamNo = producerStreamNo
        self.consumer = consumer
        self.consumerStreamNo = NOT_CONNECTED
    }
}
