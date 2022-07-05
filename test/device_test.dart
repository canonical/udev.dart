import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:udev/src/device.dart';
import 'package:udev/src/extensions.dart';
import 'package:udev/src/libudev.dart';

import 'mock_libudev.dart';
import 'test_data.dart';
import 'test_utils.dart';

void main() {
  test('device', () {
    ffi.using((arena) {
      final udev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev_t>.fromAddress(0xc),
      );
      overrideLibudevForTesting(udev);

      final aptr = ffi.Pointer<udev_device_t>.fromAddress(0xa);
      when(() => udev.device_ref(aptr)).thenReturn(aptr);
      final a = UdevDevice.fromPointer(aptr);
      expect(a, isNotNull);
      expect(a!.toPointer(), equals(aptr));

      final bptr = ffi.Pointer<udev_device_t>.fromAddress(0xb);
      when(() => udev.device_ref(bptr)).thenReturn(bptr);
      final b = UdevDevice.fromPointer(bptr);
      expect(b, isNotNull);
      expect(b!.toPointer(), equals(bptr));

      when(() => udev.device_get_syspath(aptr))
          .thenReturn('/sys/devices/fake'.toCString(allocator: arena));
      when(() => udev.device_get_syspath(bptr))
          .thenReturn('/sys/devices/fake'.toCString(allocator: arena));

      expect(a, equals(b));
      expect(a, isNot(same(b)));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), equals(b.toString()));
    });
  });

  test('net/wlan', () {
    ffi.using((arena) {
      final dev = ffi.Pointer<udev_device_t>.fromAddress(0xd);
      final udev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev_t>.fromAddress(0xc),
        devices: {dev: wlp0s20f3},
      );
      overrideLibudevForTesting(udev);

      expect(
        UdevDevice.fromSyspath(wlp0s20f3.syspath),
        equalsDevice(wlp0s20f3),
      );

      expect(
        UdevDevice.fromDevnum(wlp0s20f3.subsystem![0], wlp0s20f3.devnum),
        equalsDevice(wlp0s20f3),
      );

      expect(
        UdevDevice.fromSubsystemSysname(
            wlp0s20f3.subsystem!, wlp0s20f3.sysname),
        equalsDevice(wlp0s20f3),
      );

      expect(UdevDevice.fromDeviceId('n2'), equalsDevice(wlp0s20f3));
    });
  });

  test('block/disk', () {
    ffi.using((arena) {
      final dev = ffi.Pointer<udev_device_t>.fromAddress(0xd);
      final udev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev_t>.fromAddress(0xc),
        devices: {dev: nvme0n1},
      );
      overrideLibudevForTesting(udev);

      expect(UdevDevice.fromSyspath(nvme0n1.syspath), equalsDevice(nvme0n1));

      expect(
        UdevDevice.fromDevnum(nvme0n1.subsystem![0], nvme0n1.devnum),
        equalsDevice(nvme0n1),
      );

      expect(
        UdevDevice.fromSubsystemSysname(nvme0n1.subsystem!, nvme0n1.sysname),
        equalsDevice(nvme0n1),
      );

      expect(UdevDevice.fromDeviceId('b259:0'), equalsDevice(nvme0n1));
    });
  });

  test('sound/card', () {
    ffi.using((arena) {
      final dev = ffi.Pointer<udev_device_t>.fromAddress(0xd);
      final udev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev_t>.fromAddress(0xc),
        devices: {dev: card1},
      );
      overrideLibudevForTesting(udev);

      expect(UdevDevice.fromSyspath(card1.syspath), equalsDevice(card1));

      expect(
        UdevDevice.fromDevnum(card1.subsystem![0], card1.devnum),
        equalsDevice(card1),
      );

      expect(
        UdevDevice.fromSubsystemSysname(card1.subsystem!, card1.sysname),
        equalsDevice(card1),
      );

      expect(UdevDevice.fromDeviceId('sound:card1'), equalsDevice(card1));
    });
  });

  test('find parent', () {
    ffi.using((arena) {
      final dev = ffi.Pointer<udev_device_t>.fromAddress(0xd);
      final udev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev_t>.fromAddress(0xc),
        devices: {dev: nvme0n1},
      );
      overrideLibudevForTesting(udev);

      when(() => udev.device_get_parent_with_subsystem_devtype(
          dev,
          any(that: isCString('subsystem')),
          any(that: isCString('devtype')))).thenReturn(ffi.nullptr);

      final device = UdevDevice.fromSyspath(nvme0n1.syspath);
      expect(
        device.findParent(subsystem: 'subsystem', devtype: 'devtype'),
        isNull,
      );

      verify(() =>
              udev.device_get_parent_with_subsystem_devtype(dev, any(), any()))
          .called(1);
    });
  });

  test('sysattrs', () {
    ffi.using((arena) {
      final dev = ffi.Pointer<udev_device_t>.fromAddress(0xd);
      final udev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev_t>.fromAddress(0xc),
        devices: {dev: nvme0n1},
      );
      overrideLibudevForTesting(udev);

      final device = UdevDevice.fromSyspath(nvme0n1.syspath);
      device.sysattrs['foo'] = 'bar';
      expect(device.sysattrs['foo'], equals('bar'));
    });
  });

  test('tags', () {
    ffi.using((arena) {
      final dev = ffi.Pointer<udev_device_t>.fromAddress(0xd);
      final udev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev_t>.fromAddress(0xc),
        devices: {dev: nvme0n1},
      );
      overrideLibudevForTesting(udev);

      final device = UdevDevice.fromSyspath(nvme0n1.syspath);
      expect(device.tags.contains('systemd'), isTrue);
      expect(device.tags.contains('foobar'), isFalse);
    });
  });
}
