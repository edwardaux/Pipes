import Foundation

open class Stage: Identifiable {
    
    public let id: String = UUID().uuidString

    internal var name: String
//    var inputStage: Stage?
//    var inputRecord: String?
//    var outputStage: Stage?
//    var outputRecord: String?
    private var dispatcher: Dispatcher!

    internal var inputStreams: [Stream]
    internal var outputStreams: [Stream]

    public init(_ name: String) {
        self.name = name
        self.inputStreams = []
        self.outputStreams = []
    }

    public func output(_ record: String, streamNo: UInt = 0) throws {
        try dispatcher.output(record, stage: self, streamNo: streamNo)
    }

    public func readto(streamNo: UInt = 0) throws -> String {
        return try dispatcher.readto(stage: self, streamNo: streamNo)
    }

    public func peekto(streamNo: UInt = 0) throws -> String {
        return try dispatcher.peekto(stage: self, streamNo: streamNo)
    }

    func dispatch(dispatcher: Dispatcher) {
        self.dispatcher = dispatcher

        do {
            try run()
        } catch let error {
            print("Stage \(name) has finished: \(error)")
        }

        inputStreams.forEach { $0.sever() }
        outputStreams.forEach { $0.sever() }
    }

    open func run() throws {
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
