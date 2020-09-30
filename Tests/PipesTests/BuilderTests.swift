import Foundation
@testable import Pipes
import XCTest

final class BuilderTests: XCTestCase {
    private class DummyStage: Stage, CustomDebugStringConvertible {
        let name: String
        init(_ name: String) {
            self.name = name
        }
        override public func run() throws {}
        var debugDescription: String { return name }
    }

    func testReturnToOriginal() throws {
        //
        //  literal abc | fo: fanout  | xlate upper | chop 15 | o: overlay | console
        //              ? fo:         |      spec 1-* 17      | o:
        //
        let pipe = try Pipe()
            .add(DummyStage("literal abc"))
            .add(DummyStage("fanout"), label: "fo")
            .add(DummyStage("xlate upper"))
            .add(DummyStage("chop 15"))
            .add(DummyStage("overlay"), label: "o")
            .add(DummyStage("console"))
            .end()
            .add(label: "fo")
            .add(DummyStage("spec 1-* 17"))
            .add(label: "o")
        let stages = try pipe.build()

        XCTAssertEqual(stages.count, 7)
        let s0 = stages[0] as! DummyStage
        let s1 = stages[1] as! DummyStage
        let s2 = stages[2] as! DummyStage
        let s3 = stages[3] as! DummyStage
        let s4 = stages[4] as! DummyStage
        let s5 = stages[5] as! DummyStage
        let s6 = stages[6] as! DummyStage

        XCTAssertEqual(s0.name, "literal abc")
        XCTAssertEqual(s0.inputStreams.count, 1)
        XCTAssertEqual(s0.inputStreams[0].producer, nil)
        XCTAssertEqual(s0.inputStreams[0].consumer, Stream.Endpoint(stage: s0, streamNo: 0))
        XCTAssertEqual(s0.outputStreams.count, 1)
        XCTAssertEqual(s0.outputStreams[0].producer, Stream.Endpoint(stage: s0, streamNo: 0))
        XCTAssertEqual(s0.outputStreams[0].consumer, Stream.Endpoint(stage: s1, streamNo: 0))

        XCTAssertEqual(s1.name, "fanout")
        XCTAssertEqual(s1.inputStreams.count, 2)
        XCTAssertEqual(s1.inputStreams[0].producer, Stream.Endpoint(stage: s0, streamNo: 0))
        XCTAssertEqual(s1.inputStreams[0].consumer, Stream.Endpoint(stage: s1, streamNo: 0))
        XCTAssertEqual(s1.inputStreams[1].producer, nil)
        XCTAssertEqual(s1.inputStreams[1].consumer, Stream.Endpoint(stage: s1, streamNo: 1))
        XCTAssertEqual(s1.outputStreams.count, 2)
        XCTAssertEqual(s1.outputStreams[0].producer, Stream.Endpoint(stage: s1, streamNo: 0))
        XCTAssertEqual(s1.outputStreams[0].consumer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s1.outputStreams[1].producer, Stream.Endpoint(stage: s1, streamNo: 1))
        XCTAssertEqual(s1.outputStreams[1].consumer, Stream.Endpoint(stage: s6, streamNo: 0))

        XCTAssertEqual(s2.name, "xlate upper")
        XCTAssertEqual(s2.inputStreams.count, 1)
        XCTAssertEqual(s2.inputStreams[0].producer, Stream.Endpoint(stage: s1, streamNo: 0))
        XCTAssertEqual(s2.inputStreams[0].consumer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s2.outputStreams.count, 1)
        XCTAssertEqual(s2.outputStreams[0].producer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s2.outputStreams[0].consumer, Stream.Endpoint(stage: s3, streamNo: 0))

        XCTAssertEqual(s3.name, "chop 15")
        XCTAssertEqual(s3.inputStreams.count, 1)
        XCTAssertEqual(s3.inputStreams[0].producer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s3.inputStreams[0].consumer, Stream.Endpoint(stage: s3, streamNo: 0))
        XCTAssertEqual(s3.outputStreams.count, 1)
        XCTAssertEqual(s3.outputStreams[0].producer, Stream.Endpoint(stage: s3, streamNo: 0))
        XCTAssertEqual(s3.outputStreams[0].consumer, Stream.Endpoint(stage: s4, streamNo: 0))

        XCTAssertEqual(s4.name, "overlay")
        XCTAssertEqual(s4.inputStreams.count, 2)
        XCTAssertEqual(s4.inputStreams[0].producer, Stream.Endpoint(stage: s3, streamNo: 0))
        XCTAssertEqual(s4.inputStreams[0].consumer, Stream.Endpoint(stage: s4, streamNo: 0))
        XCTAssertEqual(s4.inputStreams[1].producer, Stream.Endpoint(stage: s6, streamNo: 0))
        XCTAssertEqual(s4.inputStreams[1].consumer, Stream.Endpoint(stage: s4, streamNo: 1))
        XCTAssertEqual(s4.outputStreams.count, 2)
        XCTAssertEqual(s4.outputStreams[0].producer, Stream.Endpoint(stage: s4, streamNo: 0))
        XCTAssertEqual(s4.outputStreams[0].consumer, Stream.Endpoint(stage: s5, streamNo: 0))
        XCTAssertEqual(s4.outputStreams[1].producer, Stream.Endpoint(stage: s4, streamNo: 1))
        XCTAssertEqual(s4.outputStreams[1].consumer, nil)

        XCTAssertEqual(s5.name, "console")
        XCTAssertEqual(s5.inputStreams.count, 1)
        XCTAssertEqual(s5.inputStreams[0].producer, Stream.Endpoint(stage: s4, streamNo: 0))
        XCTAssertEqual(s5.inputStreams[0].consumer, Stream.Endpoint(stage: s5, streamNo: 0))
        XCTAssertEqual(s5.outputStreams.count, 1)
        XCTAssertEqual(s5.outputStreams[0].producer, Stream.Endpoint(stage: s5, streamNo: 0))
        XCTAssertEqual(s5.outputStreams[0].consumer, nil)

        XCTAssertEqual(s6.name, "spec 1-* 17")
        XCTAssertEqual(s6.inputStreams.count, 1)
        XCTAssertEqual(s6.inputStreams[0].producer, Stream.Endpoint(stage: s1, streamNo: 1))
        XCTAssertEqual(s6.inputStreams[0].consumer, Stream.Endpoint(stage: s6, streamNo: 0))
        XCTAssertEqual(s6.outputStreams.count, 1)
        XCTAssertEqual(s6.outputStreams[0].producer, Stream.Endpoint(stage: s6, streamNo: 0))
        XCTAssertEqual(s6.outputStreams[0].consumer, Stream.Endpoint(stage: s4, streamNo: 1))
    }

