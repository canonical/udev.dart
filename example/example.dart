import 'dart:math';

import 'package:collection/collection.dart';
import 'package:udev/udev.dart';

void main() {
  final context = UdevContext();

  print('Currently attached USB devices:\n');

  final syspaths = context.enumerateDevices(
      subsystems: ['usb'], properties: {'DEVTYPE': 'usb_device'});
  final devices = syspaths
      .map((syspath) => UdevDevice.fromSyspath(syspath, context: context))
      .where((device) => device.devtype != null);

  printTable({
    'SYSNAME': devices.map((d) => d.sysname),
    'DEVTYPE': devices.map((d) => d.devtype!),
    'VENDOR': devices.map((d) => d.vendor),
    'MODEL': devices.map((d) => d.model),
  });

  print('\nMonitoring USB devices for 60s...\n');

  context
      .monitorDevices(subsystems: ['usb'])
      .timeout(const Duration(seconds: 60), onTimeout: (sink) => sink.close())
      .listen((device) => print(
          '- ${device.action} ${device.sysname}: ${device.vendor} ${device.model}'));
}

void printTable(Map<String, Iterable<String>> table) {
  final columns = [
    for (final entry in table.entries)
      [entry.key, ...entry.value].map((e) => e.length).reduce(max),
  ];

  void printLine(Iterable<String> items) {
    print(items.mapIndexed((i, s) => s.padRight(columns[i] + 1)).join(' '));
  }

  printLine(table.keys);
  for (var i = 0; i < table.values.first.length; ++i) {
    printLine(table.values.map((j) => j.elementAt(i)));
  }
}

extension DeviceX on UdevDevice {
  String get vendor =>
      properties.get('ID_VENDOR_FROM_DATABASE', 'ID_VENDOR') ?? '-';
  String get model =>
      properties.get('ID_MODEL_FROM_DATABASE', 'ID_MODEL') ?? '-';
}

extension MapX on Map<String, String?> {
  String? get(String key, [String? fallback]) => this[key] ?? this[fallback];
}
