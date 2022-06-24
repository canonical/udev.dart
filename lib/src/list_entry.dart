import 'dart:collection';
import 'dart:ffi' as ffi;

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart' as ffi;

import 'extensions.dart';
import 'finalizer.dart';
import 'libudev.dart';

class UdevIterable with IterableMixin<String> {
  const UdevIterable(this._ptr);

  final ffi.Pointer<udev_list_entry_t> _ptr;

  @override
  Iterator<String> get iterator => UdevIterator(_ptr);
}

class UdevIterator extends Iterator<String> {
  UdevIterator(this._ptr);

  final ffi.Pointer<udev_list_entry_t> _ptr;
  ffi.Pointer<udev_list_entry_t>? _it;

  @override
  String get current => udev.list_entry_get_name(_it!).toDartString()!;

  @override
  bool moveNext() {
    if (_it == null) {
      _it = _ptr;
    } else if (_it != ffi.nullptr) {
      _it = udev.list_entry_get_next(_it!);
    }
    return _it != ffi.nullptr;
  }
}

class UdevPropertyMap
    with MapMixin<String, String?>, UnmodifiableMapMixin<String, String?>
    implements ffi.Finalizable {
  UdevPropertyMap(this._ptr) {
    finalizer.attach(this, udev.device_ref(_ptr));
  }

  final ffi.Pointer<udev_device_t> _ptr;

  @override
  String? operator [](Object? key) {
    if (key is! String) {
      return null;
    }
    return ffi.using((arena) {
      final ckey = key.toCString(allocator: arena);
      final value = udev.device_get_property_value(_ptr, ckey);
      return value.toDartString();
    });
  }

  @override
  Iterable<String> get keys sync* {
    var entry = udev.device_get_properties_list_entry(_ptr);
    while (entry != ffi.nullptr) {
      yield udev.list_entry_get_name(entry).toDartString()!;
      entry = udev.list_entry_get_next(entry);
    }
  }
}

class UdevSysattrMap with MapMixin<String, String?> implements ffi.Finalizable {
  UdevSysattrMap(this._ptr) {
    finalizer.attach(this, udev.device_ref(_ptr));
  }

  final ffi.Pointer<udev_device_t> _ptr;

  @override
  String? operator [](Object? key) {
    if (key is! String) {
      return null;
    }
    return ffi.using((arena) {
      final ckey = key.toCString(allocator: arena);
      final value = udev.device_get_sysattr_value(_ptr, ckey);
      return value.toDartString();
    });
  }

  @override
  Iterable<String> get keys sync* {
    var entry = udev.device_get_sysattr_list_entry(_ptr);
    while (entry != ffi.nullptr) {
      yield udev.list_entry_get_name(entry).toDartString()!;
      entry = udev.list_entry_get_next(entry);
    }
  }

  @override
  void operator []=(String key, String? value) {
    ffi.using((arena) {
      final ckey = key.toCString(allocator: arena);
      final cvalue = value?.toCString(allocator: arena) ?? ffi.nullptr;
      udev.device_set_sysattr_value(_ptr, ckey, cvalue);
    });
  }

  @override
  void clear() {
    throw UnsupportedError('Cannot clear sysattrs');
  }

  @override
  String? remove(Object? key) {
    throw UnsupportedError('Cannot remove sysattrs');
  }
}