    func testCascade() throws {
        //
        //   lfd A | a: locate 10.5 /EXEC /     | literal All my EXECs   | > MY EXECS A
        // ? a:    | b: locate 10.7 /SCRIPT /   | literal All my SCRIPTs | > MY SCRIPTS A
        // ? b:    |    literal All other stuff | > OTHER STUFF A
        //
        let pipe = try Pipe()
            .add(DummyStage("lfd A"))
            .add(DummyStage("locate 10.5 /EXEC /"), label: "a")
            .add(DummyStage("literal All my EXECs"))
            .add(DummyStage("> MY EXECS A"))
            .end()
            .add(label: "a")
            .add(DummyStage("locate 10.7 /SCRIPT /"), label: "b")
            .add(DummyStage("literal All my SCRIPTs"))
            .add(DummyStage("> MY SCRIPTS A"))
            .end()
            .add(label: "b")
            .add(DummyStage("literal All other stuff"))
            .add(DummyStage("> OTHER STUFF A"))
        let stages = try pipe.build()

        XCTAssertEqual(stages.count, 9)
        let s0 = stages[0] as! DummyStage
        let s1 = stages[1] as! DummyStage
        let s2 = stages[2] as! DummyStage
        let s3 = stages[3] as! DummyStage
        let s4 = stages[4] as! DummyStage
        let s5 = stages[5] as! DummyStage
        let s6 = stages[6] as! DummyStage
        let s7 = stages[7] as! DummyStage
        let s8 = stages[8] as! DummyStage

        XCTAssertEqual(s0.name, "lfd A")
        XCTAssertEqual(s0.inputStreams.count, 1)
        XCTAssertEqual(s0.inputStreams[0].producer, nil)
        XCTAssertEqual(s0.inputStreams[0].consumer, Stream.Endpoint(stage: s0, streamNo: 0))
        XCTAssertEqual(s0.outputStreams.count, 1)
        XCTAssertEqual(s0.outputStreams[0].producer, Stream.Endpoint(stage: s0, streamNo: 0))
        XCTAssertEqual(s0.outputStreams[0].consumer, Stream.Endpoint(stage: s1, streamNo: 0))

        XCTAssertEqual(s1.name, "locate 10.5 /EXEC /")
        XCTAssertEqual(s1.inputStreams.count, 2)
        XCTAssertEqual(s1.inputStreams[0].producer, Stream.Endpoint(stage: s0, streamNo: 0))
        XCTAssertEqual(s1.inputStreams[0].consumer, Stream.Endpoint(stage: s1, streamNo: 0))
        XCTAssertEqual(s1.inputStreams[1].producer, nil)
        XCTAssertEqual(s1.inputStreams[1].consumer, Stream.Endpoint(stage: s1, streamNo: 1))
        XCTAssertEqual(s1.outputStreams.count, 2)
        XCTAssertEqual(s1.outputStreams[0].producer, Stream.Endpoint(stage: s1, streamNo: 0))
        XCTAssertEqual(s1.outputStreams[0].consumer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s1.outputStreams[1].producer, Stream.Endpoint(stage: s1, streamNo: 1))
        XCTAssertEqual(s1.outputStreams[1].consumer, Stream.Endpoint(stage: s4, streamNo: 0))

        XCTAssertEqual(s2.name, "literal All my EXECs")
        XCTAssertEqual(s2.inputStreams.count, 1)
        XCTAssertEqual(s2.inputStreams[0].producer, Stream.Endpoint(stage: s1, streamNo: 0))
        XCTAssertEqual(s2.inputStreams[0].consumer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s2.outputStreams.count, 1)
        XCTAssertEqual(s2.outputStreams[0].producer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s2.outputStreams[0].consumer, Stream.Endpoint(stage: s3, streamNo: 0))

        XCTAssertEqual(s3.name, "> MY EXECS A")
        XCTAssertEqual(s3.inputStreams.count, 1)
        XCTAssertEqual(s3.inputStreams[0].producer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s3.inputStreams[0].consumer, Stream.Endpoint(stage: s3, streamNo: 0))
        XCTAssertEqual(s3.outputStreams.count, 1)
        XCTAssertEqual(s3.outputStreams[0].producer, Stream.Endpoint(stage: s3, streamNo: 0))
        XCTAssertEqual(s3.outputStreams[0].consumer, nil)

        XCTAssertEqual(s4.name, "locate 10.7 /SCRIPT /")
        XCTAssertEqual(s4.inputStreams.count, 2)
        XCTAssertEqual(s4.inputStreams[0].producer, Stream.Endpoint(stage: s1, streamNo: 1))
        XCTAssertEqual(s4.inputStreams[0].consumer, Stream.Endpoint(stage: s4, streamNo: 0))
        XCTAssertEqual(s4.inputStreams[1].producer, nil)
        XCTAssertEqual(s4.inputStreams[1].consumer, Stream.Endpoint(stage: s4, streamNo: 1))
        XCTAssertEqual(s4.outputStreams.count, 2)
        XCTAssertEqual(s4.outputStreams[0].producer, Stream.Endpoint(stage: s4, streamNo: 0))
        XCTAssertEqual(s4.outputStreams[0].consumer, Stream.Endpoint(stage: s5, streamNo: 0))
        XCTAssertEqual(s4.outputStreams[1].producer, Stream.Endpoint(stage: s4, streamNo: 1))
        XCTAssertEqual(s4.outputStreams[1].consumer, Stream.Endpoint(stage: s7, streamNo: 0))

        XCTAssertEqual(s5.name, "literal All my SCRIPTs")
        XCTAssertEqual(s5.inputStreams.count, 1)
        XCTAssertEqual(s5.inputStreams[0].producer, Stream.Endpoint(stage: s4, streamNo: 0))
        XCTAssertEqual(s5.inputStreams[0].consumer, Stream.Endpoint(stage: s5, streamNo: 0))
        XCTAssertEqual(s5.outputStreams.count, 1)
        XCTAssertEqual(s5.outputStreams[0].producer, Stream.Endpoint(stage: s5, streamNo: 0))
        XCTAssertEqual(s5.outputStreams[0].consumer, Stream.Endpoint(stage: s6, streamNo: 0))

        XCTAssertEqual(s6.name, "> MY SCRIPTS A")
        XCTAssertEqual(s6.inputStreams.count, 1)
        XCTAssertEqual(s6.inputStreams[0].producer, Stream.Endpoint(stage: s5, streamNo: 0))
        XCTAssertEqual(s6.inputStreams[0].consumer, Stream.Endpoint(stage: s6, streamNo: 0))
        XCTAssertEqual(s6.outputStreams.count, 1)
        XCTAssertEqual(s6.outputStreams[0].producer, Stream.Endpoint(stage: s6, streamNo: 0))
        XCTAssertEqual(s6.outputStreams[0].consumer, nil)

        XCTAssertEqual(s7.name, "literal All other stuff")
        XCTAssertEqual(s7.inputStreams.count, 1)
        XCTAssertEqual(s7.inputStreams[0].producer, Stream.Endpoint(stage: s4, streamNo: 1))
        XCTAssertEqual(s7.inputStreams[0].consumer, Stream.Endpoint(stage: s7, streamNo: 0))
        XCTAssertEqual(s7.outputStreams.count, 1)
        XCTAssertEqual(s7.outputStreams[0].producer, Stream.Endpoint(stage: s7, streamNo: 0))
        XCTAssertEqual(s7.outputStreams[0].consumer, Stream.Endpoint(stage: s8, streamNo: 0))
        XCTAssertEqual(s7.outputStreams[0].producer?.stage, s7)
        XCTAssertEqual(s7.outputStreams[0].producer?.streamNo, 0)
        XCTAssertEqual(s7.outputStreams[0].consumer?.stage, s8)
        XCTAssertEqual(s7.outputStreams[0].consumer?.streamNo, 0)

        XCTAssertEqual(s8.name, "> OTHER STUFF A")
        XCTAssertEqual(s8.inputStreams.count, 1)
        XCTAssertEqual(s8.inputStreams[0].producer, Stream.Endpoint(stage: s7, streamNo: 0))
        XCTAssertEqual(s8.inputStreams[0].consumer, Stream.Endpoint(stage: s8, streamNo: 0))
        XCTAssertEqual(s8.outputStreams.count, 1)
        XCTAssertEqual(s8.outputStreams[0].producer, Stream.Endpoint(stage: s8, streamNo: 0))
        XCTAssertEqual(s8.outputStreams[0].consumer, nil)
    }

