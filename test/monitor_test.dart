import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:stdlibc/stdlibc.dart';
import 'package:test/test.dart';
import 'package:udev/src/context.dart';
import 'package:udev/src/device.dart';
import 'package:udev/src/libudev.dart';
import 'package:udev/src/monitor.dart';

import 'mock_libudev.dart';
import 'test_data.dart';
import 'test_utils.dart';

void main() {
  test('monitor', () async {
    await ffi.using((arena) async {
      final ctx = ffi.Pointer<udev_t>.fromAddress(0xc);
      final dev = ffi.Pointer<udev_device_t>.fromAddress(0xd);
      final monitor = ffi.Pointer<udev_monitor_t>.fromAddress(0xe);

      final udev = createMockLibudev(
        allocator: arena,
        context: ctx,
        devices: {dev: wlp0s20f3},
      );
      overrideLibudevForTesting(udev);

      final fds = pipe();

      when(() =>
              udev.monitor_new_from_netlink(ctx, any(that: isCString('udev'))))
          .thenReturn(monitor);
      when(() => udev.monitor_unref(monitor)).thenReturn(ffi.nullptr);
      when(() => udev.monitor_set_receive_buffer_size(monitor, 123))
          .thenReturn(0);
      when(() => udev.monitor_filter_add_match_subsystem_devtype(
          monitor, any(that: isCString('sub')), ffi.nullptr)).thenReturn(0);
      when(() => udev.monitor_filter_add_match_tag(
          monitor, any(that: isCString('tag')))).thenReturn(0);
      when(() => udev.monitor_enable_receiving(monitor)).thenReturn(0);
      when(() => udev.monitor_get_fd(monitor)).thenReturn(fds.first);
      when(() => udev.monitor_receive_device(monitor)).thenAnswer((_) => dev);

      final context = UdevContext.fromPointer(ctx);
      final stream = context.monitorDevices('udev',
          bufferSize: 123, subsystems: ['sub'], tags: ['tag']);

      write(fds.last, [1]);

      await expectLater(
          stream,
          emits(isA<UdevDevice>()
              .having((d) => d.syspath, 'syspath', wlp0s20f3.syspath)));

      close(fds.first);
      close(fds.last);

      verify(() => udev.monitor_set_receive_buffer_size(monitor, 123))
          .called(1);
      verify(() => udev.monitor_filter_add_match_subsystem_devtype(
          monitor, any(), ffi.nullptr)).called(1);
      verify(() => udev.monitor_filter_add_match_tag(monitor, any())).called(1);
      verify(() => udev.monitor_enable_receiving(monitor)).called(1);
      verify(() => udev.monitor_get_fd(monitor)).called(1);
    });
  });
}
