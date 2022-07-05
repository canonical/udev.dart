import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:udev/src/context.dart';
import 'package:udev/src/enumerate.dart';
import 'package:udev/src/libudev.dart' hide udev;

import 'mock_libudev.dart';
import 'test_data.dart';
import 'test_utils.dart';

void main() {
  test('enumerate', () {
    ffi.using((arena) {
      final ctx = ffi.Pointer<udev_t>.fromAddress(0xc);
      final ptr = ffi.Pointer<udev_enumerate_t>.fromAddress(0xe);

      final udev = createMockLibudev(
        allocator: arena,
        context: ctx,
        enumerate: ptr,
        scan: [
          wlp0s20f3.syspath,
          nvme0n1.syspath,
          card1.syspath,
        ],
      );
      overrideLibudevForTesting(udev);

      when(() => udev.enumerate_add_match_subsystem(
          ptr, any(that: isCString('net')))).thenReturn(0);
      when(() => udev.enumerate_add_match_sysname(
          ptr, any(that: isCString('nvme0n1')))).thenReturn(0);
      when(() => udev.enumerate_add_match_tag(
          ptr, any(that: isCString(':systemd:')))).thenReturn(0);
      when(() => udev.enumerate_add_match_property(
              ptr, any(that: isCString('foo')), any(that: isCString('bar'))))
          .thenReturn(0);
      when(() => udev.enumerate_add_match_sysattr(
              ptr, any(that: isCString('baz')), any(that: isCString('qux'))))
          .thenReturn(0);

      final context = UdevContext.fromPointer(ctx);

      expect(
        context.enumerateDevices(subsystems: ['net']),
        equals([wlp0s20f3.syspath, nvme0n1.syspath, card1.syspath]),
      );
      verify(() => udev.enumerate_add_match_subsystem(ptr, any())).called(1);

      expect(
        context.enumerateDevices(sysnames: ['nvme0n1']),
        equals([wlp0s20f3.syspath, nvme0n1.syspath, card1.syspath]),
      );
      verify(() => udev.enumerate_add_match_sysname(ptr, any())).called(1);

      expect(
        context.enumerateDevices(tags: [':systemd:']),
        equals([wlp0s20f3.syspath, nvme0n1.syspath, card1.syspath]),
      );
      verify(() => udev.enumerate_add_match_tag(ptr, any())).called(1);

      expect(
        context.enumerateDevices(properties: {'foo': 'bar'}),
        equals([wlp0s20f3.syspath, nvme0n1.syspath, card1.syspath]),
      );
      verify(() => udev.enumerate_add_match_property(ptr, any(), any()))
          .called(1);

      expect(
        context.enumerateDevices(sysattrs: {'baz': 'qux'}),
        equals([wlp0s20f3.syspath, nvme0n1.syspath, card1.syspath]),
      );
      verify(() => udev.enumerate_add_match_sysattr(ptr, any(), any()))
          .called(1);
    });
  });
}
