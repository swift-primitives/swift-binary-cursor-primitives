# Binary Cursor Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

`Binary.Cursor` and `Binary.Reader` — position-tracked readers over `Memory.Contiguous<Byte>` storage using the `Index<Storage>` typed-position pattern from swift-index-primitives.

Sibling extraction of swift-binary-primitives. The bare `Binary` owned-storage type lives in `Binary_Primitive`; this package adds the dual-index reader-writer (`Binary.Cursor`) and read-only reader (`Binary.Reader`) over generic `Memory.Contiguous.Protocol & ~Copyable` storage with `Element == UInt8`. Subject-first naming per `[API-NAME-001b]` — Binary is the subject (data domain), Cursor is the role.

---
