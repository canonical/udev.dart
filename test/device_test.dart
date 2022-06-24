import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:test/test.dart';
import 'package:udev/src/device.dart';
import 'package:udev/src/libudev.dart';

import 'mock_libudev.dart';
import 'test_data.dart';
import 'test_utils.dart';

void main() {
  test('net/wlan', () {
    ffi.using((arena) {
      final dev = ffi.Pointer<udev_device_t>.fromAddress(0xd);
      final udev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev_t>.fromAddress(0xc),
        devices: {dev: wlp0s20f3},
      );
      overrideLibudevForTesting(udev);

      final syspath = UdevDevice.fromSyspath(wlp0s20f3.syspath);
      addTearDown(syspath.dispose);
      expect(syspath, equalsDevice(wlp0s20f3));

      final devnum =
          UdevDevice.fromDevnum(wlp0s20f3.subsystem![0], wlp0s20f3.devnum);
      addTearDown(devnum.dispose);
      expect(devnum, equalsDevice(wlp0s20f3));

      final subsystemSysname = UdevDevice.fromSubsystemSysname(
          wlp0s20f3.subsystem!, wlp0s20f3.sysname);
      addTearDown(subsystemSysname.dispose);
      expect(subsystemSysname, equalsDevice(wlp0s20f3));

      final deviceId = UdevDevice.fromDeviceId('n2');
      addTearDown(deviceId.dispose);
      expect(deviceId, equalsDevice(wlp0s20f3));
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

      final syspath = UdevDevice.fromSyspath(nvme0n1.syspath);
      addTearDown(syspath.dispose);
      expect(syspath, equalsDevice(nvme0n1));

      final devnum =
          UdevDevice.fromDevnum(nvme0n1.subsystem![0], nvme0n1.devnum);
      addTearDown(devnum.dispose);
      expect(devnum, equalsDevice(nvme0n1));

      final subsystemSysname =
          UdevDevice.fromSubsystemSysname(nvme0n1.subsystem!, nvme0n1.sysname);
      addTearDown(subsystemSysname.dispose);
      expect(subsystemSysname, equalsDevice(nvme0n1));

      final deviceId =
          UdevDevice.fromDeviceId('b259:0'); // block<major>:<minor>
      addTearDown(deviceId.dispose);
      expect(deviceId, equalsDevice(nvme0n1));
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

      final syspath = UdevDevice.fromSyspath(card1.syspath);
      addTearDown(syspath.dispose);
      expect(syspath, equalsDevice(card1));

      final devnum = UdevDevice.fromDevnum(card1.subsystem![0], card1.devnum);
      addTearDown(devnum.dispose);
      expect(devnum, equalsDevice(card1));

      final subsystemSysname =
          UdevDevice.fromSubsystemSysname(card1.subsystem!, card1.sysname);
      addTearDown(subsystemSysname.dispose);
      expect(subsystemSysname, equalsDevice(card1));

      final deviceId = UdevDevice.fromDeviceId('sound:card1');
      addTearDown(deviceId.dispose);
      expect(deviceId, equalsDevice(card1));
    });
  });
}
