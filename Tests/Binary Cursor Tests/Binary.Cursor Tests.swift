import Binary_Cursor_Test_Support
import Byte
import Span_Protocol
import Testing

@Suite
struct `Binary.Cursor Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Binary.Cursor Tests`.Unit {

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
    func `init with custom indices preserves positions`() throws(Binary.Cursor<Swift.Span<Byte>>
        .Error)
    {
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

    @Test
    func `moveReaderIndex advances reader by offset`() throws(Binary.Cursor<Swift.Span<Byte>>.Error)
    {
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
    func `moveReaderIndex unchecked advances reader`() throws(Binary.Cursor<Swift.Span<Byte>>.Error)
    {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 5
        )

        cursor.moveReaderIndex(__unchecked: (), by: 2)
        let readerIndex = cursor.readerIndex
        #expect(readerIndex == 2)
    }

    @Test
    func `moveWriterIndex advances writer by offset`() throws(Binary.Cursor<Swift.Span<Byte>>.Error)
    {
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
    func `moveWriterIndex unchecked advances writer`() throws(Binary.Cursor<Swift.Span<Byte>>.Error)
    {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 2
        )

        cursor.moveWriterIndex(__unchecked: (), by: 2)
        let writerIndex = cursor.writerIndex
        #expect(writerIndex == 4)
    }

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
    func `setReaderIndex unchecked sets absolute position`() throws(Binary.Cursor<Swift.Span<Byte>>
        .Error)
    {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 5
        )

        cursor.setReaderIndex(__unchecked: (), to: 3)
        let readerIndex = cursor.readerIndex
        #expect(readerIndex == 3)
    }

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
    func `setWriterIndex unchecked sets absolute position`() throws(Binary.Cursor<Swift.Span<Byte>>
        .Error)
    {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 2
        )

        cursor.setWriterIndex(__unchecked: (), to: 4)
        let writerIndex = cursor.writerIndex
        #expect(writerIndex == 4)
    }

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

    @Test
    func `isReadable returns true when bytes available`() throws(Binary.Cursor<Swift.Span<Byte>>
        .Error)
    {
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
    func `isReadable returns false when no bytes available`() throws(Binary.Cursor<Swift.Span<Byte>>
        .Error)
    {
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
    func `isWritable returns true when space available`() throws(Binary.Cursor<Swift.Span<Byte>>
        .Error)
    {
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
    func `isWritable returns false when no space available`() throws(Binary.Cursor<Swift.Span<Byte>>
        .Error)
    {
        let bytes: [Byte] = [1, 2, 3]
        let cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 0,
            writerIndex: 3
        )

        let isWritable = cursor.isWritable
        #expect(isWritable == false)
    }

    @Test
    func `withReadableBytes provides correct slice`() throws(Binary.Cursor<Swift.Span<Byte>>.Error)
    {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        let cursor = try Binary.Cursor(
            storage: bytes.span,
            readerIndex: 1,
            writerIndex: 4
        )

        unsafe cursor.withReadableBytes { ptr in

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

extension `Binary.Cursor Tests`.`Edge Case` {

    @Test
    func `init throws when reader exceeds writer`() {
        let bytes: [Byte] = [1, 2, 3]

        do throws(Binary.Cursor<Swift.Span<Byte>>.Error) {
            _ = try Binary.Cursor(
                storage: bytes.span,
                readerIndex: 2,
                writerIndex: 1
            )
            Issue.record("expected Binary.Cursor.Error.invariant")
        } catch {

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

        }
    }

    @Test
    func `moveReaderIndex throws when exceeding writer`() throws(Binary.Cursor<Swift.Span<Byte>>
        .Error)
    {
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

        }
    }

    @Test
    func `moveWriterIndex throws when exceeding storage count`() throws(Binary.Cursor<
        Swift.Span<Byte>
    >.Error) {
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

        }
    }

    @Test
    func `withReadableBytes propagates typed error`() throws(Binary.Cursor<Swift.Span<Byte>>.Error)
    {
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

        }
    }
}
