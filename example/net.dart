import 'package:udev/udev.dart';

import 'shared.dart';

void main() {
  final context = UdevContext();

  final syspaths = context.scanDevices(subsystems: ['net']);
  final devices = syspaths
      .map((syspath) => UdevDevice.fromSyspath(syspath, context: context))
      .where((device) => device.devtype != null);

  printTable({
    'SYSNAME': devices.map((d) => d.sysname),
    'DEVTYPE': devices.map((d) => d.devtype!),
    'VENDOR': devices.map((d) => d.vendor),
    'MODEL': devices.map((d) => d.model),
  });
}
