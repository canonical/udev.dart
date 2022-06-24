import 'dart:ffi' as ffi;

import 'package:meta/meta.dart';

import 'libudev.dart';

UdevFinalizer? _finalizer;

UdevFinalizer get finalizer => _finalizer ??= UdevFinalizer();

@visibleForTesting
void overrideFinalizerForTesting(UdevFinalizer? finalizer) =>
    _finalizer = finalizer;

final _objects = <Object, ffi.NativeFinalizer>{};
final _finalizers = {
  udev_t: ffi.NativeFinalizer(dylib.lookup('udev_unref')),
  udev_device_t: ffi.NativeFinalizer(dylib.lookup('udev_device_unref')),
  udev_enumerate_t: ffi.NativeFinalizer(dylib.lookup('udev_enumerate_unref')),
};

class UdevFinalizer {
  void attach<T extends ffi.NativeType>(
    ffi.Finalizable object,
    ffi.Pointer<T> ptr,
  ) {
    _objects[object] = _finalizers[T]!
      ..attach(object, ptr.cast(), detach: object);
  }

  void detach(ffi.Finalizable object) {
    _objects.remove(object)!.detach(object);
  }
}
