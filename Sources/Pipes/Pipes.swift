import Foundation

class Stage {
    var dispatcher: Dispatcher!
    private let lock = DispatchSemaphore(value: 0)

    func peekto() -> String {
        return dispatcher.peekto(self)
    }
    func readto() -> String {
        return dispatcher.readto(self)
    }
    func output(_ record: String) {
        dispatcher.output(self, record: record)
    }

    func run() {

    }

    func block() {
        _ = lock.wait(timeout: DispatchTime.distantFuture)
    }
    func unblock() {
        lock.signal()
    }

    var inputStage: Stage?
    var inputRecord: String?
    var outputStage: Stage?
    var outputRecord: String?
}

class StageA: Stage {
    override init() {
    }
    override func run() {
        output("a")
        output("b")
        output("c")
        print("Stage A DONE")
    }
}
class StageB: Stage {
    override init() {
    }
    override func run() {
        let record1 = peekto()
        output(record1)
        _ = readto()

        let record2 = peekto()
        output(record2)
        _ = readto()

        let record3 = peekto()
        output(record3)
        _ = readto()
        print("Stage B DONE")
    }
}
class StageC: Stage {
    override init() {
    }
    override func run() {
        print(readto())
        print(readto())
        print(readto())
        print("Stage C DONE")
    }
}

func synchronized<T>(_ lock: AnyObject, _ body: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try body()
}

class Dispatcher {
    func peekto(_ stage: Stage) -> String {
        print("\(stage) attempting to peek")
        if stage.inputRecord == nil {
            print("\(stage) blocked while peeking")
            stage.block()
            print("\(stage) unblocked while peeking")
        }
        let record = stage.inputStage?.outputRecord ?? "XXXX"
        print("\(stage) successfully peeked: "+record)
        print("\(stage) peek returning "+record)
        return record
    }
    func readto(_ stage: Stage) -> String {
        print("\(stage) attempting to read")
        if stage.inputRecord == nil {
            print("\(stage) blocked while reading")
            stage.block()
            print("\(stage) unblocked while reading")
        }
        let record = stage.inputRecord!
        print("\(stage) successfully read: "+record)
        stage.inputRecord = nil
        stage.inputStage?.outputRecord = nil
        print("\(stage) reading unblocks \(stage.inputStage!)")
        stage.inputStage?.unblock()
        print("\(stage) read returning "+record)
        return record
    }
    func output(_ stage: Stage, record: String) {
        print("\(stage) attempting to output "+record)
        if stage.outputStage != nil {
            if stage.outputRecord != nil {
                print("\(stage) blocked while outputting "+record)
                stage.block()
                print("\(stage) unblocked while outputting "+record)
            }
            print("\(stage) outputting "+record)
            stage.outputRecord = record
            stage.outputStage?.inputRecord = record
            print("\(stage) output unblocks \(stage.outputStage!)")
            stage.outputStage?.unblock()
        }
    }

    func run() {
        let stageA = StageA()
        let stageB = StageB()
        let stageC = StageC()

        stageA.inputStage = nil
        stageA.outputStage = stageB
        stageA.dispatcher = self
        stageB.inputStage = stageA
        stageB.outputStage = stageC
        stageB.dispatcher = self
        stageC.inputStage = stageB
        stageC.outputStage = nil
        stageC.dispatcher = self

        let stages = [ stageA, stageB, stageC ]
        stages.forEach { stage in
            DispatchQueue.global().async {
                stage.run()
            }
        }
    }
}
