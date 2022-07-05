import 'dart:ffi' as ffi;

import 'finalizer.dart';
import 'libudev.dart';

/// Enumerates and monitors kernel sys devices.
class UdevContext implements ffi.Finalizable {
  /// Creates a new context.
  factory UdevContext() {
    final ptr = udev.new_();
    final context = UdevContext.fromPointer(ptr);
    udev.unref(ptr);
    return context;
  }

  UdevContext._(this._ptr) {
    finalizer.attach(this, udev.ref(_ptr));
  }

  final ffi.Pointer<udev_t> _ptr;

  /// @internal
  static UdevContext fromPointer(ffi.Pointer<udev_t> ptr) {
    assert(ptr != ffi.nullptr);
    return UdevContext._(ptr);
  }

  /// @internal
  ffi.Pointer<udev_t> toPointer() => _ptr;
}
