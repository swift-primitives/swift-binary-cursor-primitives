public import Byte_Primitives
public import Index_Primitives
public import Span_Protocol_Primitives

extension Binary {

    public struct Cursor<Storage: Span.`Protocol` & ~Copyable & ~Escapable>: ~Copyable, ~Escapable
    where Storage.Element == Byte {

        public let storage: Storage

        @usableFromInline
        internal let _count: Index<Storage>.Count

        @usableFromInline
        internal var _readerIndex: Index<Storage>

        @usableFromInline
        internal var _writerIndex: Index<Storage>

        @inlinable
        @_lifetime(copy storage)
        public init(storage: consuming Storage) {
            let byteCount = storage.span.count
            self.storage = storage
            self._count = Index<Storage>.Count(Cardinal(UInt(byteCount)))
            self._readerIndex = .zero
            self._writerIndex = .zero
        }
    }
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    public var readerIndex: Index<Storage> {
        _readerIndex
    }

    public var writerIndex: Index<Storage> {
        _writerIndex
    }

    public var count: Index<Storage>.Count {
        _count
    }
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    @inlinable
    @_lifetime(copy storage)
    public init(
        storage: consuming Storage,
        readerIndex: Index<Storage>,
        writerIndex: Index<Storage>
    ) throws(Binary.Cursor<Storage>.Error) {
        let byteCount = storage.span.count
        let count = Index<Storage>.Count(Cardinal(UInt(byteCount)))

        guard writerIndex >= readerIndex else {
            throw .invariant(
                reader: Int(bitPattern: readerIndex),
                writer: Int(bitPattern: writerIndex)
            )
        }

        guard writerIndex <= count else {
            throw .bounds(
                .writer,
                value: Int(bitPattern: writerIndex),
                lower: 0,
                upper: Int(bitPattern: count)
            )
        }

        self.storage = storage
        self._count = count
        self._readerIndex = readerIndex
        self._writerIndex = writerIndex
    }
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    @inlinable
    @_lifetime(copy storage)
    public init(
        __unchecked: Void = (),
        storage: consuming Storage,
        readerIndex: Index<Storage>,
        writerIndex: Index<Storage>
    ) {
        let byteCount = storage.span.count
        let count = Index<Storage>.Count(Cardinal(UInt(byteCount)))
        precondition(writerIndex >= readerIndex)
        precondition(writerIndex <= count)
        self.storage = storage
        self._count = count
        self._readerIndex = readerIndex
        self._writerIndex = writerIndex
    }
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    @inlinable
    public var readableCount: Index<Storage>.Count {

        let reader = Int(bitPattern: _readerIndex)
        let writer = Int(bitPattern: _writerIndex)
        return Index<Storage>.Count(Cardinal(UInt(writer - reader)))
    }

    @inlinable
    public var writableCount: Index<Storage>.Count {

        let writer = Int(bitPattern: _writerIndex)
        let count = Int(bitPattern: _count)
        return Index<Storage>.Count(Cardinal(UInt(count - writer)))
    }

    @inlinable
    public var isReadable: Bool {
        _writerIndex > _readerIndex
    }

    @inlinable
    public var isWritable: Bool {
        _writerIndex < _count
    }
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    @inlinable
    public mutating func moveReaderIndex(
        by offset: Index<Storage>.Offset
    ) throws(Binary.Cursor<Storage>.Error) {
        let currentReader = Int(bitPattern: _readerIndex)
        let currentWriter = Int(bitPattern: _writerIndex)
        let offsetValue = Int(bitPattern: offset)

        let (newIndex, overflow) = currentReader.addingReportingOverflow(offsetValue)

        guard !overflow else {
            throw .overflow(.reader)
        }

        guard newIndex >= 0 else {
            throw .bounds(
                .reader,
                value: newIndex,
                lower: 0,
                upper: currentWriter
            )
        }

        guard newIndex <= currentWriter else {
            throw .invariant(reader: newIndex, writer: currentWriter)
        }

        _readerIndex = Index<Storage>(Ordinal(UInt(newIndex)))
    }

