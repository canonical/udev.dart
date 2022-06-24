import 'dart:ffi';

import 'package:meta/meta.dart';

import 'libudev.g.dart';
export 'libudev.g.dart';

final dylib = DynamicLibrary.open('libudev.so.1');

Libudev? _udev;

Libudev get udev => _udev ??= Libudev(dylib);

@visibleForTesting
void overrideLibudevForTesting(Libudev? udev) => _udev = udev;
