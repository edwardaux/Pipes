import Foundation
import Pipes
import XCTest

final class BuilderTests: XCTestCase {
    func testReturnToOriginal() {
        /*
          literal abc | fo: fanout  | xlate upper | chop 15| o: overlay | console
        ? fo:         | spec 1-* 17 | o:
        */
        PipeBuilder()
            .add(stage: Stage("literal abc"))
            .add(stage: Stage("fanout"), label: "fo")
            .add(stage: Stage("xlate upper"))
            .add(stage: Stage("chop 15"))
            .add(stage: Stage("overlay"), label: "o")
            .add(stage: Stage("console"))
            .end()
            .add(label: "fo")
            .add(stage: Stage("spec 1-* 17"))
            .add(label: "o")
            .build()
    }

    func testCascade() {
        /*
          lfd A | a: locate 10.5 /EXEC /     | literal All my EXECs   | > MY EXECS A
        ? a:    | b: locate 10.7 /SCRIPT /   | literal All my SCRIPTs | > MY SCRIPTS A
        ? b:    |    literal All other stuff | > OTHER STUFF A
        */
        PipeBuilder()
            .add(stage: Stage("lfd A"))
            .add(stage: Stage("locate 10.5 /EXEC /"), label: "a")
            .add(stage: Stage("literal All my EXECs"))
            .add(stage: Stage("> MY EXECS A"))
            .end()
            .add(label: "a")
            .add(stage: Stage("locate 10.7 /SCRIPT /"), label: "b")
            .add(stage: Stage("literal All my SCRIPTs"))
            .add(stage: Stage("> MY SCRIPTS A"))
            .end()
            .add(label: "b")
            .add(stage: Stage("literal All other stuff"))
            .add(stage: Stage("> OTHER STUFF A"))
            .build()
    }

    func testTertiary() {
        /*
          < detail records    | Lup: lookup 1.10 details | > matched details a
        ? < reference records | Lup:                     | > unmatched details a
        ? Lup:                | > unreferenced masters a
        */
        PipeBuilder()
            .add(stage: Stage("< detail records"))
            .add(stage: Stage("lookup 1.10 details"), label: "Lup")
            .add(stage: Stage("> matched details a"))
            .end()
            .add(stage: Stage("< reference records"))
            .add(label: "Lup")
            .add(stage: Stage("> unmatched details a"))
            .end()
            .add(label: "Lup")
            .add(stage: Stage("> unreferenced masters a"))
            .build()
    }
    static var allTests = [
        ("testReturnToOriginal", testReturnToOriginal),
    ]
}