    @inlinable
    public mutating func moveReaderIndex(
        __unchecked: Void = (),
        by offset: Index<Storage>.Offset
    ) {
        let currentReader = Int(bitPattern: _readerIndex)
        let currentWriter = Int(bitPattern: _writerIndex)
        let offsetValue = Int(bitPattern: offset)

        let newIndex = currentReader &+ offsetValue
        precondition(newIndex >= 0 && newIndex <= currentWriter)
        _readerIndex = Index<Storage>(Ordinal(UInt(newIndex)))
    }
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    @inlinable
    public mutating func moveWriterIndex(
        by offset: Index<Storage>.Offset
    ) throws(Binary.Cursor<Storage>.Error) {
        let currentReader = Int(bitPattern: _readerIndex)
        let currentWriter = Int(bitPattern: _writerIndex)
        let count = Int(bitPattern: _count)
        let offsetValue = Int(bitPattern: offset)

        let (newIndex, overflow) = currentWriter.addingReportingOverflow(offsetValue)

        guard !overflow else {
            throw .overflow(.writer)
        }

        guard newIndex >= currentReader else {
            throw .invariant(reader: currentReader, writer: newIndex)
        }

        guard newIndex <= count else {
            throw .bounds(
                .writer,
                value: newIndex,
                lower: currentReader,
                upper: count
            )
        }

        _writerIndex = Index<Storage>(Ordinal(UInt(newIndex)))
    }

    @inlinable
    public mutating func moveWriterIndex(
        __unchecked: Void = (),
        by offset: Index<Storage>.Offset
    ) {
        let currentReader = Int(bitPattern: _readerIndex)
        let currentWriter = Int(bitPattern: _writerIndex)
        let count = Int(bitPattern: _count)
        let offsetValue = Int(bitPattern: offset)

        let newIndex = currentWriter &+ offsetValue
        precondition(newIndex >= currentReader && newIndex <= count)
        _writerIndex = Index<Storage>(Ordinal(UInt(newIndex)))
    }
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    @inlinable
    public mutating func setReaderIndex(
        to position: Index<Storage>
    ) throws(Binary.Cursor<Storage>.Error) {
        let currentWriter = Int(bitPattern: _writerIndex)
        let positionValue = Int(bitPattern: position)

        guard positionValue <= currentWriter else {
            throw .invariant(reader: positionValue, writer: currentWriter)
        }

        _readerIndex = position
    }

    @inlinable
    public mutating func setReaderIndex(
        __unchecked: Void = (),
        to position: Index<Storage>
    ) {
        let currentWriter = Int(bitPattern: _writerIndex)
        let positionValue = Int(bitPattern: position)
        precondition(positionValue <= currentWriter)
        _readerIndex = position
    }
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    @inlinable
    public mutating func setWriterIndex(
        to position: Index<Storage>
    ) throws(Binary.Cursor<Storage>.Error) {
        let currentReader = Int(bitPattern: _readerIndex)
        let count = Int(bitPattern: _count)
        let positionValue = Int(bitPattern: position)

        guard positionValue >= currentReader else {
            throw .invariant(reader: currentReader, writer: positionValue)
        }

        guard positionValue <= count else {
            throw .bounds(
                .writer,
                value: positionValue,
                lower: currentReader,
                upper: count
            )
        }

        _writerIndex = position
    }

    @inlinable
    public mutating func setWriterIndex(
        __unchecked: Void = (),
        to position: Index<Storage>
    ) {
        let currentReader = Int(bitPattern: _readerIndex)
        let count = Int(bitPattern: _count)
        let positionValue = Int(bitPattern: position)
        precondition(positionValue >= currentReader && positionValue <= count)
        _writerIndex = position
    }
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    @inlinable
    public mutating func reset() {
        _readerIndex = .zero
        _writerIndex = .zero
    }
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {

    @inlinable
    public var readableBytes: Swift.Span<Byte> {
        @_lifetime(borrow self)
        borrowing get {
            let readerIdx = Int(bitPattern: _readerIndex)
            let writerIdx = Int(bitPattern: _writerIndex)
            return storage.span.extracting(readerIdx..<writerIdx)
        }
    }

    @inlinable
    public func withReadableBytes<R, E: Swift.Error>(
        _ body: (UnsafeRawBufferPointer) throws(E) -> R
    ) throws(E) -> R {
        let span = readableBytes
        return try span.withUnsafeBytes {
            (rawBuffer: UnsafeRawBufferPointer) throws(E) -> R in
            try unsafe body(rawBuffer)
        }
    }
}
