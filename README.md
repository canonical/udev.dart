# udev.dart

[![CI](https://github.com/jpnurmi/udev.dart/workflows/Tests/badge.svg)](https://github.com/jpnurmi/geoclue.dart/actions/workflows/tests.yaml)
[![codecov](https://codecov.io/gh/jpnurmi/udev.dart/branch/main/graph/badge.svg?token=YdlI3jrz92)](https://codecov.io/gh/jpnurmi/udev.dart)

[libudev](https://www.freedesktop.org/software/systemd/man/libudev.html) — API for enumerating and introspecting local devices

## Querying devices

```dart
void main() {
  print(UdevDevices.fromSyspath('/sys/devices/<...>'));
  print(UdevDevices.fromDevnum('b', 66304));
  print(UdevDevices.fromSubsystemSysname('net', 'eth0'));
  print(UdevDevices.fromDeviceId('c128:1'));
}
```

## Scanning devices

```dart
void main() {
  final context = UdevContext();

  final syspaths = context.scanDevices(subsystems: ['net']);
  for (final syspath in syspaths) {
    final device = UdevDevices.fromSyspath(syspath, context: context);
    print(device);
  }
}
```

## Monitoring devices

```dart
final stream = UdevMonitor.fromNetlink('udev', subsystems: ['usb'])
stream.timeout(const Duration(seconds: 60), onTimeout: (sink) => sink.close())
    .listen(print);
```

## Contributing to udev.dart

We welcome contributions! See the [contribution guide](CONTRIBUTING.md) for more details.
