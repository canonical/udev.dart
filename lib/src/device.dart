import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;
import 'package:meta/meta.dart';

import 'context.dart';
import 'exception.dart';
import 'extensions.dart';
import 'finalizer.dart';
import 'libudev.dart';
import 'list_entry.dart';

@immutable
class UdevDevice implements ffi.Finalizable {
  UdevDevice._(this._ptr) {
    finalizer.attach(this, udev.device_ref(_ptr));
  }

  factory UdevDevice.fromSyspath(String syspath, {UdevContext? context}) {
    return ffi.using((arena) {
      final csyspath = syspath.toCString(allocator: arena);
      final dev = _tryCreate(
        context,
        (ctx) => udev.device_new_from_syspath(ctx, csyspath),
      );
      return dev.orThrowIfNull(UdevSyspathException(syspath));
    });
  }

  factory UdevDevice.fromDevnum(
    String type,
    int devnum, {
    UdevContext? context,
  }) {
    return ffi.using((arena) {
      assert(type.length == 1, type);
      final ctype = type.codeUnitAt(0);
      final dev = _tryCreate(
        context,
        (ctx) => udev.device_new_from_devnum(ctx, ctype, devnum),
      );
      return dev.orThrowIfNull(UdevDevnumException(type, devnum));
    });
  }

  factory UdevDevice.fromSubsystemSysname(
    String subsystem,
    String sysname, {
    UdevContext? context,
  }) {
    return ffi.using((arena) {
      final csubsystem = subsystem.toCString(allocator: arena);
      final csysname = sysname.toCString(allocator: arena);
      final dev = _tryCreate(
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

  factory UdevDevice.fromDeviceId(String id, {UdevContext? context}) {
    return ffi.using((arena) {
      final cid = id.toCString(allocator: arena);
      final dev = _tryCreate(
        context,
        (ctx) => udev.device_new_from_device_id(ctx, cid),
      );
      return dev.orThrowIfNull(UdevDeviceIdException(id));
    });
  }

  factory UdevDevice.fromEnvironment({UdevContext? context}) {
    return ffi.using((arena) {
      final dev = _tryCreate(
        context,
        (ctx) => udev.device_new_from_environment(ctx),
      );
      return dev.orThrowIfNull(UdevEnvironmentException(Platform.environment));
    });
  }

  static UdevDevice? fromPointer(ffi.Pointer<udev_device_t> ptr) {
    if (ptr == ffi.nullptr) return null;
    return UdevDevice._(ptr);
  }

  String get devpath => udev.device_get_devpath(_ptr).toDartString()!;
  String? get subsystem => udev.device_get_subsystem(_ptr).toDartString();
  String? get devtype => udev.device_get_devtype(_ptr).toDartString();
  String get syspath => udev.device_get_syspath(_ptr).toDartString()!;
  String get sysname => udev.device_get_sysname(_ptr).toDartString()!;
  String? get sysnum => udev.device_get_sysnum(_ptr).toDartString();
  String? get devnode => udev.device_get_devnode(_ptr).toDartString();
  bool get isInitialized => udev.device_get_is_initialized(_ptr) != 0;
  String? get driver => udev.device_get_driver(_ptr).toDartString();
  int get devnum => udev.device_get_devnum(_ptr);
  String? get action => udev.device_get_action(_ptr).toDartString();
  int get seqnum => udev.device_get_seqnum(_ptr);
  Duration get timeSinceInitialized =>
      Duration(microseconds: udev.device_get_usec_since_initialized(_ptr));
  Iterable<String> get devlinks => _UdevDevlinks(_ptr);
  Map<String, String?> get properties => UdevPropertyMap(_ptr);
  Iterable<String> get tags => _UdevTags(_ptr);
  Map<String, String?> get sysattrs => UdevSysattrMap(_ptr);
  UdevDevice? get parent =>
      UdevDevice.fromPointer(udev.device_get_parent(_ptr));

  static UdevDevice? _tryCreate(
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

  ffi.Pointer<udev_device_t> toPointer() => _ptr;

  final ffi.Pointer<udev_device_t> _ptr;

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
