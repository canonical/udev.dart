import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:meta/meta.dart';

import 'bindings.g.dart';
import 'context.dart';
import 'dylib.dart';
import 'exception.dart';
import 'extensions.dart';
import 'list_entry.dart';

@immutable
class UdevDevice {
  const UdevDevice({
    required this.devpath,
    required this.subsystem,
    required this.devtype,
    required this.syspath,
    required this.sysname,
    required this.sysnum,
    required this.devnode,
    required this.isInitialized,
    required this.driver,
    required this.devnum,
    required this.action,
    required this.seqnum,
    required this.devlinks,
    required this.properties,
    required this.tags,
    required this.sysattrs,
    required this.parent,
  });

  factory UdevDevice.fromSyspath(String syspath, {UdevContext? context}) {
    return ffi.using((arena) {
      final csyspath = syspath.toCString(allocator: arena);
      final dev = _tryCreate(
        context,
        (ctx) => dylib.udev_device_new_from_syspath(ctx, csyspath),
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
        (ctx) => dylib.udev_device_new_from_devnum(ctx, ctype, devnum),
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
        (ctx) => dylib.udev_device_new_from_subsystem_sysname(
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
        (ctx) => dylib.udev_device_new_from_device_id(ctx, cid),
      );
      return dev.orThrowIfNull(UdevDeviceIdException(id));
    });
  }

  factory UdevDevice.fromEnvironment({UdevContext? context}) {
    return ffi.using((arena) {
      final dev = _tryCreate(
        context,
        (ctx) => dylib.udev_device_new_from_environment(ctx),
      );
      return dev.orThrowIfNull(UdevEnvironmentException(Platform.environment));
    });
  }

  static UdevDevice? fromPointer(ffi.Pointer<udev_device> ptr) {
    if (ptr == ffi.nullptr) return null;
    return UdevDevice(
      devpath: dylib.udev_device_get_devpath(ptr).toDartString()!,
      subsystem: dylib.udev_device_get_subsystem(ptr).toDartString(),
      devtype: dylib.udev_device_get_devtype(ptr).toDartString(),
      syspath: dylib.udev_device_get_syspath(ptr).toDartString()!,
      sysname: dylib.udev_device_get_sysname(ptr).toDartString()!,
      sysnum: dylib.udev_device_get_sysnum(ptr).toDartString(),
      devnode: dylib.udev_device_get_devnode(ptr).toDartString(),
      isInitialized: dylib.udev_device_get_is_initialized(ptr) != 0,
      driver: dylib.udev_device_get_driver(ptr).toDartString(),
      devnum: dylib.udev_device_get_devnum(ptr),
      action: dylib.udev_device_get_action(ptr).toDartString(),
      seqnum: dylib.udev_device_get_seqnum(ptr),
      devlinks: dylib.udev_device_get_devlinks_list_entry(ptr).toDartList(),
      properties: dylib.udev_device_get_properties_list_entry(ptr).toDartMap(),
      tags: dylib.udev_device_get_tags_list_entry(ptr).toDartList(),
      sysattrs: dylib.udev_device_get_sysattr_list_entry(ptr).toDartMap(),
      parent: fromPointer(dylib.udev_device_get_parent(ptr)),
    );
  }

  final String devpath;
  final String? subsystem;
  final String? devtype;
  final String syspath;
  final String sysname;
  final String? sysnum;
  final String? devnode;
  final bool isInitialized;
  final String? driver;
  final int devnum;
  final String? action;
  final int seqnum;
  final List<String> devlinks;
  final Map<String, String?> properties;
  final List<String> tags;
  final Map<String, String?> sysattrs;
  final UdevDevice? parent;

  static UdevDevice? _tryCreate(
    UdevContext? context,
    ffi.Pointer<udev_device> Function(ffi.Pointer<udev> ctx) factory,
  ) {
    return ffi.using((arena) {
      final ctx = context ?? UdevContext();
      final ptr = factory(ctx.toPointer());
      if (context == null) ctx.dispose();
      final dev = UdevDevice.fromPointer(ptr);
      dylib.udev_device_unref(ptr);
      return dev;
    });
  }

  @override
  String toString() {
    return 'UdevDevice(devpath: $devpath, subsystem: $subsystem, devtype: $devtype, syspath: $syspath, sysname: $sysname, sysnum: $sysnum, devnode: $devnode, isInitialized: $isInitialized, driver: $driver, devnum: $devnum, action: $action, seqnum: $seqnum, devlinks: $devlinks, properties: $properties, tags: $tags, sysattrs: $sysattrs, parent: $parent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    final mapEquals = const MapEquality<String, String?>().equals;
    final listEquals = const ListEquality<String>().equals;

    return other is UdevDevice &&
        other.devpath == devpath &&
        other.subsystem == subsystem &&
        other.devtype == devtype &&
        other.syspath == syspath &&
        other.sysname == sysname &&
        other.sysnum == sysnum &&
        other.devnode == devnode &&
        other.isInitialized == isInitialized &&
        other.driver == driver &&
        other.devnum == devnum &&
        other.action == action &&
        other.seqnum == seqnum &&
        listEquals(other.devlinks, devlinks) &&
        mapEquals(other.properties, properties) &&
        listEquals(other.tags, tags) &&
        mapEquals(other.sysattrs, sysattrs) &&
        other.parent == parent;
  }

  @override
  int get hashCode {
    final mapHash = const MapEquality<String, String?>().hash;
    final listHash = const ListEquality<String>().hash;

    return Object.hash(
      devpath,
      subsystem,
      devtype,
      syspath,
      sysname,
      sysnum,
      devnode,
      isInitialized,
      driver,
      devnum,
      action,
      seqnum,
      listHash(devlinks),
      mapHash(properties),
      listHash(tags),
      mapHash(sysattrs),
      parent,
    );
  }
}
