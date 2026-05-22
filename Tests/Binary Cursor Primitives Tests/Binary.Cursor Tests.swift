// Binary.Cursor Tests.swift

import Binary_Cursor_Primitives_Test_Support
import Testing

// MARK: - Test Suites

/// Tests for Binary.Cursor - uses parallel namespace pattern per [TEST-004]
/// since Binary.Cursor is a generic type.
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
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        let cursor = Binary.Cursor(storage: storage)

        #expect(cursor.readerIndex == 0)
        #expect(cursor.writerIndex == 0)
        #expect(cursor.readableCount == 0)
        #expect(cursor.writableCount == 5)
    }

    @Test
    func `init with custom indices preserves positions`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        let cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 1,
            writerIndex: 4
        )

        #expect(cursor.readerIndex == 1)
        #expect(cursor.writerIndex == 4)
        #expect(cursor.readableCount == 3)
        #expect(cursor.writableCount == 1)
    }

    @Test
    func `init unchecked bypasses validation`() {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        let cursor = Binary.Cursor(
            // swift-linter:disable:next unchecked call site
            // REASON: Test deliberately exercises the unchecked init bypass surface per [CONV-001] same-package use.
            __unchecked: (),
            storage: storage,
            readerIndex: 1,
            writerIndex: 4
        )

        #expect(cursor.readerIndex == 1)
        #expect(cursor.writerIndex == 4)
    }

    // MARK: - Move Reader Index

    @Test
    func `moveReaderIndex advances reader by offset`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 5
        )

        try cursor.moveReaderIndex(by: 2)
        #expect(cursor.readerIndex == 2)
        #expect(cursor.readableCount == 3)
    }

    @Test
    func `moveReaderIndex unchecked advances reader`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 5
        )

        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked move bypass surface per [CONV-001] same-package use.
        cursor.moveReaderIndex(__unchecked: (), by: 2)
        #expect(cursor.readerIndex == 2)
    }

    // MARK: - Move Writer Index

    @Test
    func `moveWriterIndex advances writer by offset`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 2
        )

        try cursor.moveWriterIndex(by: 2)
        #expect(cursor.writerIndex == 4)
        #expect(cursor.writableCount == 1)
    }

    @Test
    func `moveWriterIndex unchecked advances writer`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 2
        )

        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked move bypass surface per [CONV-001] same-package use.
        cursor.moveWriterIndex(__unchecked: (), by: 2)
        #expect(cursor.writerIndex == 4)
    }

    // MARK: - Set Reader Index

    @Test
    func `setReaderIndex sets absolute position`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 5
        )

        try cursor.setReaderIndex(to: 3)
        #expect(cursor.readerIndex == 3)
    }

    @Test
    func `setReaderIndex unchecked sets absolute position`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 5
        )

        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked set bypass surface per [CONV-001] same-package use.
        cursor.setReaderIndex(__unchecked: (), to: 3)
        #expect(cursor.readerIndex == 3)
    }

    // MARK: - Set Writer Index

    @Test
    func `setWriterIndex sets absolute position`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 2
        )

        try cursor.setWriterIndex(to: 4)
        #expect(cursor.writerIndex == 4)
    }

    @Test
    func `setWriterIndex unchecked sets absolute position`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 2
        )

        // swift-linter:disable:next unchecked call site
        // REASON: Test deliberately exercises the unchecked set bypass surface per [CONV-001] same-package use.
        cursor.setWriterIndex(__unchecked: (), to: 4)
        #expect(cursor.writerIndex == 4)
    }

    // MARK: - Reset

    @Test
    func `reset clears both indices to zero`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 2,
            writerIndex: 4
        )

        cursor.reset()
        #expect(cursor.readerIndex == 0)
        #expect(cursor.writerIndex == 0)
    }

    // MARK: - Readable/Writable Checks

    @Test
    func `isReadable returns true when bytes available`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 3
        )

        #expect(cursor.isReadable == true)
    }

    @Test
    func `isReadable returns false when no bytes available`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 3,
            writerIndex: 3
        )

        #expect(cursor.isReadable == false)
    }

    @Test
    func `isWritable returns true when space available`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 1
        )

        #expect(cursor.isWritable == true)
    }

    @Test
    func `isWritable returns false when no space available`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 3
        )

        #expect(cursor.isWritable == false)
    }

    // MARK: - Closure-Based Access

    @Test
    func `withReadableBytes provides correct slice`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        let cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 1,
            writerIndex: 4
        )

        unsafe cursor.withReadableBytes { ptr in
            #expect(ptr.count == 3)
            #expect(ptr[0] == 2)
            #expect(ptr[1] == 3)
            #expect(ptr[2] == 4)
        }
    }
}

// MARK: - Edge Case Tests

extension `Binary.Cursor Tests`.`Edge Case` {

    @Test
    func `init throws when reader exceeds writer`() {
        let storage: [UInt8] = [1, 2, 3]

        #expect(throws: Binary.Error.self) {
            _ = try Binary.Cursor(
                storage: storage,
                readerIndex: 2,
                writerIndex: 1
            )
        }
    }

    @Test
    func `init throws when writer exceeds storage count`() {
        let storage: [UInt8] = [1, 2, 3]

        #expect(throws: Binary.Error.self) {
            _ = try Binary.Cursor(
                storage: storage,
                readerIndex: 0,
                writerIndex: 10
            )
        }
    }

    @Test
    func `moveReaderIndex throws when exceeding writer`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 3
        )

        #expect(throws: Binary.Error.self) {
            try cursor.moveReaderIndex(by: 5)
        }
    }

    @Test
    func `moveWriterIndex throws when exceeding storage count`() throws(Binary.Error) {
        let storage: [UInt8] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 3
        )

        #expect(throws: Binary.Error.self) {
            try cursor.moveWriterIndex(by: 10)
        }
    }

    @Test
    func `withReadableBytes propagates typed error`() throws(Binary.Error) {
        enum TestError: Swift.Error { case expected }

        let storage: [UInt8] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: storage,
            readerIndex: 0,
            writerIndex: 3
        )

        #expect(throws: TestError.expected) {
            try unsafe cursor.withReadableBytes { (_: UnsafeRawBufferPointer) throws(TestError) in
                throw TestError.expected
            }
        }
    }
}
