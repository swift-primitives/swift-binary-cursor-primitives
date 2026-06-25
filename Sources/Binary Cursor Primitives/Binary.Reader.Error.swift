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

extension Binary.Reader where Storage: ~Copyable & ~Escapable {
    /// A structured fault from reader index navigation.
    ///
    /// Uses typed throws (`throws(Binary.Reader<Storage>.Error)`). A reader
    /// tracks a single read position, so only the faults it can produce are
    /// modeled: reader-index bounds and reader-index arithmetic overflow.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The reader index fell outside its valid range `lower...upper`.
        case bounds(value: Int, lower: Int, upper: Int)

        /// Reader-index arithmetic overflowed.
        case overflow
    }
}

// MARK: - CustomStringConvertible

extension Binary.Reader.Error: CustomStringConvertible where Storage: ~Copyable & ~Escapable {
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
