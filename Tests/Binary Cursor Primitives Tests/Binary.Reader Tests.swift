// Binary.Reader Tests.swift

import Binary_Cursor_Primitives_Test_Support
import Byte_Primitives
import Span_Protocol_Primitives
import Testing

// MARK: - Test Suites

/// Tests for Binary.Reader - uses parallel namespace pattern per [TEST-004]
/// since Binary.Reader is a generic type.
///
/// `Binary.Reader` is a `~Copyable & ~Escapable` borrowed view over a
/// `Swift.Span<Byte>`. Fixtures are `[Byte]` arrays whose `.span` (a
/// `Swift.Span<Byte>: Span.\`Protocol\``) is the storage; the array must outlive
/// the reader, so it is bound to a named `let bytes` in each test. Per
/// [SWIFT-TEST-014], observable properties are projected to Copyable locals
/// before `#expect` (the macro copies its operands); throwing paths use
/// `do`/`catch` in linear scope because a lifetime-dependent reader cannot
/// escape an `#expect(throws:)` autoclosure.
@Suite
struct `Binary.Reader Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit Tests

extension `Binary.Reader Tests`.Unit {

    // MARK: - Initialization

    @Test
    func `init with default index sets reader to zero`() {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        let reader = Binary.Reader(storage: bytes.span)

        let readerIndex = reader.readerIndex
        let remaining = reader.remainingCount
        #expect(readerIndex == 0)
        #expect(remaining == 5)
    }

    @Test
    func `init with custom index preserves position`() throws(Binary.Reader<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        let reader = try Binary.Reader(storage: bytes.span, readerIndex: 2)

        let readerIndex = reader.readerIndex
        let remaining = reader.remainingCount
        #expect(readerIndex == 2)
        #expect(remaining == 3)
    }

    @Test
    func `init unchecked bypasses validation`() {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked init bypass surface per [CONV-001] same-package use.
        let reader = Binary.Reader(__unchecked: (), storage: bytes.span, readerIndex: 2)

        let readerIndex = reader.readerIndex
        let remaining = reader.remainingCount
        #expect(readerIndex == 2)
        #expect(remaining == 3)
    }

    // MARK: - Move Reader Index

    @Test
    func `moveReaderIndex advances reader by offset`() throws(Binary.Reader<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var reader = Binary.Reader(storage: bytes.span)

        try reader.moveReaderIndex(by: 3)
        let readerIndex = reader.readerIndex
        let remaining = reader.remainingCount
        #expect(readerIndex == 3)
        #expect(remaining == 2)
    }

    @Test
    func `moveReaderIndex allows negative offset for rewind`() throws(Binary.Reader<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var reader = try Binary.Reader(storage: bytes.span, readerIndex: 3)

        try reader.moveReaderIndex(by: -2)
        let readerIndex = reader.readerIndex
        let remaining = reader.remainingCount
        #expect(readerIndex == 1)
        #expect(remaining == 4)
    }

    @Test
    func `moveReaderIndex unchecked advances reader`() {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var reader = Binary.Reader(storage: bytes.span)

        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked move bypass surface per [CONV-001] same-package use.
        reader.moveReaderIndex(__unchecked: (), by: 3)
        let readerIndex = reader.readerIndex
        #expect(readerIndex == 3)
    }

    // MARK: - Set Reader Index

    @Test
    func `setReaderIndex sets absolute position`() throws(Binary.Reader<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var reader = Binary.Reader(storage: bytes.span)

        try reader.setReaderIndex(to: 4)
        let readerIndex = reader.readerIndex
        let remaining = reader.remainingCount
        #expect(readerIndex == 4)
        #expect(remaining == 1)
    }

    @Test
    func `setReaderIndex unchecked sets position`() {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var reader = Binary.Reader(storage: bytes.span)

        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked set bypass surface per [CONV-001] same-package use.
        reader.setReaderIndex(__unchecked: (), to: 4)
        let readerIndex = reader.readerIndex
        #expect(readerIndex == 4)
    }

    // MARK: - Reset

    @Test
    func `reset clears reader index to zero`() throws(Binary.Reader<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var reader = try Binary.Reader(storage: bytes.span, readerIndex: 3)

        reader.reset()
        let readerIndex = reader.readerIndex
        let remaining = reader.remainingCount
        #expect(readerIndex == 0)
        #expect(remaining == 5)
    }

    // MARK: - Convenience Properties

    @Test
    func `hasRemaining returns true when bytes available`() {
        let bytes: [Byte] = [1, 2, 3]
        let reader = Binary.Reader(storage: bytes.span)

        let hasRemaining = reader.hasRemaining
        #expect(hasRemaining == true)
    }

    @Test
    func `hasRemaining returns false at end`() throws(Binary.Reader<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3]
        let reader = try Binary.Reader(storage: bytes.span, readerIndex: 3)

        let hasRemaining = reader.hasRemaining
        #expect(hasRemaining == false)
    }

    @Test
    func `isAtEnd returns true at end`() throws(Binary.Reader<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3]
        let reader = try Binary.Reader(storage: bytes.span, readerIndex: 3)

        let isAtEnd = reader.isAtEnd
        #expect(isAtEnd == true)
    }

    @Test
    func `isAtEnd returns false when bytes remain`() {
        let bytes: [Byte] = [1, 2, 3]
        let reader = Binary.Reader(storage: bytes.span)

        let isAtEnd = reader.isAtEnd
        #expect(isAtEnd == false)
    }

    // MARK: - Closure-Based Access

    @Test
    func `withRemainingBytes provides correct slice`() throws(Binary.Reader<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        let reader = try Binary.Reader(storage: bytes.span, readerIndex: 2)

        unsafe reader.withRemainingBytes { ptr in
            // `unsafe` does not propagate into the closure ([MEM-UNSAFE-004]);
            // each raw-buffer load is marked and projected to a Copyable local.
            let count = ptr.count
            let byte0 = unsafe ptr[0]
            let byte1 = unsafe ptr[1]
            let byte2 = unsafe ptr[2]
            #expect(count == 3)
            #expect(byte0 == 3)
            #expect(byte1 == 4)
            #expect(byte2 == 5)
        }
    }

    @Test
    func `withRemainingBytes returns empty for exhausted reader`() throws(Binary.Reader<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3]
        let reader = try Binary.Reader(storage: bytes.span, readerIndex: 3)

        unsafe reader.withRemainingBytes { ptr in
            // `count` is the safe stored property of `UnsafeRawBufferPointer`;
            // project it off before `#expect` (the macro would otherwise
            // reference the unsafe-typed `ptr` in its instrumented operand).
            let count = ptr.count
            #expect(count == 0)
        }
    }

    // MARK: - Storage Access

    @Test
    func `storage property provides access to underlying data`() {
        let bytes: [Byte] = [10, 20, 30]
        let reader = Binary.Reader(storage: bytes.span)

        let storageCount = reader.storage.count
        let firstByte = reader.storage[0]
        #expect(storageCount == 3)
        #expect(firstByte == 10)
    }
}

