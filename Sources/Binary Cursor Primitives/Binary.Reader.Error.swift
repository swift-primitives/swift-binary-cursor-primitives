public enum __BinaryReaderError: Swift.Error, Sendable, Equatable {

    case bounds(value: Int, lower: Int, upper: Int)

    case overflow
}

extension Binary.Reader where Storage: ~Copyable & ~Escapable {

    public typealias Error = __BinaryReaderError
}

extension __BinaryReaderError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .bounds(let value, let lower, let upper):
            return "readerIndex out of bounds (was \(value), valid: \(lower)...\(upper))"

        case .overflow:
            return "readerIndex arithmetic overflow"
        }
    }
}
