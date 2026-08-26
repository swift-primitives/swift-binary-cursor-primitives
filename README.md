# Binary Cursor

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Position-tracked readers over borrowed byte storage — a `Binary.Cursor` with separate reader and writer indices and a read-only `Binary.Reader`, both `~Copyable & ~Escapable` views with `Index<Storage>`-typed positions.

---

## Quick Start

A `Binary.Reader` tracks a single read position over borrowed byte storage. Because it is `~Copyable & ~Escapable`, it cannot be copied and cannot outlive the storage it reads — the borrow is enforced by the compiler.

```swift
import Binary_Cursor

// Borrowed byte storage. The array must outlive any reader or cursor over it.
let frame: [Byte] = [0xDE, 0xAD, 0xBE, 0xEF, 0x01, 0x02]

var reader = Binary.Reader(storage: frame.span)

try reader.moveReaderIndex(by: 4)        // consume the 4-byte header
print(reader.remainingCount == 2)        // true
print(reader.hasRemaining)               // true

// Borrow the unconsumed tail as a raw buffer, valid only inside the closure.
unsafe reader.withRemainingBytes { payload in
    let first = unsafe payload[0]
    print(first)                         // 1
}
```

A `Binary.Cursor` adds a second index. It tracks a reader and a writer position over the same storage and enforces the invariant `0 <= readerIndex <= writerIndex <= count` at every mutation — moves and absolute sets that would break it throw a typed `Binary.Cursor.Error` instead of corrupting state.

```swift
import Binary_Cursor

let buffer: [Byte] = [1, 2, 3, 4, 5]

var cursor = try Binary.Cursor(
    storage: buffer.span,
    readerIndex: 1,
    writerIndex: 4
)

print(cursor.readableCount == 3)   // bytes between reader and writer
print(cursor.writableCount == 1)   // spare capacity after the writer
print(cursor.isReadable)           // true

// The readable window is storage[readerIndex..<writerIndex].
let window = cursor.readableBytes  // Swift.Span<Byte>, lifetime-bound to `cursor`
print(window.count)                // 3
```

Positions are typed: `Index<Storage>` for an absolute position, `Index<Storage>.Offset` for a signed displacement, and `Index<Storage>.Count` for a byte count. The storage type itself is the phantom tag, so an index taken from one buffer cannot be applied to another. Each mutating call also has an `__unchecked:` variant that skips validation for paths where the invariants are already guaranteed.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-molecules/swift-binary-cursor.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Binary Cursor", package: "swift-binary-cursor"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Architecture

Two library products over generic byte storage — any `Span.Protocol` conformer whose `Element` is `Byte`; the canonical conformer is a borrowed `Swift.Span<Byte>`.

| Product | Target | Purpose |
|---------|--------|---------|
| `Binary Cursor` | `Sources/Binary Cursor/` | The `Binary.Cursor` dual reader/writer view and the read-only `Binary.Reader`, with their typed `Binary.Cursor.Error` and `Binary.Reader.Error` navigation faults. |
| `Binary Cursor Test Support` | `Tests/Support/` | Re-exports the main target for test consumers. |

Foundation-free.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