    func testTertiary() throws {
        //
        //   < detail records    | Lup: lookup 1.10 details | > matched details a
        // ? < reference records | Lup:                     | > unmatched details a
        // ? Lup:                | > unreferenced masters a
        //
        let pipe = try Pipe()
            .add(DummyStage("< detail records"))
            .add(DummyStage("lookup 1.10 details"), label: "Lup")
            .add(DummyStage("> matched details a"))
            .end()
            .add(DummyStage("< reference records"))
            .add(label: "Lup")
            .add(DummyStage("> unmatched details a"))
            .end()
            .add(label: "Lup")
            .add(DummyStage("> unreferenced masters a"))
        let stages = try pipe.build()

        XCTAssertEqual(stages.count, 6)
        let s0 = stages[0] as! DummyStage
        let s1 = stages[1] as! DummyStage
        let s2 = stages[2] as! DummyStage
        let s3 = stages[3] as! DummyStage
        let s4 = stages[4] as! DummyStage
        let s5 = stages[5] as! DummyStage

        XCTAssertEqual(s0.name, "< detail records")
        XCTAssertEqual(s0.inputStreams.count, 1)
        XCTAssertEqual(s0.inputStreams[0].producer, nil)
        XCTAssertEqual(s0.inputStreams[0].consumer, Stream.Endpoint(stage: s0, streamNo: 0))
        XCTAssertEqual(s0.outputStreams.count, 1)
        XCTAssertEqual(s0.outputStreams[0].producer, Stream.Endpoint(stage: s0, streamNo: 0))
        XCTAssertEqual(s0.outputStreams[0].consumer, Stream.Endpoint(stage: s1, streamNo: 0))

        XCTAssertEqual(s1.name, "lookup 1.10 details")
        XCTAssertEqual(s1.inputStreams.count, 3)
        XCTAssertEqual(s1.inputStreams[0].producer, Stream.Endpoint(stage: s0, streamNo: 0))
        XCTAssertEqual(s1.inputStreams[0].consumer, Stream.Endpoint(stage: s1, streamNo: 0))
        XCTAssertEqual(s1.inputStreams[1].producer, Stream.Endpoint(stage: s3, streamNo: 0))
        XCTAssertEqual(s1.inputStreams[1].consumer, Stream.Endpoint(stage: s1, streamNo: 1))
        XCTAssertEqual(s1.inputStreams[2].producer, nil)
        XCTAssertEqual(s1.inputStreams[2].consumer, Stream.Endpoint(stage: s1, streamNo: 2))
        XCTAssertEqual(s1.outputStreams.count, 3)
        XCTAssertEqual(s1.outputStreams[0].producer, Stream.Endpoint(stage: s1, streamNo: 0))
        XCTAssertEqual(s1.outputStreams[0].consumer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s1.outputStreams[1].producer, Stream.Endpoint(stage: s1, streamNo: 1))
        XCTAssertEqual(s1.outputStreams[1].consumer, Stream.Endpoint(stage: s4, streamNo: 0))
        XCTAssertEqual(s1.outputStreams[2].producer, Stream.Endpoint(stage: s1, streamNo: 2))
        XCTAssertEqual(s1.outputStreams[2].consumer, Stream.Endpoint(stage: s5, streamNo: 0))

        XCTAssertEqual(s2.name, "> matched details a")
        XCTAssertEqual(s2.inputStreams.count, 1)
        XCTAssertEqual(s2.inputStreams[0].producer, Stream.Endpoint(stage: s1, streamNo: 0))
        XCTAssertEqual(s2.inputStreams[0].consumer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s2.outputStreams.count, 1)
        XCTAssertEqual(s2.outputStreams[0].producer, Stream.Endpoint(stage: s2, streamNo: 0))
        XCTAssertEqual(s2.outputStreams[0].consumer, nil)

        XCTAssertEqual(s3.name, "< reference records")
        XCTAssertEqual(s3.inputStreams.count, 1)
        XCTAssertEqual(s3.inputStreams[0].producer, nil)
        XCTAssertEqual(s3.inputStreams[0].consumer, Stream.Endpoint(stage: s3, streamNo: 0))
        XCTAssertEqual(s3.outputStreams.count, 1)
        XCTAssertEqual(s3.outputStreams[0].producer, Stream.Endpoint(stage: s3, streamNo: 0))
        XCTAssertEqual(s3.outputStreams[0].consumer, Stream.Endpoint(stage: s1, streamNo: 1))

        XCTAssertEqual(s4.name, "> unmatched details a")
        XCTAssertEqual(s4.inputStreams.count, 1)
        XCTAssertEqual(s4.inputStreams[0].producer, Stream.Endpoint(stage: s1, streamNo: 1))
        XCTAssertEqual(s4.inputStreams[0].consumer, Stream.Endpoint(stage: s4, streamNo: 0))
        XCTAssertEqual(s4.outputStreams.count, 1)
        XCTAssertEqual(s4.outputStreams[0].producer, Stream.Endpoint(stage: s4, streamNo: 0))
        XCTAssertEqual(s4.outputStreams[0].consumer, nil)

        XCTAssertEqual(s5.name, "> unreferenced masters a")
        XCTAssertEqual(s5.inputStreams.count, 1)
        XCTAssertEqual(s5.inputStreams[0].producer, Stream.Endpoint(stage: s1, streamNo: 2))
        XCTAssertEqual(s5.inputStreams[0].consumer, Stream.Endpoint(stage: s5, streamNo: 0))
        XCTAssertEqual(s5.outputStreams.count, 1)
        XCTAssertEqual(s5.outputStreams[0].producer, Stream.Endpoint(stage: s5, streamNo: 0))
        XCTAssertEqual(s5.outputStreams[0].consumer, nil)
    }