// MARK: - Edge Case Tests

extension `Binary.Reader Tests`.`Edge Case` {

    @Test
    func `moveReaderIndex throws on out of bounds`() {
        let bytes: [Byte] = [1, 2, 3]
        var reader = Binary.Reader(storage: bytes.span)

        // A lifetime-dependent reader cannot escape an #expect(throws:)
        // autoclosure; assert the fault via do/catch in linear scope instead.
        do throws(Binary.Reader<Swift.Span<Byte>>.Error) {
            try reader.moveReaderIndex(by: 10)
            Issue.record("expected Binary.Reader.Error.bounds")
        } catch {
            // expected: offset 10 exceeds count 3
        }
    }

    @Test
    func `setReaderIndex throws on out of bounds`() {
        let bytes: [Byte] = [1, 2, 3]
        var reader = Binary.Reader(storage: bytes.span)

        do throws(Binary.Reader<Swift.Span<Byte>>.Error) {
            try reader.setReaderIndex(to: 10)
            Issue.record("expected Binary.Reader.Error.bounds")
        } catch {
            // expected: position 10 exceeds count 3
        }
    }

    @Test
    func `withRemainingBytes propagates typed error`() {
        enum Fault: Swift.Error { case expected }

        let bytes: [Byte] = [1, 2, 3]
        let reader = Binary.Reader(storage: bytes.span)

        do throws(Fault) {
            try unsafe reader.withRemainingBytes { (_: UnsafeRawBufferPointer) throws(Fault) in
                throw Fault.expected
            }
            Issue.record("expected Fault.expected")
        } catch {
            // expected: `withRemainingBytes` is `throws(E)`, so the closure's
            // typed `TestError` propagates unchanged.
        }
    }
}
