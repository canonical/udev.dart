import 'dart:math';

import 'package:collection/collection.dart';
import 'package:udev/udev.dart';

void printTable(Map<String, Iterable<String>> table) {
  final columns = [
    for (final entry in table.entries)
      [entry.key, ...entry.value].map((e) => e.length).reduce(max),
  ];

  void printLine(Iterable<String> items) {
    print(items.mapIndexed((i, s) => s.padRight(columns[i] + 1)).join(' '));
  }

  printLine(table.keys);
  for (var i = 0; i < table.length; ++i) {
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
