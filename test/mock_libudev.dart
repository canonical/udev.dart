import 'dart:ffi' as ffi;

import 'package:collection/collection.dart';
import 'package:mocktail/mocktail.dart';
import 'package:udev/src/device.dart';
import 'package:udev/src/extensions.dart';
import 'package:udev/src/libudev.dart';

import 'test_utils.dart';

// ignore_for_file: return_of_invalid_type, non_constant_identifier_names

class MockLibudev extends Mock implements Libudev {}

MockLibudev createMockLibudev({
  required ffi.Allocator allocator,
  ffi.Pointer<udev_t>? context,
  ffi.Pointer<udev_enumerate_t>? enumerate,
  List<String> scan = const [],
  Map<ffi.Pointer<udev_device_t>, UdevDevice> devices = const {},
}) {
  final udev = MockLibudev();

  registerFallbackValue(ffi.Pointer<ffi.Char>.fromAddress(0));

  final ctxptr = context ?? ffi.Pointer<udev_t>.fromAddress(0x1234);
  when(udev.new_).thenReturn(ctxptr);
  when(() => udev.ref(ctxptr)).thenReturn(ctxptr);
  when(() => udev.unref(ctxptr)).thenReturn(ffi.nullptr);

  final enumptr =
      enumerate ?? ffi.Pointer<udev_enumerate_t>.fromAddress(0x5678);
  when(() => udev.enumerate_new(ctxptr)).thenReturn(enumptr);
  when(() => udev.enumerate_ref(enumptr)).thenReturn(enumptr);
  when(() => udev.enumerate_unref(enumptr)).thenReturn(ffi.nullptr);
  when(() => udev.enumerate_scan_devices(enumptr)).thenReturn(0);

  final results = _createMockListEntries(udev, scan, allocator: allocator);
  when(() => udev.enumerate_get_list_entry(enumptr)).thenReturn(results);

  for (final entry in devices.entries) {
    final devptr = entry.key;
    final device = entry.value;
    when(() => udev.device_new_from_syspath(
          ctxptr,
          any(that: isCString(device.syspath)),
        )).thenReturn(devptr);
    when(() => udev.device_new_from_devnum(
          ctxptr,
          device.subsystem?.codeUnits.firstOrNull ?? 0,
          device.devnum,
        )).thenReturn(devptr);
    when(() => udev.device_new_from_subsystem_sysname(
          ctxptr,
          any(that: isCString(device.subsystem)),
          any(that: isCString(device.sysname)),
        )).thenReturn(devptr);

    if (device.properties.containsKey('IFINDEX')) {
      when(() => udev.device_new_from_device_id(
            ctxptr,
            any(that: isCString('n${device.properties['IFINDEX']}')),
          )).thenReturn(devptr);
    } else if (device.properties.containsKey('MAJOR') &&
        device.properties.containsKey('MINOR')) {
      when(() => udev.device_new_from_device_id(
            ctxptr,
            any(
                that: isCString(
                    'b${device.properties['MAJOR']}:${device.properties['MINOR']}')),
          )).thenReturn(devptr);
    } else {
      when(() => udev.device_new_from_device_id(
            ctxptr,
            any(that: isCString('${device.subsystem}:${device.sysname}')),
          )).thenReturn(devptr);
    }

    when(() => udev.device_ref(devptr)).thenReturn(devptr);
    when(() => udev.device_unref(devptr)).thenReturn(ffi.nullptr);

    when(() => udev.device_get_devpath(devptr))
        .thenReturn(device.devpath.toCString(allocator: allocator));
    when(() => udev.device_get_subsystem(devptr)).thenReturn(
        device.subsystem?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(() => udev.device_get_devtype(devptr)).thenReturn(
        device.devtype?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(() => udev.device_get_syspath(devptr))
        .thenReturn(device.syspath.toCString(allocator: allocator));
    when(() => udev.device_get_sysname(devptr))
        .thenReturn(device.sysname.toCString(allocator: allocator));
    when(() => udev.device_get_sysnum(devptr)).thenReturn(
        device.sysnum?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(() => udev.device_get_devnode(devptr)).thenReturn(
        device.devnode?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(() => udev.device_get_is_initialized(devptr))
        .thenReturn(device.isInitialized ? 1 : 0);
    when(() => udev.device_get_driver(devptr)).thenReturn(
        device.driver?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(() => udev.device_get_devnum(devptr)).thenReturn(device.devnum);
    when(() => udev.device_get_action(devptr)).thenReturn(
        device.action?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(() => udev.device_get_seqnum(devptr)).thenReturn(device.seqnum);

    final devlinks =
        _createMockListEntries(udev, device.devlinks, allocator: allocator);
    when(() => udev.device_get_devlinks_list_entry(devptr))
        .thenReturn(devlinks);

    final properties =
        _createMockMapEntries(udev, device.properties, allocator: allocator);
    when(() => udev.device_get_properties_list_entry(devptr))
        .thenReturn(properties);

    final tags =
        _createMockListEntries(udev, device.tags, allocator: allocator);
    when(() => udev.device_get_tags_list_entry(devptr)).thenReturn(tags);

    final sysattrs =
        _createMockMapEntries(udev, device.sysattrs, allocator: allocator);
    when(() => udev.device_get_sysattr_list_entry(devptr)).thenReturn(sysattrs);

    when(() => udev.device_get_parent(devptr)).thenReturn(ffi.nullptr);
  }

  return udev;
}

var _address = 0x80000000;
int get _nextAddress => _address += ffi.sizeOf<ffi.Pointer>();

ffi.Pointer<udev_list_entry_t> _createMockListEntries(
  Libudev libudev,
  List<String> values, {
  required ffi.Allocator allocator,
}) {
  final keys =
      Map<String, String?>.fromIterable(values, value: (dynamic k) => null);
  return _createMockMapEntries(libudev, keys, allocator: allocator);
}

ffi.Pointer<udev_list_entry_t> _createMockMapEntries(
  Libudev udev,
  Map<String, String?> values, {
  required ffi.Allocator allocator,
}) {
  if (values.isEmpty) return ffi.nullptr;
  final ptr = ffi.Pointer<udev_list_entry_t>.fromAddress(_nextAddress);
  final entries = values.entries.toList();

  var it = ptr;
  for (var i = 0; i < entries.length; ++i) {
    final entry = entries[i];
    when(() => udev.list_entry_get_name(it))
        .thenReturn(entry.key.toCString(allocator: allocator));
    when(() => udev.list_entry_get_value(it)).thenReturn(
        entry.value?.toCString(allocator: allocator) ?? ffi.nullptr);
    final next = ffi.Pointer<udev_list_entry_t>.fromAddress(
        i < entries.length - 1 ? _nextAddress : 0);
    when(() => udev.list_entry_get_next(it)).thenReturn(next);
    it = next;
  }
  return ptr;
}
