import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;

import 'context.dart';
import 'extensions.dart';
import 'finalizer.dart';
import 'libudev.dart';
import 'list_entry.dart';

/// Enumerates kernel sys devices.
extension UdevEnumerate on UdevContext {
  /// Returns matching kernel sys devices.
  Iterable<String> enumerateDevices({
    List<String> subsystems = const [],
    List<String> sysnames = const [],
    Map<String, String?> properties = const {},
    Map<String, String?> sysattrs = const {},
    List<String> tags = const [],
  }) {
    return ffi.using((arena) {
      final ptr = udev.enumerate_new(toPointer());
      for (final subsystem in subsystems) {
        udev.enumerate_add_match_subsystem(
            ptr, subsystem.toCString(allocator: arena));
      }
      for (final sysname in sysnames) {
        udev.enumerate_add_match_sysname(
            ptr, sysname.toCString(allocator: arena));
      }
      for (final property in properties.entries) {
        udev.enumerate_add_match_property(
            ptr,
            property.key.toCString(allocator: arena),
            property.value?.toCString(allocator: arena) ?? ffi.nullptr);
      }
      for (final sysattr in sysattrs.entries) {
        udev.enumerate_add_match_sysattr(
            ptr,
            sysattr.key.toCString(allocator: arena),
            sysattr.value?.toCString(allocator: arena) ?? ffi.nullptr);
      }
      for (final tag in tags) {
        udev.enumerate_add_match_tag(ptr, tag.toCString(allocator: arena));
      }
      udev.enumerate_scan_devices(ptr);
      final devices = _UdevEnumerator(ptr);
      udev.enumerate_unref(ptr);
      return devices;
    });
  }
}

class _UdevEnumerator extends UdevIterable implements ffi.Finalizable {
  _UdevEnumerator(ffi.Pointer<udev_enumerate_t> ptr)
      : super(udev.enumerate_get_list_entry(ptr)) {
    finalizer.attach(this, udev.enumerate_ref(ptr));
  }
}
