import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;

extension CharPointer on ffi.Pointer<ffi.Char> {
  String? toDartString() =>
      this == ffi.nullptr ? null : cast<ffi.Utf8>().toDartString();
}

extension CharString on String {
  ffi.Pointer<ffi.Char> toCString({
    ffi.Allocator allocator = ffi.malloc,
  }) {
    return toNativeUtf8(allocator: allocator).cast();
  }
}

extension OrThrowIfNull<T> on T? {
  T orThrowIfNull(Object e) {
    if (this == null) throw e;
    return this!;
  }
}
