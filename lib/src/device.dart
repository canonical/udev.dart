import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:meta/meta.dart';

import 'context.dart';
import 'exception.dart';
import 'extensions.dart';
import 'finalizer.dart';
import 'libudev.dart';
import 'list_entry.dart';

/// Represents a kernel sys device.
///
/// Devices are uniquely identified by their syspath, every device has exactly
/// one path in the kernel sys filesystem. Devices usually belong to a kernel
/// subsystem, and have a unique name inside that subsystem.
@immutable
class UdevDevice implements ffi.Finalizable {
  UdevDevice._(this._ptr) {
    finalizer.attach(this, udev.device_ref(_ptr));
  }

  /// Creates a device from a [syspath] value.
  ///
  /// Optionally, a shared `context` can be provided to avoid temporarily
  /// creating a new one for the duration of the call.
  static UdevDevice fromSyspath(String syspath, {UdevContext? context}) {
    return ffi.using((arena) {
      final csyspath = syspath.toCString(allocator: arena);
      final dev = _createDevice(
        context,
        (ctx) => udev.device_new_from_syspath(ctx, csyspath),
      );
      return dev.orThrowIfNull(UdevSyspathException(syspath));
    });
  }

  /// Creates a device from [devtype] and [devnum] values.
  ///
  /// Optionally, a shared `context` can be provided to avoid temporarily
  /// creating a new one for the duration of the call.
  static UdevDevice fromDevnum(
    String devtype,
    int devnum, {
    UdevContext? context,
  }) {
    return ffi.using((arena) {
      assert(devtype.length == 1, devtype);
      final cdevtype = devtype.codeUnitAt(0);
      final dev = _createDevice(
        context,
        (ctx) => udev.device_new_from_devnum(ctx, cdevtype, devnum),
      );
      return dev.orThrowIfNull(UdevDevnumException(devtype, devnum));
    });
  }

  /// Creates a device from [subsystem] and [sysname] values.
  ///
  /// Optionally, a shared `context` can be provided to avoid temporarily
  /// creating a new one for the duration of the call.
  static UdevDevice fromSubsystemSysname(
    String subsystem,
    String sysname, {
    UdevContext? context,
  }) {
    return ffi.using((arena) {
      final csubsystem = subsystem.toCString(allocator: arena);
      final csysname = sysname.toCString(allocator: arena);
      final dev = _createDevice(
        context,
        (ctx) => udev.device_new_from_subsystem_sysname(
          ctx,
          csubsystem,
          csysname,
        ),
      );
      return dev
          .orThrowIfNull(UdevSubsystemSysnameException(subsystem, sysname));
    });
  }

  /// Creates a device from special device ID value.
  ///
  /// | ID | Description |
  /// |---|---|
  /// | `b8:2` | block device major:minor |
  /// | `c128:1` | char device major:minor |
  /// | `n3` | network device ifindex |
  /// | `+sound:card29` | kernel driver core subsystem:device name |
  ///
  /// Optionally, a shared `context` can be provided to avoid temporarily
  /// creating a new one for the duration of the call.
  static UdevDevice fromDeviceId(String id, {UdevContext? context}) {
    return ffi.using((arena) {
      final cid = id.toCString(allocator: arena);
      final dev = _createDevice(
        context,
        (ctx) => udev.device_new_from_device_id(ctx, cid),
      );
      return dev.orThrowIfNull(UdevDeviceIdException(id));
    });
  }

  static UdevDevice? _createDevice(
    UdevContext? context,
    ffi.Pointer<udev_device_t> Function(ffi.Pointer<udev_t> ctx) factory,
  ) {
    return ffi.using((arena) {
      final ctx = context ?? UdevContext();
      final ptr = factory(ctx.toPointer());
      final dev = UdevDevice.fromPointer(ptr);
      udev.device_unref(ptr);
      return dev;
    });
  }

  /// @internal
  static UdevDevice? fromPointer(ffi.Pointer<udev_device_t> ptr) {
    if (ptr == ffi.nullptr) return null;
    return UdevDevice._(ptr);
  }

  /// @internal
  ffi.Pointer<udev_device_t> toPointer() => _ptr;

  final ffi.Pointer<udev_device_t> _ptr;

  /// The kernel devpath value.
  ///
  /// The path does not contain the sys mount point, and starts with a `/`.
  String get devpath => udev.device_get_devpath(_ptr).toDartString()!;

  /// The subsystem name.
  String? get subsystem => udev.device_get_subsystem(_ptr).toDartString();

  /// The device type name.
  String? get devtype => udev.device_get_devtype(_ptr).toDartString();

  /// The syspath value.
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

  /// Find the next parent device.
  UdevDevice? findParent({required String subsystem, String? devtype}) {
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
