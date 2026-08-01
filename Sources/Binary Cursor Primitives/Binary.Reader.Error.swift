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

// Binary.Reader.Error.swift
// Domain-specific error for Binary.Reader index navigation.
//
// Hoisted to module scope (non-generic over Storage) rather than nested in
// Binary.Reader<Storage>: the cases never use Storage, so a nested form is
// an accidentally-generic `@error` SIL result that can trip
// FunctionSignatureOpts under -O -enable-default-cmo (swiftlang/swift#89617).
// `Binary.Reader<Storage>.Error` still resolves via the `public typealias
// Error` kept on `Binary.Reader` — behaviour-preserving.

/// A structured fault from reader index navigation.
///
/// Uses typed throws (`throws(Binary.Reader<Storage>.Error)`). A reader
/// tracks a single read position, so only the faults it can produce are
/// modeled: reader-index bounds and reader-index arithmetic overflow.
public enum __BinaryReaderError: Swift.Error, Sendable, Equatable {
    /// The reader index fell outside its valid range `lower...upper`.
    case bounds(value: Int, lower: Int, upper: Int)

    /// Reader-index arithmetic overflowed.
    case overflow
}

extension Binary.Reader where Storage: ~Copyable & ~Escapable {
    /// A structured fault from reader index navigation.
    public typealias Error = __BinaryReaderError
}

// MARK: - CustomStringConvertible

extension __BinaryReaderError: CustomStringConvertible {
    /// A human-readable description of the navigation fault.
    public var description: String {
        switch self {
        case .bounds(let value, let lower, let upper):
            return "readerIndex out of bounds (was \(value), valid: \(lower)...\(upper))"

        case .overflow:
            return "readerIndex arithmetic overflow"
        }
    }
}
