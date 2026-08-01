// Binary.Cursor Tests.swift

import Binary_Cursor_Primitives_Test_Support
import Byte_Primitives
import Span_Protocol_Primitives
import Testing

// MARK: - Test Suites

/// Tests for Binary.Cursor - uses parallel namespace pattern per [TEST-004]
/// since Binary.Cursor is a generic type.
///
/// `Binary.Cursor` is a `~Copyable & ~Escapable` borrowed view over a
/// `Swift.Span<Byte>`. Fixtures are `[Byte]` arrays whose `.span` (a
/// `Swift.Span<Byte>: Span.\`Protocol\``) is the storage; the array must outlive
/// the cursor, so it is bound to a named `let bytes` in each test. Per
/// [SWIFT-TEST-014], observable properties are projected to Copyable locals
/// before `#expect` (the macro copies its operands); throwing paths use
/// `do`/`catch` in linear scope because a lifetime-dependent cursor cannot
/// escape an `#expect(throws:)` autoclosure.
@Suite
struct `Binary.Cursor Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit Tests

extension `Binary.Cursor Tests`.Unit {

    // MARK: - Initialization

    @Test
    func `init with default indices sets reader and writer to zero`() {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        let cursor = Binary.Cursor(storage: bytes.span)

        let readerIndex = cursor.readerIndex
        let writerIndex = cursor.writerIndex
        let readable = cursor.readableCount
        let writable = cursor.writableCount
        #expect(readerIndex == 0)
        #expect(writerIndex == 0)
        #expect(readable == 0)
        #expect(writable == 5)
    }

    @Test
    func `init with custom indices preserves positions`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        let cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 1,
            writerIndex: 4
        )

        let readerIndex = cursor.readerIndex
        let writerIndex = cursor.writerIndex
        let readable = cursor.readableCount
        let writable = cursor.writableCount
        #expect(readerIndex == 1)
        #expect(writerIndex == 4)
        #expect(readable == 3)
        #expect(writable == 1)
    }

    @Test
    func `init unchecked bypasses validation`() {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        let cursor = Binary.Cursor(
            // swift-linter:disable:next unchecked call site
            // REASON: Test deliberately exercises the unchecked init bypass surface per [CONV-001] same-package use.
            __unchecked: (),
            storage: bytes.span,
            readerIndex: 1,
            writerIndex: 4
        )

        let readerIndex = cursor.readerIndex
        let writerIndex = cursor.writerIndex
        #expect(readerIndex == 1)
        #expect(writerIndex == 4)
    }

    // MARK: - Move Reader Index

    @Test
    func `moveReaderIndex advances reader by offset`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 5
        )

        try cursor.moveReaderIndex(by: 2)
        let readerIndex = cursor.readerIndex
        let readable = cursor.readableCount
        #expect(readerIndex == 2)
        #expect(readable == 3)
    }

    @Test
    func `moveReaderIndex unchecked advances reader`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 5
        )

        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked move bypass surface per [CONV-001] same-package use.
        cursor.moveReaderIndex(__unchecked: (), by: 2)
        let readerIndex = cursor.readerIndex
        #expect(readerIndex == 2)
    }

    // MARK: - Move Writer Index

    @Test
    func `moveWriterIndex advances writer by offset`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 2
        )

        try cursor.moveWriterIndex(by: 2)
        let writerIndex = cursor.writerIndex
        let writable = cursor.writableCount
        #expect(writerIndex == 4)
        #expect(writable == 1)
    }

    @Test
    func `moveWriterIndex unchecked advances writer`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 2
        )

        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked move bypass surface per [CONV-001] same-package use.
        cursor.moveWriterIndex(__unchecked: (), by: 2)
        let writerIndex = cursor.writerIndex
        #expect(writerIndex == 4)
    }

    // MARK: - Set Reader Index

    @Test
    func `setReaderIndex sets absolute position`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 5
        )

        try cursor.setReaderIndex(to: 3)
        let readerIndex = cursor.readerIndex
        #expect(readerIndex == 3)
    }

    @Test
    func `setReaderIndex unchecked sets absolute position`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 5
        )

        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked set bypass surface per [CONV-001] same-package use.
        cursor.setReaderIndex(__unchecked: (), to: 3)
        let readerIndex = cursor.readerIndex
        #expect(readerIndex == 3)
    }

    // MARK: - Set Writer Index

    @Test
    func `setWriterIndex sets absolute position`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 2
        )

        try cursor.setWriterIndex(to: 4)
        let writerIndex = cursor.writerIndex
        #expect(writerIndex == 4)
    }

    @Test
    func `setWriterIndex unchecked sets absolute position`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 2
        )

        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked set bypass surface per [CONV-001] same-package use.
        cursor.setWriterIndex(__unchecked: (), to: 4)
        let writerIndex = cursor.writerIndex
        #expect(writerIndex == 4)
    }

    // MARK: - Reset

    @Test
    func `reset clears both indices to zero`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 2,
            writerIndex: 4
        )

        cursor.reset()
        let readerIndex = cursor.readerIndex
        let writerIndex = cursor.writerIndex
        #expect(readerIndex == 0)
        #expect(writerIndex == 0)
    }

    // MARK: - Readable/Writable Checks

    @Test
    func `isReadable returns true when bytes available`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 3
        )

        let isReadable = cursor.isReadable
        #expect(isReadable == true)
    }

    @Test
    func `isReadable returns false when no bytes available`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 3,
            writerIndex: 3
        )

        let isReadable = cursor.isReadable
        #expect(isReadable == false)
    }

    @Test
    func `isWritable returns true when space available`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 1
        )

        let isWritable = cursor.isWritable
        #expect(isWritable == true)
    }

    @Test
    func `isWritable returns false when no space available`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 3
        )

        let isWritable = cursor.isWritable
        #expect(isWritable == false)
    }

    // MARK: - Closure-Based Access

    @Test
    func `withReadableBytes provides correct slice`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        let cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 1,
            writerIndex: 4
        )

        unsafe cursor.withReadableBytes { ptr in
            // `unsafe` does not propagate into the closure ([MEM-UNSAFE-004]);
            // each raw-buffer load is marked and projected to a Copyable local.
            let count = ptr.count
            let byte0 = unsafe ptr[0]
            let byte1 = unsafe ptr[1]
            let byte2 = unsafe ptr[2]
            #expect(count == 3)
            #expect(byte0 == 2)
            #expect(byte1 == 3)
            #expect(byte2 == 4)
        }
    }
}

// MARK: - Edge Case Tests

extension `Binary.Cursor Tests`.`Edge Case` {

    @Test
    func `init throws when reader exceeds writer`() {
        let bytes: [Byte] = [1, 2, 3]

        // A lifetime-dependent cursor cannot escape an #expect(throws:)
        // autoclosure; assert the fault via do/catch in linear scope instead.
        do throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
            _ = try Binary.Cursor(
                storage: bytes.span,
                readerIndex: 2,
                writerIndex: 1
            )
            Issue.record("expected Binary.Cursor.Error.invariant")
        } catch {
            // expected: reader 2 > writer 1 violates the ordering invariant
        }
    }

    @Test
    func `init throws when writer exceeds storage count`() {
        let bytes: [Byte] = [1, 2, 3]

        do throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
            _ = try Binary.Cursor(
                storage: bytes.span,
                readerIndex: 0,
                writerIndex: 10
            )
            Issue.record("expected Binary.Cursor.Error.bounds")
        } catch {
            // expected: writer 10 exceeds count 3
        }
    }

    @Test
    func `moveReaderIndex throws when exceeding writer`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 3
        )

        do throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
            try cursor.moveReaderIndex(by: 5)
            Issue.record("expected Binary.Cursor.Error.invariant")
        } catch {
            // expected: reader would advance past writer 3
        }
    }

    @Test
    func `moveWriterIndex throws when exceeding storage count`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 3
        )

        do throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
            try cursor.moveWriterIndex(by: 10)
            Issue.record("expected Binary.Cursor.Error.bounds")
        } catch {
            // expected: writer would advance past count 5
        }
    }

    @Test
    func `withReadableBytes propagates typed error`() throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
        enum Fault: Swift.Error { case expected }

        let bytes: [Byte] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 3
        )

        do throws(Fault) {
            try unsafe cursor.withReadableBytes { (_: UnsafeRawBufferPointer) throws(Fault) in
                throw Fault.expected
            }
            Issue.record("expected Fault.expected")
        } catch {
            // expected: `withReadableBytes` is `throws(E)`, so the closure's
            // typed `TestError` propagates unchanged.
        }
    }
}