    func testLabelNotDeclared() throws {
        do {
            _ = try Pipe().add(DummyStage("blah")).add(label: "a")
        } catch let error as PipeError {
            XCTAssertEqual(error, PipeError.labelNotDeclared(label: "a"))
        }
    }

    func testLabelAlreadyDeclared() throws {
        do {
            _ = try Pipe().add(DummyStage("blah"), label: "a").add(DummyStage("blah"), label: "a")
        } catch let error as PipeError {
            XCTAssertEqual(error, PipeError.labelAlreadyDeclared(label: "a"))
        }
    }

    func testReturnToOriginalStageNum() throws {
        //
        //  literal abc | fo: fanout  | xlate upper | chop 15 | o: overlay | console
        //              ? fo:         |      spec 1-* 17      | o:
        //
        let pipe = try Pipe()
            .add(DummyStage("literal abc"))
            .add(DummyStage("fanout"), label: "fo")
            .add(DummyStage("xlate upper"))
            .add(DummyStage("chop 15"))
            .add(DummyStage("overlay"), label: "o")
            .add(DummyStage("console"))
            .end()
            .add(label: "fo")
            .add(DummyStage("spec 1-* 17"))
            .add(label: "o")
        let stages = try pipe.build()

        XCTAssertEqual(stages.count, 7)
        let s0 = stages[0] as! DummyStage
        let s1 = stages[1] as! DummyStage
        let s2 = stages[2] as! DummyStage
        let s3 = stages[3] as! DummyStage
        let s4 = stages[4] as! DummyStage
        let s5 = stages[5] as! DummyStage
        let s6 = stages[6] as! DummyStage

        XCTAssertEqual(s0.stageNumber, 1)
        XCTAssertEqual(s1.stageNumber, 2)
        XCTAssertEqual(s2.stageNumber, 3)
        XCTAssertEqual(s3.stageNumber, 4)
        XCTAssertEqual(s4.stageNumber, 5)
        XCTAssertEqual(s5.stageNumber, 6)
        XCTAssertEqual(s6.stageNumber, 2)
    }

