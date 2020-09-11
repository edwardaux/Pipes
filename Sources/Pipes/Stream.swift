import Foundation

private let NOT_CONNECTED: UInt = 9999999

enum StreamState {
    case empty
    case full
    case reading
    case peeking
    case severed
}

class Stream {
    private static let debug = true

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

    func output(_ record: String) throws {
        // TODO is this the right error
        guard let consumer = consumer else { throw StreamLockError.endOfFile }

        if Self.debug { debug(producer, producerStreamNo, "About to output: \(record)") }
        try consumer.lock.output(record, stream: self)
        if Self.debug { debug(producer, producerStreamNo, "Succesfully output: \(record)") }
    }

    func readto() throws -> String {
        // TODO is this the right error
        guard let consumer = consumer else { throw StreamLockError.endOfFile }

        if Self.debug { debug(consumer, consumerStreamNo, "About to readto") }
        let record = try consumer.lock.readto(stream: self)
        if Self.debug { debug(consumer, consumerStreamNo, "Successfully readto: \(record)") }
        return record
    }

    func peekto() throws -> String {
        // TODO is this the right error
        guard let consumer = consumer else { throw StreamLockError.endOfFile }

        if Self.debug { debug(consumer, consumerStreamNo, "About to peekto") }
        let record = try consumer.lock.peekto(stream: self)
        if Self.debug { debug(consumer, consumerStreamNo, "Successfully peekto: \(record)") }
        return record
    }

    func sever() throws {
        // TODO is this the right error
        guard let consumer = consumer else { throw StreamLockError.endOfFile }

        if Self.debug { debug(producer, producerStreamNo, "About to sever: \(consumer.name)(\(consumerStreamNo))") }
        consumer.lock.sever(stream: self)
        if Self.debug { debug(producer, producerStreamNo, "Successfully severed: \(consumer.name)(\(consumerStreamNo))") }
    }

    private func debug(_ stage: Stage?, _ streamNo: UInt, _ message: String) {
        print("\(stage?.name ?? "Weird")(\(streamNo)): \(message)")
    }

    deinit {
        consumer?.lock.sever(stream: self)
    }
}
