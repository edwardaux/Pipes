import Foundation

/**
 * Convert from one data type to another.  Supported types are:
 *   B - Bit string. eg "0100100001101001"
 *   C - Character. eg "Hi"
 *   X - Hexadecimal number. eg "4869"
 */
public enum Conversion: String {
    case b2c
    case b2x
    case c2b
    case c2x
    case x2b
    case x2c

    static func from(_ string: String) -> Conversion? {
        return Conversion(rawValue: string.lowercased())
    }
}

extension Conversion {
    public func convert(_ string: String) throws -> String {
        switch self {
        case .b2c:
            guard string.count % 8 == 0 else { throw PipeError.conversionError(type: "B2C", reason: "The number of characters in a bit field is not divisible by 8", input: string) }
            let bytes: [UInt8] = try string.split(length: 8).map {
                guard let value = UInt8($0, radix: 2) else { throw PipeError.conversionError(type: "B2C", reason: "Invalid binary value", input: String($0)) }
                return value
            }
            guard let output = String(bytes: bytes, encoding: .utf8) else { throw PipeError.conversionError(type: "B2C", reason: "Unable to convert to UTF-8", input: string) }
            return output
        case .b2x:
            guard string.count % 8 == 0 else { throw PipeError.conversionError(type: "B2X", reason: "The number of characters in a bit field is not divisible by 8", input: string) }
            let bytes: [UInt8] = try string.split(length: 8).map {
                guard let value = UInt8($0, radix: 2) else { throw PipeError.conversionError(type: "B2X", reason: "Invalid binary value", input: String($0)) }
                return value
            }
            return bytes.map { String(format: "%X", $0) }.joined()
        case .c2b:
            guard let data = string.data(using: .utf8) else { throw PipeError.conversionError(type: "C2B", reason: "Unable to convert from UTF-8", input: string) }
            return data.map { String($0, radix: 2).aligned(alignment: .right, length: 8, pad: "0", truncate: true) }.joined()
        case .c2x:
            guard let data = string.data(using: .utf8) else { throw PipeError.conversionError(type: "C2X", reason: "Unable to convert from UTF-8", input: string) }
            return data.map { String(format: "%X", $0) }.joined()
        case .x2b:
            guard string.count % 2 == 0 else { throw PipeError.conversionError(type: "X2B", reason: "Odd number of characters in a hexadecimal field", input: string) }
            let bytes: [UInt8] = try string.split(length: 2).map {
                guard let value = UInt8($0, radix: 16) else { throw PipeError.conversionError(type: "X2B", reason: "Invalid hex value", input: String($0)) }
                return value
            }
            return bytes.map { String($0, radix: 2).aligned(alignment: .right, length: 8, pad: "0", truncate: true) }.joined()
        case .x2c:
            guard string.count % 2 == 0 else { throw PipeError.conversionError(type: "X2C", reason: "Odd number of characters in a hexadecimal field", input: string) }
            let bytes: [UInt8] = try string.split(length: 2).map {
                guard let value = UInt8($0, radix: 16) else { throw PipeError.conversionError(type: "X2C", reason: "Invalid hex value", input: String($0)) }
                return value
            }
            guard let output = String(bytes: bytes, encoding: .utf8) else { throw PipeError.conversionError(type: "X2C", reason: "Unable to convert to UTF-8", input: string) }
            return output
        }
    }
}
