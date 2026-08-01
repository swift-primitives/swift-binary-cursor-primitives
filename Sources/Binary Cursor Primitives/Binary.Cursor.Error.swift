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

// Binary.Cursor.Error.swift
// Domain-specific error for Binary.Cursor index navigation.
//
// Hoisted to module scope (non-generic over Storage) rather than nested in
// Binary.Cursor<Storage>: the cases never use Storage, so a nested form is
// an accidentally-generic `@error` SIL result that can trip
// FunctionSignatureOpts under -O -enable-default-cmo (swiftlang/swift#89617).
// `Binary.Cursor<Storage>.Error` still resolves via the `public typealias
// Error` kept on `Binary.Cursor` — behaviour-preserving.

/// A structured fault from cursor index navigation.
///
/// Uses typed throws (`throws(Binary.Cursor<Storage>.Error)`) to provide
/// compile-time exhaustiveness checking. Only the faults a cursor can
/// actually produce are modeled: the `readerIndex <= writerIndex` ordering
/// invariant, index bounds, and index-arithmetic overflow.
public enum __BinaryCursorError: Swift.Error, Sendable, Equatable {
    /// The `readerIndex <= writerIndex` ordering invariant was violated.
    case invariant(reader: Int, writer: Int)

    /// An index fell outside its valid range `lower...upper`.
    case bounds(Field, value: Int, lower: Int, upper: Int)

    /// Index arithmetic overflowed.
    case overflow(Field)
}

extension Binary.Cursor where Storage: ~Copyable & ~Escapable {
    /// A structured fault from cursor index navigation.
    public typealias Error = __BinaryCursorError
}

// MARK: - CustomStringConvertible

extension __BinaryCursorError: CustomStringConvertible {
    /// A human-readable description of the navigation fault.
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
