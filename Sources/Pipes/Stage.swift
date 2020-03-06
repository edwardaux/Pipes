import Foundation

open class Stage {
    var dispatcher: Dispatcher!

    private let lock = DispatchSemaphore(value: 0)

    public init() {
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

    var inputStage: Stage?
    var inputRecord: String?
    var outputStage: Stage?
    var outputRecord: String?
}
