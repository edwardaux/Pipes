public struct Options: Equatable {
    public static let `default` = Options(stageSep: "|", escape: nil, endChar: nil)

    let stageSep: Character
    let escape: Character?
    let endChar: Character?
}
