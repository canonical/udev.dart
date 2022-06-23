import 'dart:ffi' as ffi;

import 'bindings.g.dart';
import 'dylib.dart';
import 'extensions.dart';

extension UdevListEntry on ffi.Pointer<udev_list_entry> {
  Map<String, String?> toDartMap() {
    final map = <String, String?>{};
    var next = this;
    while (next != ffi.nullptr) {
      final name = dylib.udev_list_entry_get_name(next).toDartString()!;
      map[name] = dylib.udev_list_entry_get_value(next).toDartString();
      next = dylib.udev_list_entry_get_next(next);
    }
    return map;
  }

  List<String> toDartList() {
    final list = <String>[];
    var next = this;
    while (next != ffi.nullptr) {
      list.add(dylib.udev_list_entry_get_name(next).toDartString()!);
      next = dylib.udev_list_entry_get_next(next);
    }
    return list;
  }
}
