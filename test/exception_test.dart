import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:test/test.dart';
import 'package:udev/src/libudev.dart';
import 'package:udev/udev.dart';

import 'fake_device.dart';
import 'mock_libudev.dart';

void main() {
  test('exception', () {
    const syspath1 = UdevSyspathException('foo');
    expect(syspath1.toString(), contains('syspath: foo'));

    const syspath2 = UdevSyspathException('foo');
    expect(syspath2.toString(), contains('syspath: foo'));

    const syspath3 = UdevSyspathException('bar');
    expect(syspath3.toString(), contains('syspath: bar'));

    expect(syspath1, equals(syspath2));
    expect(syspath1, isNot(equals(syspath3)));
    expect(syspath1.hashCode, equals(syspath2.hashCode));
    expect(syspath1.hashCode, isNot(equals(syspath3.hashCode)));
    expect(syspath1, isNot(equals(UdevEnvironmentException({}))));
  });

  test('device not found', () {
    ffi.using((arena) {
      final dummy = FakeUdevDevice(
        devpath: 'DEVPATH',
        subsystem: 'SUBSYSTEM',
        devtype: 'DEVTYPE',
        syspath: 'SYSPATH',
        sysname: 'SYSNAME',
        sysnum: 'SYSNUM',
        devnode: null,
        isInitialized: false,
        driver: null,
        devnum: 123,
        action: null,
        seqnum: 0,
        devlinks: [],
        properties: {},
        tags: [],
        sysattrs: {},
        parent: null,
      );

      final libudev = createMockLibudev(
        allocator: arena,
        context: ffi.Pointer<udev_t>.fromAddress(0xc),
        devices: {ffi.nullptr: dummy},
      );
      overrideLibudevForTesting(libudev);

      expect(
        () => UdevDevice.fromSyspath('SYSPATH'),
        throwsA(isA<UdevSyspathException>()
            .having((e) => e.syspath, 'syspath', 'SYSPATH')),
      );

      expect(
        () => UdevDevice.fromDevnum('S', 123),
        throwsA(isA<UdevDevnumException>()
            .having((e) => e.type, 'type', 'S')
            .having((e) => e.devnum, 'devnum', 123)),
      );

      expect(
        () => UdevDevice.fromSubsystemSysname('SUBSYSTEM', 'SYSNAME'),
        throwsA(isA<UdevSubsystemSysnameException>()
            .having((e) => e.subsystem, 'subsystem', 'SUBSYSTEM')
            .having((e) => e.sysname, 'sysname', 'SYSNAME')),
      );

      expect(
        () => UdevDevice.fromDeviceId('SUBSYSTEM:SYSNAME'),
        throwsA(isA<UdevDeviceIdException>()
            .having((e) => e.id, 'id', 'SUBSYSTEM:SYSNAME')),
      );
    });
  });
}
