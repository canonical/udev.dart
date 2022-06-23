import 'dart:ffi';

import 'package:meta/meta.dart';

import 'bindings.g.dart';

Libudev? _dylib;

Libudev get dylib => _dylib ??= Libudev(DynamicLibrary.open('libudev.so.1'));

@visibleForTesting
void overrideLibudevForTesting(Libudev? dylib) => _dylib = dylib;
