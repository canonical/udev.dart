import 'package:udev/udev.dart';

import 'shared.dart';

void main() {
  final context = UdevContext();

  print('Monitoring USB devices for 60s...');

  context
      .monitorDevices('udev', subsystems: ['usb'])
      .timeout(const Duration(seconds: 60), onTimeout: (sink) => sink.close())
      .listen((device) => print(
          '${device.action}: ${device.vendor} ${device.model} (${device.syspath})'));
}
