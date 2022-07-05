import 'package:mocktail/mocktail.dart';
import 'package:udev/src/device.dart';

class FakeUdevDevice extends Fake implements UdevDevice {
  FakeUdevDevice({
    required this.devpath,
    required this.subsystem,
    required this.devtype,
    required this.syspath,
    required this.sysname,
    required this.sysnum,
    required this.devnode,
    required this.isInitialized,
    required this.driver,
    required this.devnum,
    required this.action,
    required this.seqnum,
    required this.timeSinceInitialized,
    required this.devlinks,
    required this.properties,
    required this.tags,
    required this.sysattrs,
    required this.parent,
  });

  @override
  final String devpath;
  @override
  final String? subsystem;
  @override
  final String? devtype;
  @override
  final String syspath;
  @override
  final String sysname;
  @override
  final String? sysnum;
  @override
  final String? devnode;
  @override
  final bool isInitialized;
  @override
  final String? driver;
  @override
  final int devnum;
  @override
  final String? action;
  @override
  final int seqnum;
  @override
  final Duration timeSinceInitialized;
  @override
  final List<String> devlinks;
  @override
  final Map<String, String?> properties;
  @override
  final List<String> tags;
  @override
  final Map<String, String?> sysattrs;
  @override
  final UdevDevice? parent;
}
