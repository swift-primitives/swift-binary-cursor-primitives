extension __BinaryCursorError {

    public enum Field: Sendable, Equatable {

        case reader

        case writer
    }
}

extension __BinaryCursorError.Field: CustomStringConvertible {

    public var description: String {
        switch self {
        case .reader: return "readerIndex"
        case .writer: return "writerIndex"
        }
    }
}
