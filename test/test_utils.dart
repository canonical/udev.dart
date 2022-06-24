import 'dart:ffi' as ffi;

import 'package:test/test.dart';
import 'package:udev/src/extensions.dart';
import 'package:udev/udev.dart';

TypeMatcher<ffi.Pointer<T>> isPointer<T extends ffi.NativeType>([
  int? address,
]) {
  final matcher = isA<ffi.Pointer<T>>();
  return address == null
      ? matcher
      : matcher.having((p) => p.address, 'address', address);
}

TypeMatcher<ffi.Pointer<ffi.Char>> isCString(dynamic matcher) {
  return isPointer<ffi.Char>()
      .having((p) => p.toDartString(), 'toDartString', matcher);
}

Matcher equalsDevice(UdevDevice device) {
  return isA<UdevDevice>()
      .having((d) => d.devpath, 'devpath', device.devpath)
      .having((d) => d.subsystem, 'subsystem', device.subsystem)
      .having((d) => d.devtype, 'devtype', device.devtype)
      .having((d) => d.syspath, 'syspath', device.syspath)
      .having((d) => d.sysname, 'sysname', device.sysname)
      .having((d) => d.sysnum, 'sysnum', device.sysnum)
      .having((d) => d.devnode, 'devnode', device.devnode)
      .having((d) => d.isInitialized, 'isInitialized', device.isInitialized)
      .having((d) => d.driver, 'driver', device.driver)
      .having((d) => d.devnum, 'devnum', device.devnum)
      .having((d) => d.action, 'action', device.action)
      .having((d) => d.seqnum, 'seqnum', device.seqnum)
      .having((d) => d.devlinks, 'devlinks', device.devlinks)
      .having((d) => d.properties, 'properties', device.properties)
      .having((d) => d.tags, 'tags', device.tags)
      .having((d) => d.sysattrs, 'sysattrs', device.sysattrs)
      .having((d) => d.parent, 'parent', device.parent);
}
