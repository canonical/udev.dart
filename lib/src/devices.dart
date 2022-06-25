import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;

import 'context.dart';
import 'device.dart';
import 'exception.dart';
import 'extensions.dart';
import 'libudev.dart';

abstract class UdevDevices {
  const UdevDevices._();

  static UdevDevice fromSyspath(String syspath, {UdevContext? context}) {
    return ffi.using((arena) {
      final csyspath = syspath.toCString(allocator: arena);
      final dev = _tryCreate(
        context,
        (ctx) => udev.device_new_from_syspath(ctx, csyspath),
      );
      return dev.orThrowIfNull(UdevSyspathException(syspath));
    });
  }

  static UdevDevice fromDevnum(
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

  static UdevDevice fromSubsystemSysname(
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

  static UdevDevice fromDeviceId(String id, {UdevContext? context}) {
    return ffi.using((arena) {
      final cid = id.toCString(allocator: arena);
      final dev = _tryCreate(
        context,
        (ctx) => udev.device_new_from_device_id(ctx, cid),
      );
      return dev.orThrowIfNull(UdevDeviceIdException(id));
    });
  }

  static UdevDevice fromEnvironment({UdevContext? context}) {
    return ffi.using((arena) {
      final dev = _tryCreate(
        context,
        (ctx) => udev.device_new_from_environment(ctx),
      );
      return dev.orThrowIfNull(UdevEnvironmentException(Platform.environment));
    });
  }

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
}
