import 'dart:ffi' as ffi;

import 'package:test/test.dart';
import 'package:udev/src/extensions.dart';

TypeMatcher<ffi.Pointer<T>> isPointer<T extends ffi.NativeType>([
  int? address,
]) {
  final matcher = isA<ffi.Pointer<T>>();
  return address == null
      ? matcher
      : matcher.having((p) => p.address, 'address', address);
}

TypeMatcher<ffi.Pointer<ffi.Char>> isCString(dynamic matcher) {
  return isPointer<ffi.Char>()
      .having((p) => p.toDartString(), 'toDartString', matcher);
}
