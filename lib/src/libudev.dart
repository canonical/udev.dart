import 'dart:ffi';

import 'package:meta/meta.dart';

import 'libudev.g.dart';
export 'libudev.g.dart';

Libudev? _udev;

Libudev get udev => _udev ??= Libudev(DynamicLibrary.open('libudev.so.1'));

@visibleForTesting
void overrideLibudevForTesting(Libudev? udev) => _udev = udev;
