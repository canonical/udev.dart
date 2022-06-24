import 'dart:ffi' as ffi;

import 'extensions.dart';
import 'libudev.dart';

extension UdevListEntry on ffi.Pointer<udev_list_entry_t> {
  Map<String, String?> toDartMap() {
    final map = <String, String?>{};
    var next = this;
    while (next != ffi.nullptr) {
      final name = udev.list_entry_get_name(next).toDartString()!;
      map[name] = udev.list_entry_get_value(next).toDartString();
      next = udev.list_entry_get_next(next);
    }
    return map;
  }

  List<String> toDartList() {
    final list = <String>[];
    var next = this;
    while (next != ffi.nullptr) {
      list.add(udev.list_entry_get_name(next).toDartString()!);
      next = udev.list_entry_get_next(next);
    }
    return list;
  }
}
