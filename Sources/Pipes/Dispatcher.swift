import Foundation

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
        let record = stage.inputStage?.outputRecord ?? "XXXX"
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

    func run(stages: [Stage]) {
        for i in 0..<stages.count {
            if i == 0 {
                stages[i].inputStage = nil
                stages[i].outputStage = stages[i+1]
            } else if i == stages.count-1 {
                stages[i].inputStage = stages[i-1]
                stages[i].outputStage = nil
            } else {
                stages[i].inputStage = stages[i-1]
                stages[i].outputStage = stages[i+1]
            }
            stages[i].dispatcher = self
        }

        stages.forEach { stage in
            DispatchQueue.global().async {
                stage.run()
            }
        }
    }
}
