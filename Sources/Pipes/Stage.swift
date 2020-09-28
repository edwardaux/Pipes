import Foundation

open class Stage: Identifiable {
    public let id: String = UUID().uuidString

    internal let lock: StreamLock<String>
    internal var inputStreams: [Stream]
    internal var outputStreams: [Stream]

    public init() {
        self.inputStreams = []
        self.outputStreams = []
        self.lock = StreamLock<String>()
    }

    open func run() throws {
        preconditionFailure("Stage \(self) needs to implement run()")
    }
}

//
// MARK: - Setup and dispatch
//
extension Stage {
    internal func setup(inputStreams: [Stream], outputStreams: [Stream]) {
        self.inputStreams = inputStreams
        self.outputStreams = outputStreams
    }

    internal func dispatch() {
        do {
            try run()
        } catch let error {
            print("Stage \(self) has finished: \(error)")
        }

        try? sever()
    }
}

//
// MARK: - Inherited APIs
//
extension Stage {
    public func output(_ record: String, streamNo: UInt = 0) throws {
        // TODO is this the right error
        // TODO check stream No
        let stream = outputStreams[Int(streamNo)]
        guard let consumer = stream.consumer else { throw StreamLockError.endOfFile }

        try consumer.stage.lock.output(record, stream: stream)
    }

    public func readto(streamNo: UInt = 0) throws -> String {
        // TODO is this the right error
        // TODO check stream No
        if streamNo == Stream.ANY {
            let record = try lock.readtoAny(streams: inputStreams)
            return record
        } else {
            let stream = inputStreams[Int(streamNo)]
            guard stream.isProducerConnected else { throw StreamLockError.endOfFile }

            return try lock.readto(stream: stream)
        }
    }

    public func peekto(streamNo: UInt = 0) throws -> String {
        // TODO is this the right error
        // TODO check stream No
        if streamNo == Stream.ANY {
            return try lock.peektoAny(streams: inputStreams)
        } else {
            let stream = inputStreams[Int(streamNo)]
            guard stream.isProducerConnected else { throw StreamLockError.endOfFile }

            return try lock.peekto(stream: stream)
        }
    }

    public func sever() throws {
        // TODO think about this more
        inputStreams.enumerated().forEach {
            lock.sever(stream: $1)
        }
        outputStreams.enumerated().forEach {
            lock.sever(stream: $1)
        }
    }

    public var maxInputStreamNo: Int {
        return inputStreams.count - 1
    }

    public var maxOutputStreamNo: Int {
        return outputStreams.count - 1
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
