// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// Binary.Cursor.swift
// Position-tracked view over byte storage using Index<Storage> pattern.

public import Byte_Primitives
public import Index_Primitives
public import Span_Protocol_Primitives

extension Binary {
    /// A position-tracked view over borrowed contiguous byte storage.
    ///
    /// Uses the `Index<Storage>` pattern from index-primitives:
    /// - `Index<Storage>` for byte positions (phantom-typed via Storage)
    /// - `Index<Storage>.Offset` for signed displacements
    /// - `Index<Storage>.Count` for byte counts
    ///
    /// This aligns with storage-primitives' pattern where the storage type
    /// itself serves as the phantom tag for type safety.
    ///
    /// ## Type Safety
    ///
    /// ```swift
    /// var cursor1 = try Binary.Cursor(storage: buffer1)
    /// var cursor2 = try Binary.Cursor(storage: buffer2)
    ///
    /// // cursor1.readerIndex == cursor2.readerIndex
    /// // ^ Compile error if buffer1 and buffer2 are different types
    /// ```
    ///
    /// ## Invariants
    ///
    /// `0 <= readerIndex <= writerIndex <= count`
    ///
    /// ## Lifetime
    ///
    /// `~Copyable & ~Escapable`. `Storage` is a `Span.\`Protocol\`` conformer
    /// whose suppression of `Escapable` is restated here, so the canonical
    /// conformer — a borrowed `Swift.Span<Byte>` — qualifies. The cursor stores
    /// that borrow by value and cannot outlive the storage it reads
    /// (compiler-enforced via `@_lifetime(copy storage)` on the initializers).
    public struct Cursor<Storage: Span.`Protocol` & ~Copyable & ~Escapable>: ~Copyable, ~Escapable
    where Storage.Element == Byte {
        /// The borrowed storage.
        ///
        /// The reader spans `[readerIndex, writerIndex)` and the writer index
        /// marks the valid-data extent. Set once at construction; the borrow is
        /// read-only.
        public let storage: Storage

        /// The storage count (validated once at construction).
        @usableFromInline
        internal let _count: Index<Storage>.Count

        /// The current read position.
        @usableFromInline
        internal var _readerIndex: Index<Storage>

        /// The current write position.
        @usableFromInline
        internal var _writerIndex: Index<Storage>

        /// Creates a cursor over the given storage with indices at zero.
        ///
        /// Both reader and writer start at position zero. The cursor binds its
        /// lifetime to `storage`'s own lifetime scope (e.g., a
        /// `Swift.Span<Byte>`'s borrow lifetime propagates through this
        /// initializer).
        ///
        /// - Parameter storage: The underlying storage.
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

// MARK: - Indices

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// The current read position.
    public var readerIndex: Index<Storage> {
        _readerIndex
    }

    /// The current write position.
    public var writerIndex: Index<Storage> {
        _writerIndex
    }

    /// The storage count.
    public var count: Index<Storage>.Count {
        _count
    }
}

// MARK: - Validated Initializer

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// Creates a cursor over the given storage with validated indices.
    ///
    /// - Parameters:
    ///   - storage: The underlying storage.
    ///   - readerIndex: The initial reader position.
    ///   - writerIndex: The initial writer position.
    /// - Throws: `Binary.Cursor.Error` if indices violate invariants.
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

// MARK: - Unchecked Initializer

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// Creates a cursor without validation.
    ///
    /// Use this in performance-critical paths where invariants are
    /// guaranteed by construction or prior validation.
    ///
    /// - Parameters:
    ///   - __unchecked: Marker parameter (pass `()` or omit).
    ///   - storage: The underlying storage.
    ///   - readerIndex: The initial reader position.
    ///   - writerIndex: The initial writer position.
    /// - Precondition: `0 <= readerIndex <= writerIndex <= storage.span.count`
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

// MARK: - Computed Properties

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// Bytes available for reading.
    @inlinable
    public var readableCount: Index<Storage>.Count {
        // Safe: invariant guarantees writer >= reader
        let reader = Int(bitPattern: _readerIndex)
        let writer = Int(bitPattern: _writerIndex)
        return Index<Storage>.Count(Cardinal(UInt(writer - reader)))
    }