    func testCascadeStageNum() throws {
        //
        //   lfd A | a: locate 10.5 /EXEC /     | literal All my EXECs   | > MY EXECS A
        // ? a:    | b: locate 10.7 /SCRIPT /   | literal All my SCRIPTs | > MY SCRIPTS A
        // ? b:    |    literal All other stuff | > OTHER STUFF A
        //
        let pipe = try Pipe()
            .add(DummyStage("lfd A"))
            .add(DummyStage("locate 10.5 /EXEC /"), label: "a")
            .add(DummyStage("literal All my EXECs"))
            .add(DummyStage("> MY EXECS A"))
            .end()
            .add(label: "a")
            .add(DummyStage("locate 10.7 /SCRIPT /"), label: "b")
            .add(DummyStage("literal All my SCRIPTs"))
            .add(DummyStage("> MY SCRIPTS A"))
            .end()
            .add(label: "b")
            .add(DummyStage("literal All other stuff"))
            .add(DummyStage("> OTHER STUFF A"))
        let stages = try pipe.build()

        XCTAssertEqual(stages.count, 9)
        let s0 = stages[0] as! DummyStage
        let s1 = stages[1] as! DummyStage
        let s2 = stages[2] as! DummyStage
        let s3 = stages[3] as! DummyStage
        let s4 = stages[4] as! DummyStage
        let s5 = stages[5] as! DummyStage
        let s6 = stages[6] as! DummyStage
        let s7 = stages[7] as! DummyStage
        let s8 = stages[8] as! DummyStage

        XCTAssertEqual(s0.stageNumber, 1)
        XCTAssertEqual(s1.stageNumber, 2)
        XCTAssertEqual(s2.stageNumber, 3)
        XCTAssertEqual(s3.stageNumber, 4)
        XCTAssertEqual(s4.stageNumber, 2)
        XCTAssertEqual(s5.stageNumber, 3)
        XCTAssertEqual(s6.stageNumber, 4)
        XCTAssertEqual(s7.stageNumber, 2)
        XCTAssertEqual(s8.stageNumber, 3)
    }

