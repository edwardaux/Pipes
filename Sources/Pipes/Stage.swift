import Foundation

public enum StreamState {
    case connectedWaiting
    case connectedNotWaiting
    case notConnected
    case notDefined
}

public enum StreamSide {
    case input
    case output
}

open class Stage: Identifiable {
    public let id: String = UUID().uuidString

    internal let lock: StreamLock<String>
    internal var inputStreams: [Stream]
    internal var outputStreams: [Stream]

    /// Returns the position of this stage in the pipeline of its primary stream. First
    /// stage returns 1.
    public internal(set) var stageNumber: UInt = 1

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
                try? sever(.input, streamNo: UInt(streamNo))
            }
            for streamNo in 0..<maxOutputStreamNo {
                try? sever(.output, streamNo: UInt(streamNo))
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
    public var maxInputStreamNo: Int {
        return inputStreams.count - 1
    }

    public var maxOutputStreamNo: Int {
        return outputStreams.count - 1
    }

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

    public func sever(_ side: StreamSide, streamNo: UInt = 0) throws {
        switch side {
        case .input:
            guard streamNo < inputStreams.count else { throw PipeReturnCode.streamDoesNotExist(streamNo: streamNo) }

            let stream = inputStreams[Int(streamNo)]
            lock.sever(stream: stream)
        case .output:
            guard streamNo < outputStreams.count else { throw PipeReturnCode.streamDoesNotExist(streamNo: streamNo) }

            let stream = outputStreams[Int(streamNo)]
            lock.sever(stream: stream)
        }
    }

    public func streamState(_ side: StreamSide, streamNo: UInt = 0) -> StreamState {
        switch side {
        case .input:
            guard streamNo < inputStreams.count else { return .notDefined }

            let stream = inputStreams[Int(streamNo)]
            if !stream.isProducerConnected { return .notConnected }

            switch stream.lockState {
            case .empty: return .connectedNotWaiting
            case .readyToOutput: return .connectedWaiting
            case .full: return .connectedWaiting
            case .reading: return .connectedWaiting
            case .peeking: return .connectedWaiting
            case .severed: return .notConnected
            }
        case .output:
            guard streamNo < outputStreams.count else { return .notDefined }

            let stream = outputStreams[Int(streamNo)]
            if !stream.isConsumerConnected { return .notConnected }

            switch stream.lockState {
            case .empty: return .connectedNotWaiting
            case .readyToOutput: return .connectedWaiting
            case .full: return .connectedWaiting
            case .reading: return .connectedWaiting
            case .peeking: return .connectedWaiting
            case .severed: return .notConnected
            }
        }
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
