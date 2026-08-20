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

// Binary.Reader.swift
// Read-only position-tracked view over byte storage using Index<Storage> pattern.

public import Byte_Primitives
public import Index_Primitives
public import Span_Protocol_Primitives

extension Binary {
    /// A read-only position-tracked view over contiguous byte storage.
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
    /// var reader1 = Binary.Reader(storage: buffer1)
    /// var reader2 = Binary.Reader(storage: buffer2)
    ///
    /// // reader1.readerIndex == reader2.readerIndex
    /// // ^ Compile error if buffer1 and buffer2 are different types
    /// ```
    ///
    /// ## Invariants
    ///
    /// `0 <= readerIndex <= count`
    ///
    /// ## Lifetime
    ///
    /// `~Copyable & ~Escapable`. `Storage` is a `Span.\`Protocol\`` conformer
    /// whose suppression of `Escapable` is restated here, so the canonical
    /// conformer — a borrowed `Swift.Span<Byte>` — qualifies. The reader stores
    /// that borrow by value and cannot outlive the storage it reads
    /// (compiler-enforced via `@_lifetime(copy storage)` on the initializers).
    public struct Reader<Storage: Span.`Protocol` & ~Copyable & ~Escapable>: ~Copyable, ~Escapable
    where Storage.Element == Byte {
        /// The underlying storage.
        public let storage: Storage

        /// The storage count (validated once at construction).
        @usableFromInline
        internal let _count: Index<Storage>.Count

        /// The current read position.
        @usableFromInline
        internal var _readerIndex: Index<Storage>

        /// Creates a reader over the given storage with index at zero.
        ///
        /// The reader binds its lifetime to `storage`'s own lifetime scope
        /// (e.g., a `Swift.Span<Byte>`'s borrow lifetime propagates through
        /// this initializer).
        ///
        /// - Parameter storage: The underlying storage.
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

// MARK: - Indices

extension Binary.Reader where Storage: ~Copyable & ~Escapable {
    /// The current read position.
    public var readerIndex: Index<Storage> {
        _readerIndex
    }

    /// The storage count.
    public var count: Index<Storage>.Count {
        _count
    }
}

// MARK: - Validated Initializer

extension Binary.Reader where Storage: ~Copyable & ~Escapable {
    /// Creates a reader over the given storage with validated index.
    ///
    /// - Parameters:
    ///   - storage: The underlying storage.
    ///   - readerIndex: The initial reader position.
    /// - Throws: `Binary.Reader.Error` if index violates invariants.
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

// MARK: - Unchecked Initializer

extension Binary.Reader where Storage: ~Copyable & ~Escapable {
    /// Creates a reader without validation.
    ///
    /// Use this in performance-critical paths where invariants are
    /// guaranteed by construction or prior validation.
    ///
    /// - Parameters:
    ///   - __unchecked: Marker parameter (pass `()` or omit).
    ///   - storage: The underlying storage.
    ///   - readerIndex: The initial reader position.
    /// - Precondition: `0 <= readerIndex <= storage.span.count`
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

// MARK: - Computed Properties

extension Binary.Reader where Storage: ~Copyable & ~Escapable {
    /// Bytes remaining to read.
    @inlinable
    public var remainingCount: Index<Storage>.Count {
        // Safe: invariant guarantees count >= reader
        let reader = Int(bitPattern: _readerIndex)
        let count = Int(bitPattern: _count)
        return Index<Storage>.Count(Cardinal(UInt(count - reader)))
    }

    /// Whether there are bytes remaining to read.
    @inlinable
    public var hasRemaining: Bool {
        _readerIndex < _count
    }

    /// Whether the reader has consumed all bytes.
    @inlinable
    public var isAtEnd: Bool {
        _readerIndex >= _count
    }
}

// MARK: - Move Reader Index

extension Binary.Reader where Storage: ~Copyable & ~Escapable {
    /// Move reader index by offset.
    ///
    /// - Parameter offset: The displacement to apply.
    /// - Throws: `Binary.Reader.Error` if resulting index would be invalid.
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

    // swift-format-ignore: AlwaysUseLowerCamelCase
    /// Move reader index by offset (unchecked).
    ///
    /// - Parameters:
    ///   - __unchecked: Marker parameter (pass `()` or omit).
    ///   - offset: The displacement to apply.
    /// - Precondition: No overflow occurs.
    /// - Precondition: Result must satisfy `0 <= readerIndex <= count`.
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

// MARK: - Set Reader Index

extension Binary.Reader where Storage: ~Copyable & ~Escapable {
    /// Set reader index to position.
    ///
    /// - Parameter position: The new reader position.
    /// - Throws: `Binary.Reader.Error` if position is invalid.
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

    // swift-format-ignore: AlwaysUseLowerCamelCase
    /// Set reader index to position (unchecked).
    ///
    /// - Parameters:
    ///   - __unchecked: Marker parameter (pass `()` or omit).
    ///   - position: The new reader position.
    /// - Precondition: `0 <= position <= count`.
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

// MARK: - Reset

extension Binary.Reader where Storage: ~Copyable & ~Escapable {
    /// Reset reader index to zero.
    @inlinable
    public mutating func reset() {
        _readerIndex = .zero
    }
}

// MARK: - Region Access

extension Binary.Reader where Storage: ~Copyable & ~Escapable {
    /// Returns a span of the remaining bytes region.
    ///
    /// The remaining region is `storage[readerIndex..<count]`.
    /// The span is lifetime-bound to the reader.
    @inlinable
    public var remainingBytes: Swift.Span<Byte> {
        @_lifetime(borrow self)
        borrowing get {
            let readerIdx = Int(bitPattern: _readerIndex)
            let storageCount = Int(bitPattern: _count)
            return storage.span.extracting(readerIdx..<storageCount)
        }
    }

    /// Provides read-only access to the remaining bytes region via closure.
    ///
    /// The remaining region is `storage[readerIndex..<count]`.
    /// The buffer pointer is valid only within the closure scope.
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
