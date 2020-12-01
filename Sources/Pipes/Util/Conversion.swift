import Foundation

/**
 * Convert from one data type to another.  Types are:
 *   B - Bit String. eg "00110010"
 *   D - Signed (negative sign optional) decimal. eg "-123"
 *   F - Signed floating point number.  eg. 1.234
 *   I - Internal binary representation
 *   X - Hexadecimal number (even number of digits). eg. "0AF1"
 */
public enum Conversion: String {
    case b2i
    case b2d
    case b2f
    case b2x

    case d2b
    case d2i
    case d2f
    case d2x

    case f2b
    case f2i
    case f2d
    case f2x

    case i2b
    case i2d
    case i2f
    case i2x

    case x2b
    case x2i
    case x2d
    case x2f

    static func from(_ string: String) -> Conversion? {
        return Conversion(rawValue: string.lowercased())
    }
}

extension Conversion {
    public func convert(_ string: String) throws -> String {
        switch self {
        case .b2i:
            guard string.count % 8 == 0 else { throw PipeError.conversionError(type: "B2I", code: 36, input: string) }
            break
        case .b2d:
            break
        case .b2f:
            break
        case .b2x:
            break
        case .d2b:
            break
        case .d2i:
            break
        case .d2f:
            break
        case .d2x:
            break
        case .f2b:
            break
        case .f2i:
            break
        case .f2d:
            break
        case .f2x:
            break
        case .i2b:
            break
        case .i2d:
            break
        case .i2f:
            break
        case .i2x:
            break
        case .x2b:
            break
        case .x2i:
            break
        case .x2d:
            break
        case .x2f:
            break
        }
        return string
    }
}
