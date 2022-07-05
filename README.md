# udev.dart

[![CI](https://github.com/jpnurmi/udev.dart/workflows/Tests/badge.svg)](https://github.com/jpnurmi/geoclue.dart/actions/workflows/tests.yaml)
[![codecov](https://codecov.io/gh/jpnurmi/udev.dart/branch/main/graph/badge.svg?token=YdlI3jrz92)](https://codecov.io/gh/jpnurmi/udev.dart)

[udev](https://www.freedesktop.org/software/systemd/man/libudev.html) — API for enumerating and introspecting local devices

## Querying devices

```dart
void main() {
  print(UdevDevice.fromSyspath('/sys/devices/<...>'));
  print(UdevDevice.fromDevnum('b', 66304));
  print(UdevDevice.fromSubsystemSysname('net', 'eth0'));
  print(UdevDevice.fromDeviceId('c128:1'));
}
```

## Enumerating devices

```dart
void main() {
  final context = UdevContext();

  final syspaths = context.enumerateDevices(subsystems: ['usb']);
  for (final syspath in syspaths) {
    final device = UdevDevice.fromSyspath(syspath, context: context);
    print(device);
  }
}
```

## Monitoring devices

```dart
final stream = UdevMonitor.fromNetlink(subsystems: ['usb'])
stream.timeout(const Duration(seconds: 60), onTimeout: (sink) => sink.close())
    .listen(print);
```

## Contributing to udev.dart

We welcome contributions! See the [contribution guide](CONTRIBUTING.md) for more details.
