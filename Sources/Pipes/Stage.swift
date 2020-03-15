import Foundation

open class Stage: Identifiable {

    public let id: String = UUID().uuidString

    private let lock = DispatchSemaphore(value: 0)

    var name: String
    var inputStage: Stage?
    var inputRecord: String?
    var outputStage: Stage?
    var outputRecord: String?
    var dispatcher: Dispatcher!

    public init(_ name: String) {
        self.name = name
    }

    public func peekto() -> String {
        return dispatcher.peekto(self)
    }
    public func readto() -> String {
        return dispatcher.readto(self)
    }
    public func output(_ record: String) {
        dispatcher.output(self, record: record)
    }

    open func run() {

    }

    internal func block() {
        _ = lock.wait(timeout: DispatchTime.distantFuture)
    }
    internal func unblock() {
        lock.signal()
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
