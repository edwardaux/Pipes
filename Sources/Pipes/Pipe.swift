import Foundation

public class Pipe {
    private let builder = PipeBuilder()

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

    internal func build() throws -> [Stage] {
        return try builder.build()
    }

    public func run() throws {
        let stages = try build()

        let errorLock = NSLock()
        var errors: [Error] = []
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

        if let error = errors.compactMap({ $0 as? PipeError }).sorted(by: { $0.code < $1.code }).first {
            throw error
        }
    }
}
