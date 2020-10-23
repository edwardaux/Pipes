import Foundation

public enum StreamDirection {
    case input
    case output
}

open class Stage: Identifiable {
    public let id: String = UUID().uuidString

    internal let lock: StreamLock<String>
    internal var inputStreams: [Stream]
    internal var outputStreams: [Stream]
    internal var committed = false

    /// Returns the position of this stage in the pipeline of its primary stream. First
    /// stage returns 1.
    public internal(set) var stageNumber: Int = 1

    public init() {
        self.inputStreams = []
        self.outputStreams = []
        self.lock = StreamLock<String>()
    }

    open func run() throws {
        preconditionFailure("Stage \(self) needs to implement run()")
    }

    open func commit() throws {
        // By default, we do nothing but this gives the stages an opportunity to
        // do some checks before running.
    }
}

//
// MARK: - Dispatch
//
extension Stage {
    internal func dispatch() throws {
        defer {
            for (streamNo, stream) in inputStreams.enumerated() {
                try? sever(.input, streamNo: streamNo)
            }
            for (streamNo, stream) in outputStreams.enumerated() {
                try? sever(.output, streamNo: streamNo)
            }
        }

        do {
            try run()
        } catch _ as EndOfFile {
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

    public var isPrimaryInputStreamConnected: Bool {
        return streamState(.input, streamNo: 0).isConnected
    }

    public var isPrimaryOutputStreamConnected: Bool {
        return streamState(.output, streamNo: 0).isConnected
    }

    public var isSecondaryInputStreamConnected: Bool {
        return streamState(.input, streamNo: 1).isConnected
    }

    public var isSecondaryOutputStreamConnected: Bool {
        return streamState(.output, streamNo: 1).isConnected
    }

    public var isTertiaryInputStreamConnected: Bool {
        return streamState(.input, streamNo: 2).isConnected
    }

    public var isTertiaryOutputStreamConnected: Bool {
        return streamState(.output, streamNo: 2).isConnected
    }

    public func output(_ record: String, streamNo: Int = 0) throws {
        guard committed else { throw PipeError.commandNotPermitted(command: "OUTPUT") }
        guard streamNo < outputStreams.count else { throw PipeError.streamNotDefined(streamNo: streamNo) }

        let stream = outputStreams[streamNo]
        guard let consumer = stream.consumer else { throw EndOfFile() }

        try consumer.stage.lock.output(record, stream: stream)
    }

    public func readto(streamNo: Int = 0) throws -> String {
        guard committed else { throw PipeError.commandNotPermitted(command: "READTO") }

        if streamNo == Stream.ANY {
            let record = try lock.readtoAny(streams: inputStreams)
            return record
        } else {
            guard streamNo < inputStreams.count else { throw PipeError.streamNotDefined(streamNo: streamNo) }

            let stream = inputStreams[streamNo]
            guard stream.isProducerConnected else { throw EndOfFile() }

            return try lock.readto(stream: stream)
        }
    }

    public func peekto(streamNo: Int = 0) throws -> String {
        guard committed else { throw PipeError.commandNotPermitted(command: "PEEKTO") }

        if streamNo == Stream.ANY {
            return try lock.peektoAny(streams: inputStreams)
        } else {
            guard streamNo < inputStreams.count else { throw PipeError.streamNotDefined(streamNo: streamNo) }

            let stream = inputStreams[streamNo]
            guard stream.isProducerConnected else { throw EndOfFile() }

            return try lock.peekto(stream: stream)
        }
    }

    public func sever(_ direction: StreamDirection, streamNo: Int = 0) throws {
        guard committed else { throw PipeError.commandNotPermitted(command: "SEVER") }

        switch direction {
        case .input:
            guard streamNo < inputStreams.count else { throw PipeError.streamNotDefined(streamNo: streamNo) }

            let stream = inputStreams[streamNo]
            lock.sever(stream: stream)
        case .output:
            guard streamNo < outputStreams.count else { throw PipeError.streamNotDefined(streamNo: streamNo) }

            let stream = outputStreams[streamNo]
            stream.consumer?.stage.lock.sever(stream: stream)
        }
    }

    public func streamState(_ direction: StreamDirection, streamNo: Int = 0) -> StreamState {
        switch direction {
        case .input:
            guard streamNo < inputStreams.count else { return .notDefined }

            let stream = inputStreams[streamNo]
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

            let stream = outputStreams[streamNo]
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
