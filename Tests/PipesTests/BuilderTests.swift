//import Foundation
//@testable import Pipes
//import XCTest
//
//final class BuilderTests: XCTestCase {
//    func testReturnToOriginal() {
//        /*
//          literal abc | fo: fanout  | xlate upper | chop 15 | o: overlay | console
//        ? fo:         | spec 1-* 17 | o:
//        */
//        let pipeline = PipeBuilder()
//            .add(stage: Stage("literal abc"))
//            .add(stage: Stage("fanout"), label: "fo")
//            .add(stage: Stage("xlate upper"))
//            .add(stage: Stage("chop 15"))
//            .add(stage: Stage("overlay"), label: "o")
//            .add(stage: Stage("console"))
//            .end()
//            .add(label: "fo")
//            .add(stage: Stage("spec 1-* 17"))
//            .add(label: "o")
//            .build()
//
//        XCTAssertEqual(pipeline.stages.count, 7)
//        let s0 = pipeline.stages[0]
//        let s1 = pipeline.stages[1]
//        let s2 = pipeline.stages[2]
//        let s3 = pipeline.stages[3]
//        let s4 = pipeline.stages[4]
//        let s5 = pipeline.stages[5]
//        let s6 = pipeline.stages[6]
//
//        XCTAssertEqual(s0.name, "literal abc")
//        XCTAssertEqual(s0.inputStreams.count, 0)
//        XCTAssertEqual(s0.outputStreams.count, 1)
//        XCTAssertEqual(s0.outputStreams[0].producer?.stage, s0)
//        XCTAssertEqual(s0.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s0.outputStreams[0].consumer?.stage, s1)
//        XCTAssertEqual(s0.outputStreams[0].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s1.name, "fanout")
//        XCTAssertEqual(s1.inputStreams.count, 1)
//        XCTAssertEqual(s1.inputStreams[0].producer?.stage, s0)
//        XCTAssertEqual(s1.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s1.inputStreams[0].consumer?.stage, s1)
//        XCTAssertEqual(s1.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s1.outputStreams.count, 2)
//        XCTAssertEqual(s1.outputStreams[0].producer?.stage, s1)
//        XCTAssertEqual(s1.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s1.outputStreams[0].consumer?.stage, s2)
//        XCTAssertEqual(s1.outputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s1.outputStreams[1].producer?.stage, s1)
//        XCTAssertEqual(s1.outputStreams[1].producer?.streamNo, 1)
//        XCTAssertEqual(s1.outputStreams[1].consumer?.stage, s6)
//        XCTAssertEqual(s1.outputStreams[1].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s2.name, "xlate upper")
//        XCTAssertEqual(s2.inputStreams.count, 1)
//        XCTAssertEqual(s2.inputStreams[0].producer?.stage, s1)
//        XCTAssertEqual(s2.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s2.inputStreams[0].consumer?.stage, s2)
//        XCTAssertEqual(s2.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s2.outputStreams.count, 1)
//        XCTAssertEqual(s2.outputStreams[0].producer?.stage, s2)
//        XCTAssertEqual(s2.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s2.outputStreams[0].consumer?.stage, s3)
//        XCTAssertEqual(s2.outputStreams[0].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s3.name, "chop 15")
//        XCTAssertEqual(s3.inputStreams.count, 1)
//        XCTAssertEqual(s3.inputStreams[0].producer?.stage, s2)
//        XCTAssertEqual(s3.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s3.inputStreams[0].consumer?.stage, s3)
//        XCTAssertEqual(s3.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s3.outputStreams.count, 1)
//        XCTAssertEqual(s3.outputStreams[0].producer?.stage, s3)
//        XCTAssertEqual(s3.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s3.outputStreams[0].consumer?.stage, s4)
//        XCTAssertEqual(s3.outputStreams[0].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s4.name, "overlay")
//        XCTAssertEqual(s4.inputStreams.count, 2)
//        XCTAssertEqual(s4.inputStreams[0].producer?.stage, s3)
//        XCTAssertEqual(s4.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s4.inputStreams[0].consumer?.stage, s4)
//        XCTAssertEqual(s4.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s4.inputStreams[1].producer?.stage, s6)
//        XCTAssertEqual(s4.inputStreams[1].producer?.streamNo, 0)
//        XCTAssertEqual(s4.inputStreams[1].consumer?.stage, s4)
//        XCTAssertEqual(s4.inputStreams[1].consumer?.streamNo, 1)
//        XCTAssertEqual(s4.outputStreams.count, 1)
//        XCTAssertEqual(s4.outputStreams[0].producer?.stage, s4)
//        XCTAssertEqual(s4.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s4.outputStreams[0].consumer?.stage, s5)
//        XCTAssertEqual(s4.outputStreams[0].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s5.name, "console")
//        XCTAssertEqual(s5.inputStreams.count, 1)
//        XCTAssertEqual(s5.inputStreams[0].producer?.stage, s4)
//        XCTAssertEqual(s5.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s5.inputStreams[0].consumer?.stage, s5)
//        XCTAssertEqual(s5.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s5.outputStreams.count, 0)
//
//        XCTAssertEqual(s6.name, "spec 1-* 17")
//        XCTAssertEqual(s6.inputStreams.count, 1)
//        XCTAssertEqual(s6.inputStreams[0].producer?.stage, s1)
//        XCTAssertEqual(s6.inputStreams[0].producer?.streamNo, 1)
//        XCTAssertEqual(s6.inputStreams[0].consumer?.stage, s6)
//        XCTAssertEqual(s6.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s6.outputStreams.count, 1)
//        XCTAssertEqual(s6.outputStreams[0].producer?.stage, s6)
//        XCTAssertEqual(s6.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s6.outputStreams[0].consumer?.stage, s4)
//        XCTAssertEqual(s6.outputStreams[0].consumer?.streamNo, 1)
//    }
//
//    func testCascade() {
//        /*
//          lfd A | a: locate 10.5 /EXEC /     | literal All my EXECs   | > MY EXECS A
//        ? a:    | b: locate 10.7 /SCRIPT /   | literal All my SCRIPTs | > MY SCRIPTS A
//        ? b:    |    literal All other stuff | > OTHER STUFF A
//        */
//        let pipeline = PipeBuilder()
//            .add(stage: Stage("lfd A"))
//            .add(stage: Stage("locate 10.5 /EXEC /"), label: "a")
//            .add(stage: Stage("literal All my EXECs"))
//            .add(stage: Stage("> MY EXECS A"))
//            .end()
//            .add(label: "a")
//            .add(stage: Stage("locate 10.7 /SCRIPT /"), label: "b")
//            .add(stage: Stage("literal All my SCRIPTs"))
//            .add(stage: Stage("> MY SCRIPTS A"))
//            .end()
//            .add(label: "b")
//            .add(stage: Stage("literal All other stuff"))
//            .add(stage: Stage("> OTHER STUFF A"))
//            .build()
//
//        XCTAssertEqual(pipeline.stages.count, 9)
//        let s0 = pipeline.stages[0]
//        let s1 = pipeline.stages[1]
//        let s2 = pipeline.stages[2]
//        let s3 = pipeline.stages[3]
//        let s4 = pipeline.stages[4]
//        let s5 = pipeline.stages[5]
//        let s6 = pipeline.stages[6]
//        let s7 = pipeline.stages[7]
//        let s8 = pipeline.stages[8]
//
//        XCTAssertEqual(s0.name, "lfd A")
//        XCTAssertEqual(s0.inputStreams.count, 0)
//        XCTAssertEqual(s0.outputStreams.count, 1)
//        XCTAssertEqual(s0.outputStreams[0].producer?.stage, s0)
//        XCTAssertEqual(s0.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s0.outputStreams[0].consumer?.stage, s1)
//        XCTAssertEqual(s0.outputStreams[0].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s1.name, "locate 10.5 /EXEC /")
//        XCTAssertEqual(s1.inputStreams.count, 1)
//        XCTAssertEqual(s1.inputStreams[0].producer?.stage, s0)
//        XCTAssertEqual(s1.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s1.inputStreams[0].consumer?.stage, s1)
//        XCTAssertEqual(s1.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s1.outputStreams.count, 2)
//        XCTAssertEqual(s1.outputStreams[0].producer?.stage, s1)
//        XCTAssertEqual(s1.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s1.outputStreams[0].consumer?.stage, s2)
//        XCTAssertEqual(s1.outputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s1.outputStreams[1].producer?.stage, s1)
//        XCTAssertEqual(s1.outputStreams[1].producer?.streamNo, 1)
//        XCTAssertEqual(s1.outputStreams[1].consumer?.stage, s4)
//        XCTAssertEqual(s1.outputStreams[1].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s2.name, "literal All my EXECs")
//        XCTAssertEqual(s2.inputStreams.count, 1)
//        XCTAssertEqual(s2.inputStreams[0].producer?.stage, s1)
//        XCTAssertEqual(s2.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s2.inputStreams[0].consumer?.stage, s2)
//        XCTAssertEqual(s2.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s2.outputStreams.count, 1)
//        XCTAssertEqual(s2.outputStreams[0].producer?.stage, s2)
//        XCTAssertEqual(s2.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s2.outputStreams[0].consumer?.stage, s3)
//        XCTAssertEqual(s2.outputStreams[0].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s3.name, "> MY EXECS A")
//        XCTAssertEqual(s3.inputStreams.count, 1)
//        XCTAssertEqual(s3.inputStreams[0].producer?.stage, s2)
//        XCTAssertEqual(s3.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s3.inputStreams[0].consumer?.stage, s3)
//        XCTAssertEqual(s3.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s3.outputStreams.count, 0)
//
//        XCTAssertEqual(s4.name, "locate 10.7 /SCRIPT /")
//        XCTAssertEqual(s4.inputStreams.count, 1)
//        XCTAssertEqual(s4.inputStreams[0].producer?.stage, s1)
//        XCTAssertEqual(s4.inputStreams[0].producer?.streamNo, 1)
//        XCTAssertEqual(s4.inputStreams[0].consumer?.stage, s4)
//        XCTAssertEqual(s4.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s4.outputStreams.count, 2)
//        XCTAssertEqual(s4.outputStreams[0].producer?.stage, s4)
//        XCTAssertEqual(s4.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s4.outputStreams[0].consumer?.stage, s5)
//        XCTAssertEqual(s4.outputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s4.outputStreams[1].producer?.stage, s4)
//        XCTAssertEqual(s4.outputStreams[1].producer?.streamNo, 1)
//        XCTAssertEqual(s4.outputStreams[1].consumer?.stage, s7)
//        XCTAssertEqual(s4.outputStreams[1].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s5.name, "literal All my SCRIPTs")
//        XCTAssertEqual(s5.inputStreams.count, 1)
//        XCTAssertEqual(s5.inputStreams[0].producer?.stage, s4)
//        XCTAssertEqual(s5.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s5.inputStreams[0].consumer?.stage, s5)
//        XCTAssertEqual(s5.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s5.outputStreams.count, 1)
//        XCTAssertEqual(s5.outputStreams[0].producer?.stage, s5)
//        XCTAssertEqual(s5.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s5.outputStreams[0].consumer?.stage, s6)
//        XCTAssertEqual(s5.outputStreams[0].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s6.name, "> MY SCRIPTS A")
//        XCTAssertEqual(s6.inputStreams.count, 1)
//        XCTAssertEqual(s6.inputStreams[0].producer?.stage, s5)
//        XCTAssertEqual(s6.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s6.inputStreams[0].consumer?.stage, s6)
//        XCTAssertEqual(s6.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s6.outputStreams.count, 0)
//
//        XCTAssertEqual(s7.name, "literal All other stuff")
//        XCTAssertEqual(s7.inputStreams.count, 1)
//        XCTAssertEqual(s7.inputStreams[0].producer?.stage, s4)
//        XCTAssertEqual(s7.inputStreams[0].producer?.streamNo, 1)
//        XCTAssertEqual(s7.inputStreams[0].consumer?.stage, s7)
//        XCTAssertEqual(s7.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s7.outputStreams.count, 1)
//        XCTAssertEqual(s7.outputStreams[0].producer?.stage, s7)
//        XCTAssertEqual(s7.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s7.outputStreams[0].consumer?.stage, s8)
//        XCTAssertEqual(s7.outputStreams[0].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s8.name, "> OTHER STUFF A")
//        XCTAssertEqual(s8.inputStreams.count, 1)
//        XCTAssertEqual(s8.inputStreams[0].producer?.stage, s7)
//        XCTAssertEqual(s8.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s8.inputStreams[0].consumer?.stage, s8)
//        XCTAssertEqual(s8.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s8.outputStreams.count, 0)
//
//    }
//
//    func testTertiary() {
//        /*
//          < detail records    | Lup: lookup 1.10 details | > matched details a
//        ? < reference records | Lup:                     | > unmatched details a
//        ? Lup:                | > unreferenced masters a
//        */
//        let pipeline = PipeBuilder()
//            .add(stage: Stage("< detail records"))
//            .add(stage: Stage("lookup 1.10 details"), label: "Lup")
//            .add(stage: Stage("> matched details a"))
//            .end()
//            .add(stage: Stage("< reference records"))
//            .add(label: "Lup")
//            .add(stage: Stage("> unmatched details a"))
//            .end()
//            .add(label: "Lup")
//            .add(stage: Stage("> unreferenced masters a"))
//            .build()
//
//        XCTAssertEqual(pipeline.stages.count, 6)
//        let s0 = pipeline.stages[0]
//        let s1 = pipeline.stages[1]
//        let s2 = pipeline.stages[2]
//        let s3 = pipeline.stages[3]
//        let s4 = pipeline.stages[4]
//        let s5 = pipeline.stages[5]
//
//        XCTAssertEqual(s0.name, "< detail records")
//        XCTAssertEqual(s0.inputStreams.count, 0)
//        XCTAssertEqual(s0.outputStreams.count, 1)
//        XCTAssertEqual(s0.outputStreams[0].producer?.stage, s0)
//        XCTAssertEqual(s0.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s0.outputStreams[0].consumer?.stage, s1)
//        XCTAssertEqual(s0.outputStreams[0].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s1.name, "lookup 1.10 details")
//        XCTAssertEqual(s1.inputStreams.count, 2)
//        XCTAssertEqual(s1.inputStreams[0].producer?.stage, s0)
//        XCTAssertEqual(s1.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s1.inputStreams[0].consumer?.stage, s1)
//        XCTAssertEqual(s1.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s1.inputStreams[1].producer?.stage, s3)
//        XCTAssertEqual(s1.inputStreams[1].producer?.streamNo, 0)
//        XCTAssertEqual(s1.inputStreams[1].consumer?.stage, s1)
//        XCTAssertEqual(s1.inputStreams[1].consumer?.streamNo, 1)
//        XCTAssertEqual(s1.outputStreams.count, 3)
//        XCTAssertEqual(s1.outputStreams[0].producer?.stage, s1)
//        XCTAssertEqual(s1.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s1.outputStreams[0].consumer?.stage, s2)
//        XCTAssertEqual(s1.outputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s1.outputStreams[1].producer?.stage, s1)
//        XCTAssertEqual(s1.outputStreams[1].producer?.streamNo, 1)
//        XCTAssertEqual(s1.outputStreams[1].consumer?.stage, s4)
//        XCTAssertEqual(s1.outputStreams[1].consumer?.streamNo, 0)
//        XCTAssertEqual(s1.outputStreams[2].producer?.stage, s1)
//        XCTAssertEqual(s1.outputStreams[2].producer?.streamNo, 2)
//        XCTAssertEqual(s1.outputStreams[2].consumer?.stage, s5)
//        XCTAssertEqual(s1.outputStreams[2].consumer?.streamNo, 0)
//
//        XCTAssertEqual(s2.name, "> matched details a")
//        XCTAssertEqual(s2.inputStreams.count, 1)
//        XCTAssertEqual(s2.inputStreams[0].producer?.stage, s1)
//        XCTAssertEqual(s2.inputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s2.inputStreams[0].consumer?.stage, s2)
//        XCTAssertEqual(s2.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s2.outputStreams.count, 0)
//
//        XCTAssertEqual(s3.name, "< reference records")
//        XCTAssertEqual(s3.inputStreams.count, 0)
//        XCTAssertEqual(s3.outputStreams.count, 1)
//        XCTAssertEqual(s3.outputStreams[0].producer?.stage, s3)
//        XCTAssertEqual(s3.outputStreams[0].producer?.streamNo, 0)
//        XCTAssertEqual(s3.outputStreams[0].consumer?.stage, s1)
//        XCTAssertEqual(s3.outputStreams[0].consumer?.streamNo, 1)
//
//        XCTAssertEqual(s4.name, "> unmatched details a")
//        XCTAssertEqual(s4.inputStreams.count, 1)
//        XCTAssertEqual(s4.inputStreams[0].producer?.stage, s1)
//        XCTAssertEqual(s4.inputStreams[0].producer?.streamNo, 1)
//        XCTAssertEqual(s4.inputStreams[0].consumer?.stage, s4)
//        XCTAssertEqual(s4.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s4.outputStreams.count, 0)
//
//        XCTAssertEqual(s5.name, "> unreferenced masters a")
//        XCTAssertEqual(s5.inputStreams.count, 1)
//        XCTAssertEqual(s5.inputStreams[0].producer?.stage, s1)
//        XCTAssertEqual(s5.inputStreams[0].producer?.streamNo, 2)
//        XCTAssertEqual(s5.inputStreams[0].consumer?.stage, s5)
//        XCTAssertEqual(s5.inputStreams[0].consumer?.streamNo, 0)
//        XCTAssertEqual(s5.outputStreams.count, 0)
//    }
//    static var allTests = [
//        ("testReturnToOriginal", testReturnToOriginal),
//    ]
//}