    /// Bytes available for writing.
    @inlinable
    public var writableCount: Index<Storage>.Count {
        // Safe: invariant guarantees count >= writer
        let writer = Int(bitPattern: _writerIndex)
        let count = Int(bitPattern: _count)
        return Index<Storage>.Count(Cardinal(UInt(count - writer)))
    }

    /// Whether there are bytes available to read.
    @inlinable
    public var isReadable: Bool {
        _writerIndex > _readerIndex
    }

    /// Whether there is space available to write.
    @inlinable
    public var isWritable: Bool {
        _writerIndex < _count
    }
}

// MARK: - Move Reader Index

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// Move reader index by offset.
    ///
    /// - Parameter offset: The displacement to apply.
    /// - Throws: `Binary.Cursor.Error` if resulting index would be invalid.
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

    // swift-format-ignore: AlwaysUseLowerCamelCase
    /// Move reader index by offset (unchecked).
    ///
    /// - Parameters:
    ///   - __unchecked: Marker parameter (pass `()` or omit).
    ///   - offset: The displacement to apply.
    /// - Precondition: No overflow occurs.
    /// - Precondition: Result must satisfy `0 <= readerIndex <= writerIndex`.
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

// MARK: - Move Writer Index

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// Move writer index by offset.
    ///
    /// - Parameter offset: The displacement to apply.
    /// - Throws: `Binary.Cursor.Error` if resulting index would be invalid.
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

    // swift-format-ignore: AlwaysUseLowerCamelCase
    /// Move writer index by offset (unchecked).
    ///
    /// - Parameters:
    ///   - __unchecked: Marker parameter (pass `()` or omit).
    ///   - offset: The displacement to apply.
    /// - Precondition: No overflow occurs.
    /// - Precondition: Result must satisfy `readerIndex <= writerIndex <= count`.
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

// MARK: - Set Reader Index

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// Set reader index to position.
    ///
    /// - Parameter position: The new reader position.
    /// - Throws: `Binary.Cursor.Error` if position is invalid.
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

    // swift-format-ignore: AlwaysUseLowerCamelCase
    /// Set reader index to position (unchecked).
    ///
    /// - Parameters:
    ///   - __unchecked: Marker parameter (pass `()` or omit).
    ///   - position: The new reader position.
    /// - Precondition: `0 <= position <= writerIndex`.
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

// MARK: - Set Writer Index

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// Set writer index to position.
    ///
    /// - Parameter position: The new writer position.
    /// - Throws: `Binary.Cursor.Error` if position is invalid.
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

    // swift-format-ignore: AlwaysUseLowerCamelCase
    /// Set writer index to position (unchecked).
    ///
    /// - Parameters:
    ///   - __unchecked: Marker parameter (pass `()` or omit).
    ///   - position: The new writer position.
    /// - Precondition: `readerIndex <= position <= count`.
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

// MARK: - Reset

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// Reset both indices to zero.
    @inlinable
    public mutating func reset() {
        _readerIndex = .zero
        _writerIndex = .zero
    }
}

// MARK: - Region Access

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// Returns a span of the readable bytes region.
    ///
    /// The readable region is `storage[readerIndex..<writerIndex]`.
    /// The span is lifetime-bound to the cursor.
    @inlinable
    public var readableBytes: Swift.Span<Byte> {
        @_lifetime(borrow self)
        borrowing get {
            let readerIdx = Int(bitPattern: _readerIndex)
            let writerIdx = Int(bitPattern: _writerIndex)
            return storage.span.extracting(readerIdx..<writerIdx)
        }
    }

    /// Provides read-only access to the readable bytes region via closure.
    ///
    /// The readable region is `storage[readerIndex..<writerIndex]`.
    /// The buffer pointer is valid only within the closure scope.
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
