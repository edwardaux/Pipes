import Foundation

open class Stage: Identifiable {
    public let id: String = UUID().uuidString

    internal var name: String
    private var dispatcher: Dispatcher!

    internal let lock: StreamLock<String>
    internal var inputStreams: [Stream]
    internal var outputStreams: [Stream]

    internal var debugIndent: String

    public init(_ name: String, debugIndent: String = "") {
        self.name = name
        self.inputStreams = []
        self.outputStreams = []
        self.lock = StreamLock<String>()
        self.debugIndent = debugIndent
    }

    public func output(_ record: String, streamNo: UInt = 0) throws {
        // TODO is this the right error
        // TODO check stream No
        let stream = outputStreams[Int(streamNo)]
        guard let consumer = stream.consumer, stream.consumerStreamNo != NOT_CONNECTED else { throw StreamLockError.endOfFile }

        try consumer.lock.output(record, stream: stream)
    }

    public func readto(streamNo: UInt = 0) throws -> String {
        if streamNo == Stream.ANY {
            let record = try lock.readtoAny(streams: inputStreams)
            return record
        } else {
            let producer = inputStreams[Int(streamNo)]
            guard producer.producerStreamNo != NOT_CONNECTED else { throw StreamLockError.endOfFile }

            return try lock.readto(stream: producer)
        }
    }

    public func peekto(streamNo: UInt = 0) throws -> String {
        if streamNo == Stream.ANY {
            return try lock.peektoAny(streams: inputStreams)
        } else {
            let producer = inputStreams[Int(streamNo)]
            guard producer.producerStreamNo != NOT_CONNECTED else { throw StreamLockError.endOfFile }

            return try lock.peekto(stream: producer)
        }
    }

    func sever() throws {
        // TODO think about this more
        inputStreams.enumerated().forEach {
            lock.sever(stream: $1)
        }
        outputStreams.enumerated().forEach {
            lock.sever(stream: $1)
        }
    }

    func dispatch(dispatcher: Dispatcher) {
        self.dispatcher = dispatcher

        do {
            try run()
        } catch let error {
            print("Stage \(name) has finished: \(error)")
        }

        try? sever()
    }

    open func run() throws {
        preconditionFailure("Stage \(self) needs to implement run()")
    }

    deinit {
        // TODO clean up streams
//        consumer?.lock.sever(stream: self)
    }

}

extension Stage {
    internal func setup(inputStreams: [Stream], outputStreams: [Stream]) {
        self.inputStreams = inputStreams
        self.outputStreams = outputStreams
    }
}

extension Stage: Equatable, Hashable {
    public static func == (lhs: Stage, rhs: Stage) -> Bool {
        return lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
