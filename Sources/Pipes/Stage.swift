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
// MARK: - Dispatch
//
extension Stage {
    internal func dispatch() throws {
        defer {
            for streamNo in 0..<maxInputStreamNo {
                try? severInput(streamNo: UInt(streamNo))
            }
            for streamNo in 0..<maxOutputStreamNo {
                try? severOutput(streamNo: UInt(streamNo))
            }
        }

        do {
            try run()
        } catch _ as PipeReturnCode {
            // These types of errors don't constitute an error
        }
    }
}

//
// MARK: - Inherited APIs
//
extension Stage {
    public func output(_ record: String, streamNo: UInt = 0) throws {
        guard streamNo < outputStreams.count else { throw PipeReturnCode.streamDoesNotExist(streamNo: streamNo) }

        let stream = outputStreams[Int(streamNo)]
        guard let consumer = stream.consumer else { throw PipeReturnCode.endOfFile }

        try consumer.stage.lock.output(record, stream: stream)
    }

    public func readto(streamNo: UInt = 0) throws -> String {
        if streamNo == Stream.ANY {
            let record = try lock.readtoAny(streams: inputStreams)
            return record
        } else {
            guard streamNo < inputStreams.count else { throw PipeReturnCode.streamDoesNotExist(streamNo: streamNo) }

            let stream = inputStreams[Int(streamNo)]
            guard stream.isProducerConnected else { throw PipeReturnCode.endOfFile }

            return try lock.readto(stream: stream)
        }
    }

    public func peekto(streamNo: UInt = 0) throws -> String {
        if streamNo == Stream.ANY {
            return try lock.peektoAny(streams: inputStreams)
        } else {
            guard streamNo < inputStreams.count else { throw PipeReturnCode.streamDoesNotExist(streamNo: streamNo) }

            let stream = inputStreams[Int(streamNo)]
            guard stream.isProducerConnected else { throw PipeReturnCode.endOfFile }

            return try lock.peekto(stream: stream)
        }
    }

    public func severInput(streamNo: UInt = 0) throws {
        guard streamNo < inputStreams.count else { throw PipeReturnCode.streamDoesNotExist(streamNo: streamNo) }

        let stream = inputStreams[Int(streamNo)]
        lock.sever(stream: stream)
    }

    public func severOutput(streamNo: UInt = 0) throws {
        guard streamNo < outputStreams.count else { throw PipeReturnCode.streamDoesNotExist(streamNo: streamNo) }

        let stream = outputStreams[Int(streamNo)]
        lock.sever(stream: stream)
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
