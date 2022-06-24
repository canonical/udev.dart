import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:udev/src/bindings.g.dart';
import 'package:udev/src/device.dart';
import 'package:udev/src/dylib.dart';

import 'mock_libudev.dart';
import 'test_data.dart';

void main() {
  test('net/wlan', () {
    ffi.using((arena) {
      final dev = ffi.Pointer<udev_device>.fromAddress(0xd);
      final libudev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev>.fromAddress(0xc),
        devices: {dev: wlp0s20f3},
      );
      overrideLibudevForTesting(libudev);

      expect(
        UdevDevice.fromSyspath(wlp0s20f3.syspath),
        equals(wlp0s20f3),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);

      expect(
        UdevDevice.fromDevnum(wlp0s20f3.subsystem![0], wlp0s20f3.devnum),
        equals(wlp0s20f3),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);

      expect(
        UdevDevice.fromSubsystemSysname(
            wlp0s20f3.subsystem!, wlp0s20f3.sysname),
        equals(wlp0s20f3),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);

      expect(
        UdevDevice.fromDeviceId('n2'),
        equals(wlp0s20f3),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);
    });
  });

  test('block/disk', () {
    ffi.using((arena) {
      final dev = ffi.Pointer<udev_device>.fromAddress(0xd);
      final libudev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev>.fromAddress(0xc),
        devices: {dev: nvme0n1},
      );
      overrideLibudevForTesting(libudev);

      expect(
        UdevDevice.fromSyspath(nvme0n1.syspath),
        equals(nvme0n1),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);

      expect(
        UdevDevice.fromDevnum(nvme0n1.subsystem![0], nvme0n1.devnum),
        equals(nvme0n1),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);

      expect(
        UdevDevice.fromSubsystemSysname(nvme0n1.subsystem!, nvme0n1.sysname),
        equals(nvme0n1),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);

      expect(
        UdevDevice.fromDeviceId('b259:0'), // block<major>:<minor>
        equals(nvme0n1),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);
    });
  });

  test('sound/card', () {
    ffi.using((arena) {
      final dev = ffi.Pointer<udev_device>.fromAddress(0xd);
      final libudev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev>.fromAddress(0xc),
        devices: {dev: card1},
      );
      overrideLibudevForTesting(libudev);

      expect(
        UdevDevice.fromSyspath(card1.syspath),
        equals(card1),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);

      expect(
        UdevDevice.fromDevnum(card1.subsystem![0], card1.devnum),
        equals(card1),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);

      expect(
        UdevDevice.fromSubsystemSysname(card1.subsystem!, card1.sysname),
        equals(card1),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);

      expect(
        UdevDevice.fromDeviceId('sound:card1'),
        equals(card1),
      );
      verify(() => libudev.udev_device_unref(dev)).called(1);
    });
  });
}
