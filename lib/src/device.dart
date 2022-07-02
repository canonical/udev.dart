import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:meta/meta.dart';

import 'extensions.dart';
import 'finalizer.dart';
import 'libudev.dart';
import 'list_entry.dart';

@immutable
class UdevDevice implements ffi.Finalizable {
  UdevDevice._(this._ptr) {
    finalizer.attach(this, udev.device_ref(_ptr));
  }

  final ffi.Pointer<udev_device_t> _ptr;

  /// @internal
  static UdevDevice? fromPointer(ffi.Pointer<udev_device_t> ptr) {
    if (ptr == ffi.nullptr) return null;
    return UdevDevice._(ptr);
  }

  /// @internal
  ffi.Pointer<udev_device_t> toPointer() => _ptr;

  /// The kernel devpath value.
  ///
  /// The path does not contain the sys mount point, and starts with a `/`.
  String get devpath => udev.device_get_devpath(_ptr).toDartString()!;

  /// The subsystem name.
  String? get subsystem => udev.device_get_subsystem(_ptr).toDartString();

  /// The device type name.
  String? get devtype => udev.device_get_devtype(_ptr).toDartString();

  /// The sys path value.
  ///
  /// The path is absolute and starts with the sys mount point.
  String get syspath => udev.device_get_syspath(_ptr).toDartString()!;

  /// The kernel device name in /sys.
  String get sysname => udev.device_get_sysname(_ptr).toDartString()!;

  /// The trailing instance number.
  String? get sysnum => udev.device_get_sysnum(_ptr).toDartString();

  /// The device node file name.
  ///
  /// The path is absolute and starts with the device directory.
  String? get devnode => udev.device_get_devnode(_ptr).toDartString();

  /// Whether the device is set up.
  ///
  /// This is only implemented for devices with a device node or network
  /// interfaces. All other devices return `true`.
  bool get isInitialized => udev.device_get_is_initialized(_ptr) != 0;

  /// The kernel driver name.
  String? get driver => udev.device_get_driver(_ptr).toDartString();

  /// The device major/minor number.
  int get devnum => udev.device_get_devnum(_ptr);

  /// The kernel action value.
  ///
  /// Usual actions are: "add", "remove", "change", "online", "offline".
  ///
  /// This is only valid if the device was received through a monitor. Devices
  /// read from sys do not have an action string.
  String? get action => udev.device_get_action(_ptr).toDartString();

  /// The kernel event sequence number.
  int get seqnum => udev.device_get_seqnum(_ptr);

  /// The time since the device was first seen.
  ///
  /// This is only implemented for devices with need to store properties in the
  /// udev database. All other devices return 0.
  Duration get timeSinceInitialized =>
      Duration(microseconds: udev.device_get_usec_since_initialized(_ptr));

  /// The device links pointing to the device file.
  ///
  /// The path is absolute and starts with the device directory.
  Iterable<String> get devlinks => _UdevDevlinks(_ptr);

  /// The device properties.
  Map<String, String?> get properties => UdevPropertyMap(_ptr);

  /// The tags attached to the device.
  Iterable<String> get tags => _UdevTags(_ptr);

  /// The sys attributes.
  Map<String, String?> get sysattrs => UdevSysattrMap(_ptr);

  /// The parent device.
  UdevDevice? get parent =>
      UdevDevice.fromPointer(udev.device_get_parent(_ptr));

  UdevDevice? getParentWithSubsystemDevtype(
    String subsystem, [
    String? devtype,
  ]) {
    return ffi.using((arena) {
      final csubsystem = subsystem.toCString(allocator: arena);
      final cdevtype = devtype?.toCString(allocator: arena) ?? ffi.nullptr;
      return UdevDevice.fromPointer(
          udev.device_get_parent_with_subsystem_devtype(
        _ptr,
        csubsystem,
        cdevtype,
      ));
    });
  }

  @override
  bool operator ==(Object other) =>
      other is UdevDevice && other.syspath == syspath;

  @override
  int get hashCode => syspath.hashCode;

  @override
  String toString() => 'UdevDevice(syspath: $syspath)';
}

class _UdevDevlinks extends UdevIterable implements ffi.Finalizable {
  _UdevDevlinks(ffi.Pointer<udev_device_t> ptr)
      : super(udev.device_get_devlinks_list_entry(ptr)) {
    finalizer.attach(this, udev.device_ref(ptr));
  }
}

class _UdevTags extends UdevIterable implements ffi.Finalizable {
  _UdevTags(this._ptr) : super(udev.device_get_tags_list_entry(_ptr)) {
    finalizer.attach(this, udev.device_ref(_ptr));
  }

  final ffi.Pointer<udev_device_t> _ptr;

  @override
  bool contains(Object? element) {
    if (element is! String) return false;
    return ffi.using((arena) {
      final ctag = element.toCString(allocator: arena);
      return udev.device_has_tag(_ptr, ctag) != 0;
    });
  }
}
