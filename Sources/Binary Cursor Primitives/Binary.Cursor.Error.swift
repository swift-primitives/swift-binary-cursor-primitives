public enum __BinaryCursorError: Swift.Error, Sendable, Equatable {

    case invariant(reader: Int, writer: Int)

    case bounds(Field, value: Int, lower: Int, upper: Int)

    case overflow(Field)
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    public typealias Error = __BinaryCursorError
}

extension __BinaryCursorError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .invariant(let reader, let writer):
            return "readerIndex must be <= writerIndex (reader=\(reader), writer=\(writer))"

        case .bounds(let field, let value, let lower, let upper):
            return "\(field) out of bounds (was \(value), valid: \(lower)...\(upper))"

        case .overflow(let field):
            return "\(field) index arithmetic overflow"
        }
    }
}
