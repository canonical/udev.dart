import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart' as ffi;
import 'package:stdlibc/stdlibc.dart';

import 'context.dart';
import 'device.dart';
import 'exception.dart';
import 'extensions.dart';
import 'libudev.dart';

/// Monitors kernel sys devices.
extension UdevMonitor on UdevContext {
  /// Returns a stream of kernel sys device changes.
  Stream<UdevDevice> monitorDevices({
    String name = 'udev',
    int? bufferSize,
    List<String> subsystems = const [],
    List<String> tags = const [],
  }) async* {
    ffi.Pointer<udev_monitor_t>? monitor;
    final stop = pipe();

    ffi.using((arena) {
      final cname = name.toCString(allocator: arena);
      monitor = udev.monitor_new_from_netlink(toPointer(), cname);

      for (final subsystem in subsystems) {
        final csubsystem = subsystem.toCString(allocator: arena);
        udev.monitor_filter_add_match_subsystem_devtype(
            monitor!, csubsystem, ffi.nullptr);
      }

      for (final tag in tags) {
        final ctag = tag.toCString(allocator: arena);
        udev.monitor_filter_add_match_tag(monitor!, ctag);
      }
    });

    if (bufferSize != null) {
      final res = udev.monitor_set_receive_buffer_size(monitor!, bufferSize);
      if (res < 0) {
        udev.monitor_unref(monitor!);
        throw UdevErrnoException(-res);
      }
    }

    final res = udev.monitor_enable_receiving(monitor!);
    if (res < 0) {
      udev.monitor_unref(monitor!);
      throw UdevErrnoException(-res);
    }

    try {
      final receivePort = ReceivePort();

      await Isolate.spawn(
        _poll,
        _UdevPollArgs(
          fd: udev.monitor_get_fd(monitor!),
          stop: stop.first,
          sendPort: receivePort.sendPort,
        ),
      );

      yield* receivePort
          .map((dynamic event) => monitor != null
              ? udev.monitor_receive_device(monitor!)
              : ffi.nullptr)
          .map(UdevDevice.fromPointer)
          .where((device) => device != null)
          .cast();
    } finally {
      write(stop.last, [0]);
      close(stop.last);
      if (monitor != null) {
        udev.monitor_unref(monitor!);
        monitor = null;
      }
    }
  }

  static Future<void> _poll(_UdevPollArgs args) {
    final fds = [Pollfd(args.stop, POLLIN), Pollfd(args.fd, POLLIN)];
    return Future.doWhile(() {
      for (final p in poll(fds)) {
        if (p.fd == args.stop) {
          close(p.fd);
          return false;
        } else if (p.fd == args.fd) {
          if (p.events & POLLIN != 0) {
            args.sendPort.send(p.fd);
          } else if (p.events & POLLHUP != 0) {
            return false;
          }
        }
      }
      return true;
    });
  }
}

class _UdevPollArgs {
  _UdevPollArgs({
    required this.fd,
    required this.stop,
    required this.sendPort,
  });
  final int fd;
  final int stop;
  final SendPort sendPort;
}
