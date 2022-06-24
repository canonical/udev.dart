import 'dart:ffi' as ffi;

import 'libudev.dart';

final _finalizers = <Object, ffi.NativeFinalizer>{};
final _contextFinalizer = ffi.NativeFinalizer(dylib.lookup('udev_unref'));
final _deviceFinalizer = ffi.NativeFinalizer(dylib.lookup('udev_device_unref'));

class UdevFinalizer {
  static void attach(ffi.Finalizable object, ffi.Pointer ptr) {
    if (ptr is ffi.Pointer<udev_t>) {
      _finalizers[object] = _contextFinalizer
        ..attach(object, ptr.cast(), detach: object);
    } else if (ptr is ffi.Pointer<udev_device_t>) {
      _finalizers[object] = _deviceFinalizer
        ..attach(object, ptr.cast(), detach: object);
    } else {
      throw UnsupportedError('${ptr.runtimeType}');
    }
  }

  static void detach(ffi.Finalizable object) {
    final finalizer = _finalizers.remove(object);
    finalizer!.detach(object);
  }
}
