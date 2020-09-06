import Foundation

private let NOT_CONNECTED: UInt = 9999999

class Stream {
    private static let debug = true

    private let lock = StreamLock<String>()

    let producer: Stage?
    let producerStreamNo: UInt
    let consumer: Stage?
    let consumerStreamNo: UInt

    init(producer: Stage, producerStreamNo: UInt, consumer: Stage, consumerStreamNo: UInt) {
        self.producer = producer
        self.producerStreamNo = producerStreamNo
        self.consumer = consumer
        self.consumerStreamNo = consumerStreamNo
    }

    init(producer: Stage?, consumer: Stage, consumerStreamNo: UInt) {
        self.producer = producer
        self.producerStreamNo = NOT_CONNECTED
        self.consumer = consumer
        self.consumerStreamNo = consumerStreamNo
    }

    init(producer: Stage, producerStreamNo: UInt, consumer: Stage?) {
        self.producer = producer
        self.producerStreamNo = producerStreamNo
        self.consumer = consumer
        self.consumerStreamNo = NOT_CONNECTED
    }

    func output(_ record: String) throws {
        if Self.debug { debug(producer, producerStreamNo, "About to output: \(record)") }
        try lock.output(record)
        if Self.debug { debug(producer, producerStreamNo, "Succesfully output: \(record)") }
    }

    func readto() throws -> String {
        if Self.debug { debug(consumer, consumerStreamNo, "About to readto") }
        let record = try lock.readto()
        if Self.debug { debug(consumer, consumerStreamNo, "Successfully readto: \(record)") }
        return record
    }

    func peekto() throws -> String {
        if Self.debug { debug(consumer, consumerStreamNo, "About to peekto") }
        let record = try lock.peekto()
        if Self.debug { debug(consumer, consumerStreamNo, "Successfully peekto: \(record)") }
        return record
    }

    func sever() {
        if Self.debug { debug(producer, producerStreamNo, "About to sever: \(consumer?.name ?? "Not connected")(\(consumerStreamNo))") }
        lock.sever()
        if Self.debug { debug(producer, producerStreamNo, "Successfully severed: \(consumer?.name ?? "Not connected")(\(consumerStreamNo))") }
    }

    private func debug(_ stage: Stage?, _ streamNo: UInt, _ message: String) {
        print("\(stage?.name ?? "Weird")(\(streamNo)): \(message)")
    }
}
