import 'dart:ffi' as ffi;

import 'package:mockito/mockito.dart';
import 'package:udev/src/bindings.g.dart';
import 'package:udev/src/device.dart';
import 'package:udev/src/extensions.dart';

import 'test_utils.dart';

// ignore_for_file: return_of_invalid_type, non_constant_identifier_names

MockLibudev createMockLibudev({
  ffi.Pointer<udev>? context,
  Map<ffi.Pointer<udev_device>, UdevDevice> devices = const {},
  required ffi.Allocator allocator,
}) {
  final libudev = MockLibudev();

  final ctx = ffi.Pointer<udev>.fromAddress(0xc);
  when(libudev.udev_new()).thenReturn(ctx);
  when(libudev.udev_unref(ctx)).thenReturn(ffi.nullptr);

  for (final entry in devices.entries) {
    final ptr = entry.key;
    final device = entry.value;
    when(libudev.udev_device_new_from_syspath(
      ctx,
      argThat(isCString(device.syspath)),
    )).thenReturn(ptr);
    when(libudev.udev_device_new_from_devnum(
      ctx,
      device.subsystem.codeUnitAt(0),
      device.devnum,
    )).thenReturn(ptr);
    when(libudev.udev_device_new_from_subsystem_sysname(
      ctx,
      argThat(isCString(device.subsystem)),
      argThat(isCString(device.sysname)),
    )).thenReturn(ptr);

    if (device.properties.containsKey('IFINDEX')) {
      when(libudev.udev_device_new_from_device_id(
        ctx,
        argThat(isCString('n${device.properties['IFINDEX']}')),
      )).thenReturn(ptr);
    } else if (device.properties.containsKey('MAJOR') &&
        device.properties.containsKey('MINOR')) {
      when(libudev.udev_device_new_from_device_id(
        ctx,
        argThat(isCString(
            'b${device.properties['MAJOR']}:${device.properties['MINOR']}')),
      )).thenReturn(ptr);
    } else {
      when(libudev.udev_device_new_from_device_id(
        ctx,
        argThat(isCString('${device.subsystem}:${device.sysname}')),
      )).thenReturn(ptr);
    }

    when(libudev.udev_device_unref(ptr)).thenReturn(ffi.nullptr);

    when(libudev.udev_device_get_devpath(ptr))
        .thenReturn(device.devpath.toCString(allocator: allocator));
    when(libudev.udev_device_get_subsystem(ptr))
        .thenReturn(device.subsystem.toCString(allocator: allocator));
    when(libudev.udev_device_get_devtype(ptr)).thenReturn(
        device.devtype?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(libudev.udev_device_get_syspath(ptr))
        .thenReturn(device.syspath.toCString(allocator: allocator));
    when(libudev.udev_device_get_sysname(ptr))
        .thenReturn(device.sysname.toCString(allocator: allocator));
    when(libudev.udev_device_get_sysnum(ptr)).thenReturn(
        device.sysnum?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(libudev.udev_device_get_devnode(ptr)).thenReturn(
        device.devnode?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(libudev.udev_device_get_is_initialized(ptr))
        .thenReturn(device.isInitialized ? 1 : 0);
    when(libudev.udev_device_get_driver(ptr)).thenReturn(
        device.driver?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(libudev.udev_device_get_devnum(ptr)).thenReturn(device.devnum);
    when(libudev.udev_device_get_action(ptr)).thenReturn(
        device.action?.toCString(allocator: allocator) ?? ffi.nullptr);
    when(libudev.udev_device_get_seqnum(ptr)).thenReturn(device.seqnum);

    final devlinks =
        _createMockListEntries(libudev, device.devlinks, allocator: allocator);
    when(libudev.udev_device_get_devlinks_list_entry(ptr)).thenReturn(devlinks);

    final properties =
        _createMockMapEntries(libudev, device.properties, allocator: allocator);
    when(libudev.udev_device_get_properties_list_entry(ptr))
        .thenReturn(properties);

    final tags =
        _createMockListEntries(libudev, device.tags, allocator: allocator);
    when(libudev.udev_device_get_tags_list_entry(ptr)).thenReturn(tags);

    final sysattrs =
        _createMockMapEntries(libudev, device.sysattrs, allocator: allocator);
    when(libudev.udev_device_get_sysattr_list_entry(ptr)).thenReturn(sysattrs);
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
