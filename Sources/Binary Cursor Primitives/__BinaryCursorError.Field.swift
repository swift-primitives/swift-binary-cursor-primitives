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

// MARK: - Field

extension __BinaryCursorError {
    /// Which index a fault concerns.
    public enum Field: Sendable, Equatable {
        /// The reader index.
        case reader

        /// The writer index.
        case writer
    }
}

extension __BinaryCursorError.Field: CustomStringConvertible {
    /// A human-readable name for the index a fault concerns.
    public var description: String {
        switch self {
        case .reader: return "readerIndex"
        case .writer: return "writerIndex"
        }
    }
}
