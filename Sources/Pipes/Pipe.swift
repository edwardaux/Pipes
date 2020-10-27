import Foundation

public class Pipe {
    private static var registeredStages: [RegisteredStage.Type] = []

    private let builder = Builder()

    public func add(_ stage: Stage, label: String? = nil) throws -> Pipe {
        try builder.add(stage, label: label)
        return self
    }

    public func add(label: String) throws -> Pipe {
        try builder.add(label: label)
        return self
    }

    public func end() -> Pipe {
        builder.end()
        return self
    }

    public func run() throws {
        let stages = try build()

        var errors: [Error] = []

        stages.forEach { stage in
            do {
                try stage.commit()
                stage.committed = true
            } catch let error {
                errors.append(error)
            }
        }

        if errors.isEmpty {
            let errorLock = NSLock()
            let group = DispatchGroup()
            stages.forEach { stage in
                group.enter()
                DispatchQueue.global().async {
                    do {
                        try stage.dispatch()
                    } catch let error {
                        errorLock.lock()
                        errors.append(error)
                        errorLock.unlock()
                    }
                    group.leave()
                }
            }
            group.wait()
        }

        if !errors.isEmpty {
            if let error = errors.compactMap({ $0 as? PipeError }).sorted(by: { $0.code < $1.code }).first {
                throw error
            } else {
                throw errors.first!
            }
        }
    }
}

extension Pipe {
    public convenience init(_ pipeSpec: String) throws {
        Pipe.registerBuiltInStages()

        self.init()

        let parser = try Parser(pipeSpec: pipeSpec)
        try parser.parse(into: self)
    }

    internal func build() throws -> [Stage] {
        return try builder.build()
    }
}

extension Pipe {
    static func register(_ stageType: RegisteredStage.Type) {
        if !registeredStages.contains(where: { $0 == stageType }) {
            registeredStages.append(stageType)
        }
    }

    static func deregister(_ stageType: RegisteredStage.Type) {
        registeredStages.removeAll(where: { $0 == stageType })
    }

    static func registeredStageType(for stageName: String) throws -> RegisteredStage.Type {
        for stageType in registeredStages {
            if stageType.allowedStageNames.contains(where: { $0.lowercased() == stageName.lowercased() }) {
                return stageType
            }
        }
        throw PipeError.stageNotFound(stageName: stageName)
    }

    static func registerBuiltInStages() {
        register(Console.self)
        register(Count.self)
        register(Diskr.self)
        register(Diskw.self)
        register(Diskwa.self)
        register(Fanin.self)
        register(Faninany.self)
        register(Help.self)
        register(Hole.self)
        register(Literal.self)
    }
}