    func testTertiaryStageNum() throws {
        //
        //   < detail records    | Lup: lookup 1.10 details | > matched details a
        // ? < reference records | Lup:                     | > unmatched details a
        // ? Lup:                | > unreferenced masters a
        //
        let pipe = try Pipe()
            .add(DummyStage("< detail records"))
            .add(DummyStage("lookup 1.10 details"), label: "Lup")
            .add(DummyStage("> matched details a"))
            .end()
            .add(DummyStage("< reference records"))
            .add(label: "Lup")
            .add(DummyStage("> unmatched details a"))
            .end()
            .add(label: "Lup")
            .add(DummyStage("> unreferenced masters a"))
        let stages = try pipe.build()

        XCTAssertEqual(stages.count, 6)
        let s0 = stages[0] as! DummyStage
        let s1 = stages[1] as! DummyStage
        let s2 = stages[2] as! DummyStage
        let s3 = stages[3] as! DummyStage
        let s4 = stages[4] as! DummyStage
        let s5 = stages[5] as! DummyStage

        XCTAssertEqual(s0.stageNumber, 1)
        XCTAssertEqual(s1.stageNumber, 2)
        XCTAssertEqual(s2.stageNumber, 3)
        XCTAssertEqual(s3.stageNumber, 1)
        XCTAssertEqual(s4.stageNumber, 3)
        XCTAssertEqual(s5.stageNumber, 2)
    }
}
