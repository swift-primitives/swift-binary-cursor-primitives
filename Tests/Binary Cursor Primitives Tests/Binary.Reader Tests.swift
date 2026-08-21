import Binary_Cursor_Primitives_Test_Support
import Byte_Primitives
import Span_Protocol_Primitives
import Testing

@Suite
struct `Binary.Reader Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Binary.Reader Tests`.Unit {

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
    func `init with custom index preserves position`() throws(Binary.Reader<Swift.Span<Byte>>.Error)
    {
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

        let reader = Binary.Reader(__unchecked: (), storage: bytes.span, readerIndex: 2)

        let readerIndex = reader.readerIndex
        let remaining = reader.remainingCount
        #expect(readerIndex == 2)
        #expect(remaining == 3)
    }

    @Test
    func `moveReaderIndex advances reader by offset`() throws(Binary.Reader<Swift.Span<Byte>>.Error)
    {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        var reader = Binary.Reader(storage: bytes.span)

        try reader.moveReaderIndex(by: 3)
        let readerIndex = reader.readerIndex
        let remaining = reader.remainingCount
        #expect(readerIndex == 3)
        #expect(remaining == 2)
    }

    @Test
    func `moveReaderIndex allows negative offset for rewind`() throws(Binary.Reader<
        Swift.Span<Byte>
    >.Error) {
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

        reader.moveReaderIndex(__unchecked: (), by: 3)
        let readerIndex = reader.readerIndex
        #expect(readerIndex == 3)
    }

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

        reader.setReaderIndex(__unchecked: (), to: 4)
        let readerIndex = reader.readerIndex
        #expect(readerIndex == 4)
    }

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

    @Test
    func `withRemainingBytes provides correct slice`() throws(Binary.Reader<Swift.Span<Byte>>.Error)
    {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        let reader = try Binary.Reader(storage: bytes.span, readerIndex: 2)

        unsafe reader.withRemainingBytes { ptr in

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
    func `withRemainingBytes returns empty for exhausted reader`() throws(Binary.Reader<
        Swift.Span<Byte>
    >.Error) {
        let bytes: [Byte] = [1, 2, 3]
        let reader = try Binary.Reader(storage: bytes.span, readerIndex: 3)

        unsafe reader.withRemainingBytes { ptr in

            let count = ptr.count
            #expect(count == 0)
        }
    }

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

extension `Binary.Reader Tests`.`Edge Case` {

    @Test
    func `moveReaderIndex throws on out of bounds`() {
        let bytes: [Byte] = [1, 2, 3]
        var reader = Binary.Reader(storage: bytes.span)

        do throws(Binary.Reader<Swift.Span<Byte>>.Error) {
            try reader.moveReaderIndex(by: 10)
            Issue.record("expected Binary.Reader.Error.bounds")
        } catch {

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

        }
    }
}
