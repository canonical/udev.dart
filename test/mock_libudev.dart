import 'dart:ffi' as ffi;

import 'package:collection/collection.dart';
import 'package:mockito/mockito.dart';
import 'package:udev/src/bindings.g.dart';
import 'package:udev/src/device.dart';
import 'package:udev/src/extensions.dart';

import 'test_utils.dart';

// ignore_for_file: return_of_invalid_type, non_constant_identifier_names

MockLibudev createMockLibudev({
  required ffi.Allocator allocator,
  ffi.Pointer<udev>? context,
  ffi.Pointer<udev_enumerate>? enumerate,
  List<String> scan = const [],
  Map<ffi.Pointer<udev_device>, UdevDevice> devices = const {},
}) {
  final libudev = MockLibudev();

  final ctxptr = context ?? ffi.Pointer<udev>.fromAddress(0x1234);
  when(libudev.udev_new()).thenReturn(ctxptr);
  when(libudev.udev_unref(ctxptr)).thenReturn(ffi.nullptr);

  final enumptr = enumerate ?? ffi.Pointer<udev_enumerate>.fromAddress(0x5678);
  when(libudev.udev_enumerate_new(ctxptr)).thenReturn(enumptr);
  when(libudev.udev_enumerate_unref(enumptr)).thenReturn(ffi.nullptr);
  when(libudev.udev_enumerate_scan_devices(enumerate)).thenReturn(0);

  final results = _createMockListEntries(libudev, scan, allocator: allocator);
  when(libudev.udev_enumerate_get_list_entry(enumptr)).thenReturn(results);

  for (final entry in devices.entries) {
    final devptr = entry.key;
    final device = entry.value;
    when(libudev.udev_device_new_from_syspath(
      ctxptr,
      argThat(isCString(device.syspath)),
    )).thenReturn(devptr);
    when(libudev.udev_device_new_from_devnum(
      ctxptr,
      device.subsystem.codeUnits.firstOrNull,
      device.devnum,
    )).thenReturn(devptr);
    when(libudev.udev_device_new_from_subsystem_sysname(
      ctxptr,
      argThat(isCString(device.subsystem)),
      argThat(isCString(device.sysname)),
    )).thenReturn(devptr);

    if (device.properties.containsKey('IFINDEX')) {
      when(libudev.udev_device_new_from_device_id(
        ctxptr,
        argThat(isCString('n${device.properties['IFINDEX']}')),
      )).thenReturn(devptr);
    } else if (device.properties.containsKey('MAJOR') &&
        device.properties.containsKey('MINOR')) {
      when(libudev.udev_device_new_from_device_id(
        ctxptr,
        argThat(isCString(
            'b${device.properties['MAJOR']}:${device.properties['MINOR']}')),
      )).thenReturn(devptr);
    } else {
      when(libudev.udev_device_new_from_device_id(
        ctxptr,
        argThat(isCString('${device.subsystem}:${device.sysname}')),
      )).thenReturn(devptr);
    }

    when(libudev.udev_device_unref(devptr)).thenReturn(ffi.nullptr);

    when(libudev.udev_device_get_devpath(devptr))
        .thenReturn(device.devpath.toCString(allocator: allocator));
    when(libudev.udev_device_get_subsystem(devptr))
        .thenReturn(device.subsystem.toCString(allocator: allocator));
    when(libudev.udev_device_get_devtype(devptr)).thenReturn(
        device.devtype?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(libudev.udev_device_get_syspath(devptr))
        .thenReturn(device.syspath.toCString(allocator: allocator));
    when(libudev.udev_device_get_sysname(devptr))
        .thenReturn(device.sysname.toCString(allocator: allocator));
    when(libudev.udev_device_get_sysnum(devptr)).thenReturn(
        device.sysnum?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(libudev.udev_device_get_devnode(devptr)).thenReturn(
        device.devnode?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(libudev.udev_device_get_is_initialized(devptr))
        .thenReturn(device.isInitialized ? 1 : 0);
    when(libudev.udev_device_get_driver(devptr)).thenReturn(
        device.driver?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(libudev.udev_device_get_devnum(devptr)).thenReturn(device.devnum);
    when(libudev.udev_device_get_action(devptr)).thenReturn(
        device.action?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(libudev.udev_device_get_seqnum(devptr)).thenReturn(device.seqnum);

    final devlinks =
        _createMockListEntries(libudev, device.devlinks, allocator: allocator);
    when(libudev.udev_device_get_devlinks_list_entry(devptr))
        .thenReturn(devlinks);

    final properties =
        _createMockMapEntries(libudev, device.properties, allocator: allocator);
    when(libudev.udev_device_get_properties_list_entry(devptr))
        .thenReturn(properties);

    final tags =
        _createMockListEntries(libudev, device.tags, allocator: allocator);
    when(libudev.udev_device_get_tags_list_entry(devptr)).thenReturn(tags);

    final sysattrs =
        _createMockMapEntries(libudev, device.sysattrs, allocator: allocator);
    when(libudev.udev_device_get_sysattr_list_entry(devptr))
        .thenReturn(sysattrs);
  }

  return libudev;
}

var _address = 0x80000000;
int get _nextAddress => _address += ffi.sizeOf<ffi.Pointer>();

ffi.Pointer<udev_list_entry> _createMockListEntries(
  Libudev libudev,
  List<String> values, {
  required ffi.Allocator allocator,
}) {
  final keys =
      Map<String, String?>.fromIterable(values, value: (dynamic k) => null);
  return _createMockMapEntries(libudev, keys, allocator: allocator);
}

ffi.Pointer<udev_list_entry> _createMockMapEntries(
  Libudev libudev,
  Map<String, String?> values, {
  required ffi.Allocator allocator,
}) {
  if (values.isEmpty) return ffi.nullptr;
  final ptr = ffi.Pointer<udev_list_entry>.fromAddress(_nextAddress);
  final entries = values.entries.toList();

  var it = ptr;
  for (var i = 0; i < entries.length; ++i) {
    final entry = entries[i];
    when(libudev.udev_list_entry_get_name(it))
        .thenReturn(entry.key.toCString(allocator: allocator));
    when(libudev.udev_list_entry_get_value(it)).thenReturn(
        entry.value?.toCString(allocator: allocator) ?? ffi.nullptr);
    final next = ffi.Pointer<udev_list_entry>.fromAddress(
        i < entries.length - 1 ? _nextAddress : 0);
    when(libudev.udev_list_entry_get_next(it)).thenReturn(next);
    it = next;
  }
  return ptr;
}

class MockLibudev extends Mock implements Libudev {
  @override
  ffi.Pointer<udev> udev_new() {
    return super.noSuchMethod(Invocation.method(#udev_new, []),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev> udev_unref(ffi.Pointer<udev>? udev) {
    return super.noSuchMethod(Invocation.method(#udev_unref, [udev]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_enumerate> udev_enumerate_new(ffi.Pointer<udev>? udev) {
    return super.noSuchMethod(Invocation.method(#udev_enumerate_new, [udev]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_enumerate> udev_enumerate_unref(
      ffi.Pointer<udev_enumerate>? udev_enumerate) {
    return super.noSuchMethod(Invocation.method(#udev_enumerate_unref, [udev]),
        returnValue: ffi.nullptr);
  }

  @override
  int udev_enumerate_add_match_sysname(
      ffi.Pointer<udev_enumerate>? udev_enumerate,
      ffi.Pointer<ffi.Char>? sysname) {
    return super.noSuchMethod(
        Invocation.method(
            #udev_enumerate_add_match_sysname, [udev_enumerate, sysname]),
        returnValue: 0);
  }

  @override
  int udev_enumerate_add_match_subsystem(
      ffi.Pointer<udev_enumerate>? udev_enumerate,
      ffi.Pointer<ffi.Char>? subsystem) {
    return super.noSuchMethod(
        Invocation.method(
            #udev_enumerate_add_match_subsystem, [udev_enumerate, subsystem]),
        returnValue: 0);
  }

  @override
  int udev_enumerate_add_match_tag(
      ffi.Pointer<udev_enumerate>? udev_enumerate, ffi.Pointer<ffi.Char>? tag) {
    return super.noSuchMethod(
        Invocation.method(#udev_enumerate_add_match_tag, [udev_enumerate, tag]),
        returnValue: 0);
  }

  @override
  int udev_enumerate_add_match_property(
      ffi.Pointer<udev_enumerate>? udev_enumerate,
      ffi.Pointer<ffi.Char>? property,
      ffi.Pointer<ffi.Char>? value) {
    return super.noSuchMethod(
        Invocation.method(#udev_enumerate_add_match_property,
            [udev_enumerate, property, value]),
        returnValue: 0);
  }

  @override
  int udev_enumerate_add_match_sysattr(
      ffi.Pointer<udev_enumerate>? udev_enumerate,
      ffi.Pointer<ffi.Char>? sysattr,
      ffi.Pointer<ffi.Char>? value) {
    return super.noSuchMethod(
        Invocation.method(#udev_enumerate_add_match_sysattr,
            [udev_enumerate, sysattr, value]),
        returnValue: 0);
  }

  @override
  int udev_enumerate_scan_devices(ffi.Pointer<udev_enumerate>? udev_enumerate) {
    return super.noSuchMethod(
        Invocation.method(#udev_enumerate_scan_devices, [udev_enumerate]),
        returnValue: 0);
  }

  @override
  ffi.Pointer<udev_list_entry> udev_enumerate_get_list_entry(
      ffi.Pointer<udev_enumerate> udev_enumerate) {
    return super.noSuchMethod(
        Invocation.method(#udev_enumerate_get_list_entry, [udev_enumerate]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_device> udev_device_new_from_syspath(
      ffi.Pointer<udev>? udev, ffi.Pointer<ffi.Char>? syspath) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_new_from_syspath, [udev, syspath]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_device> udev_device_new_from_devnum(
      ffi.Pointer<udev>? udev, int? type, int? devnum) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_new_from_devnum, [udev, type, devnum]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_device> udev_device_new_from_subsystem_sysname(
    ffi.Pointer<udev>? udev,
    ffi.Pointer<ffi.Char>? subsystem,
    ffi.Pointer<ffi.Char>? sysname,
  ) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_new_from_subsystem_sysname,
            [udev, subsystem, sysname]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_device> udev_device_new_from_device_id(
      ffi.Pointer<udev>? udev, ffi.Pointer<ffi.Char>? id) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_new_from_device_id, [udev, id]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_device> udev_device_new_from_environment(
      ffi.Pointer<udev>? udev) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_new_from_environment, [udev]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_device> udev_device_unref(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_unref, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<ffi.Char> udev_device_get_devpath(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_devpath, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<ffi.Char> udev_device_get_subsystem(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_subsystem, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<ffi.Char> udev_device_get_devtype(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_devtype, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<ffi.Char> udev_device_get_syspath(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_syspath, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<ffi.Char> udev_device_get_sysname(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_sysname, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<ffi.Char> udev_device_get_sysnum(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_sysnum, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<ffi.Char> udev_device_get_devnode(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_devnode, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  int udev_device_get_is_initialized(ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_is_initialized, [udev_device]),
        returnValue: 0);
  }

  @override
  ffi.Pointer<ffi.Char> udev_device_get_driver(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_driver, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  int udev_device_get_devnum(ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_devnum, [udev_device]),
        returnValue: -1);
  }

  @override
  ffi.Pointer<ffi.Char> udev_device_get_action(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_action, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  int udev_device_get_seqnum(ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_seqnum, [udev_device]),
        returnValue: -1);
  }

  @override
  ffi.Pointer<udev_list_entry> udev_device_get_devlinks_list_entry(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_devlinks_list_entry, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_list_entry> udev_device_get_properties_list_entry(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(
            #udev_device_get_properties_list_entry, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_list_entry> udev_device_get_tags_list_entry(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_tags_list_entry, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_list_entry> udev_device_get_sysattr_list_entry(
      ffi.Pointer<udev_device>? udev_device) {
    return super.noSuchMethod(
        Invocation.method(#udev_device_get_sysattr_list_entry, [udev_device]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<ffi.Char> udev_list_entry_get_name(
      ffi.Pointer<udev_list_entry>? list_entry) {
    return super.noSuchMethod(
        Invocation.method(#udev_list_entry_get_name, [list_entry]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<ffi.Char> udev_list_entry_get_value(
      ffi.Pointer<udev_list_entry>? list_entry) {
    return super.noSuchMethod(
        Invocation.method(#udev_list_entry_get_value, [list_entry]),
        returnValue: ffi.nullptr);
  }

  @override
  ffi.Pointer<udev_list_entry> udev_list_entry_get_next(
      ffi.Pointer<udev_list_entry>? list_entry) {
    return super.noSuchMethod(
        Invocation.method(#udev_list_entry_get_next, [list_entry]),
        returnValue: ffi.nullptr);
  }
}
