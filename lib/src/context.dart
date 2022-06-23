import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:meta/meta.dart';

import 'bindings.g.dart';
import 'dylib.dart';
import 'extensions.dart';
import 'list_entry.dart';

@immutable
class UdevContext {
  factory UdevContext() => UdevContext.fromPointer(dylib.udev_new());

  const UdevContext.fromPointer(ffi.Pointer<udev> ptr) : _ptr = ptr;

  ffi.Pointer<udev> toPointer() => _ptr;

  final ffi.Pointer<udev> _ptr;

  List<String> scanDevices({
    List<String> subsystems = const [],
    List<String> sysnames = const [],
    Map<String, String?> properties = const {},
    Map<String, String?> sysattrs = const {},
    List<String> tags = const [],
  }) {
    return ffi.using((arena) {
      final ptr = dylib.udev_enumerate_new(toPointer());
      for (final subsystem in subsystems) {
        dylib.udev_enumerate_add_match_subsystem(
            ptr, subsystem.toCString(allocator: arena));
      }
      for (final sysname in sysnames) {
        dylib.udev_enumerate_add_match_sysname(
            ptr, sysname.toCString(allocator: arena));
      }
      for (final property in properties.entries) {
        dylib.udev_enumerate_add_match_property(
            ptr,
            property.key.toCString(allocator: arena),
            property.value?.toCString(allocator: arena) ?? ffi.nullptr);
      }
      for (final sysattr in sysattrs.entries) {
        dylib.udev_enumerate_add_match_sysattr(
            ptr,
            sysattr.key.toCString(allocator: arena),
            sysattr.value?.toCString(allocator: arena) ?? ffi.nullptr);
      }
      for (final tag in tags) {
        dylib.udev_enumerate_add_match_tag(
            ptr, tag.toCString(allocator: arena));
      }
      dylib.udev_enumerate_scan_devices(ptr);
      final devices = dylib.udev_enumerate_get_list_entry(ptr).toDartList();
      dylib.udev_enumerate_unref(ptr);
      return devices;
    });
  }

  void dispose() => dylib.udev_unref(_ptr);

  @override
  int get hashCode => _ptr.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UdevContext && _ptr == other._ptr;
  }
}
