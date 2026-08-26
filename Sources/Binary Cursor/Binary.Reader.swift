public import Byte
public import Index
public import Span_Protocol

extension Binary {

    public struct Reader<Storage: Span.`Protocol` & ~Copyable & ~Escapable>: ~Copyable, ~Escapable
    where Storage.Element == Byte {

        public let storage: Storage

        @usableFromInline
        internal let _count: Index<Storage>.Count

        @usableFromInline
        internal var _readerIndex: Index<Storage>

        @inlinable
        @_lifetime(copy storage)
        public init(storage: consuming Storage) {
            let byteCount = storage.span.count
            self.storage = storage
            self._count = Index<Storage>.Count(Cardinal(UInt(byteCount)))
            self._readerIndex = .zero
        }
    }
}

extension Binary.Reader where Storage: ~Copyable & ~Escapable {

    public var readerIndex: Index<Storage> {
        _readerIndex
    }

    public var count: Index<Storage>.Count {
        _count
    }
}

extension Binary.Reader where Storage: ~Copyable & ~Escapable {

    @inlinable
    @_lifetime(copy storage)
    public init(
        storage: consuming Storage,
        readerIndex: Index<Storage>
    ) throws(Binary.Reader<Storage>.Error) {
        let byteCount = storage.span.count
        let count = Index<Storage>.Count(Cardinal(UInt(byteCount)))

        guard readerIndex <= count else {
            throw .bounds(
                value: Int(bitPattern: readerIndex),
                lower: 0,
                upper: Int(bitPattern: count)
            )
        }

        self.storage = storage
        self._count = count
        self._readerIndex = readerIndex
    }
}

extension Binary.Reader where Storage: ~Copyable & ~Escapable {

    @inlinable
    @_lifetime(copy storage)
    public init(
        __unchecked: Void = (),
        storage: consuming Storage,
        readerIndex: Index<Storage>? = nil
    ) {
        let byteCount = storage.span.count
        let count = Index<Storage>.Count(Cardinal(UInt(byteCount)))
        let readerIndex = readerIndex ?? .zero
        precondition(readerIndex <= count)
        self.storage = storage
        self._count = count
        self._readerIndex = readerIndex
    }
}

extension Binary.Reader where Storage: ~Copyable & ~Escapable {

    @inlinable
    public var remainingCount: Index<Storage>.Count {

        let reader = Int(bitPattern: _readerIndex)
        let count = Int(bitPattern: _count)
        return Index<Storage>.Count(Cardinal(UInt(count - reader)))
    }

    @inlinable
    public var hasRemaining: Bool {
        _readerIndex < _count
    }

    @inlinable
    public var isAtEnd: Bool {
        _readerIndex >= _count
    }
}

extension Binary.Reader where Storage: ~Copyable & ~Escapable {

    @inlinable
    public mutating func moveReaderIndex(
        by offset: Index<Storage>.Offset
    ) throws(Binary.Reader<Storage>.Error) {
        let currentReader = Int(bitPattern: _readerIndex)
        let count = Int(bitPattern: _count)
        let offsetValue = Int(bitPattern: offset)

        let (newIndex, overflow) = currentReader.addingReportingOverflow(offsetValue)

        guard !overflow else {
            throw .overflow
        }

        guard newIndex >= 0 else {
            throw .bounds(
                value: newIndex,
                lower: 0,
                upper: count
            )
        }

        guard newIndex <= count else {
            throw .bounds(
                value: newIndex,
                lower: 0,
                upper: count
            )
        }

        _readerIndex = Index<Storage>(Ordinal(UInt(newIndex)))
    }

    @inlinable
    public mutating func moveReaderIndex(
        __unchecked: Void = (),
        by offset: Index<Storage>.Offset
    ) {
        let currentReader = Int(bitPattern: _readerIndex)
        let count = Int(bitPattern: _count)
        let offsetValue = Int(bitPattern: offset)

        let newIndex = currentReader &+ offsetValue
        precondition(newIndex >= 0 && newIndex <= count)
        _readerIndex = Index<Storage>(Ordinal(UInt(newIndex)))
    }
}

extension Binary.Reader where Storage: ~Copyable & ~Escapable {

    @inlinable
    public mutating func setReaderIndex(
        to position: Index<Storage>
    ) throws(Binary.Reader<Storage>.Error) {
        let count = Int(bitPattern: _count)
        let positionValue = Int(bitPattern: position)

        guard positionValue <= count else {
            throw .bounds(
                value: positionValue,
                lower: 0,
                upper: count
            )
        }

        _readerIndex = position
    }

    @inlinable
    public mutating func setReaderIndex(
        __unchecked: Void = (),
        to position: Index<Storage>
    ) {
        let count = Int(bitPattern: _count)
        let positionValue = Int(bitPattern: position)
        precondition(positionValue <= count)
        _readerIndex = position
    }
}

extension Binary.Reader where Storage: ~Copyable & ~Escapable {

    @inlinable
    public mutating func reset() {
        _readerIndex = .zero
    }
}

extension Binary.Reader where Storage: ~Copyable & ~Escapable {

    @inlinable
    public var remainingBytes: Swift.Span<Byte> {
        @_lifetime(borrow self)
        borrowing get {
            let readerIdx = Int(bitPattern: _readerIndex)
            let storageCount = Int(bitPattern: _count)
            return storage.span.extracting(readerIdx..<storageCount)
        }
    }

    @inlinable
    public func withRemainingBytes<R, E: Swift.Error>(
        _ body: (UnsafeRawBufferPointer) throws(E) -> R
    ) throws(E) -> R {
        let span = remainingBytes
        return try span.withUnsafeBytes {
            (rawBuffer: UnsafeRawBufferPointer) throws(E) -> R in
            try unsafe body(rawBuffer)
        }
    }
}
