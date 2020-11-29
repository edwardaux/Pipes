import Foundation

/**
 * Convert from one data type to another.  Types are:
 *   B - Bit String. eg "00110010"
 *   C - Internal binary representation
 *   D - Signed (negative sign optional) decimal. eg "-123"
 *   F - Signed floating point number.  eg. 1.234
 *   I - ISO Date format. eg [yy]yymmdd[hh[mm[ss]]]
 *   P - Packed decimal. eg -1.234
 *   V - Prefixed field length (2 bytes length prefix). eg. "\u0000\u0004abcd"
 *   X - Hexadecimal number (even number of digits). eg. "0AF1"
 */
public enum Conversion {
    case b2c
    case b2d
    case b2f
    case b2i
    case b2p
    case b2v
    case b2x

    case c2b
    case c2d
    case c2f
    case c2i
    case c2p
    case c2v
    case c2x

    case d2b
    case d2c
    case d2x

    case f2b
    case f2c
    case f2x

    case i2b
    case i2c
    case i2x

    case p2b
    case p2c
    case p2x

    case v2b
    case v2c
    case v2x

    case x2b
    case x2c
    case x2d
    case x2f
    case x2i
    case x2p
    case x2v
}

extension Conversion {
    public func convert(_ string: String) -> String {
        // TODO perform conversion
        return string
    }
}
