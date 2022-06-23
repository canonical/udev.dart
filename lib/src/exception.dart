import 'package:meta/meta.dart';

@immutable
class UdevException implements Exception {
  const UdevException(this.message);

  final String message;

  @override
  String toString() => message;

  @override
  int get hashCode => message.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    return other is UdevException && other.message == message;
  }
}

@immutable
class UdevDeviceException extends UdevException {
  const UdevDeviceException(super.message);
}

@immutable
class UdevSyspathException extends UdevDeviceException {
  const UdevSyspathException(this.syspath)
      : super('Device not found (syspath: $syspath)');

  final String syspath;
}

@immutable
class UdevDevnumException extends UdevDeviceException {
  const UdevDevnumException(this.type, this.devnum)
      : super('Device not found (type: $type, devnum: $devnum)');

  final String type;
  final int devnum;
}

@immutable
class UdevSubsystemSysnameException extends UdevDeviceException {
  const UdevSubsystemSysnameException(this.subsystem, this.sysname)
      : super('Device not found (subsystem: $subsystem, sysname: $sysname)');

  final String subsystem;
  final String sysname;
}

@immutable
class UdevDeviceIdException extends UdevDeviceException {
  const UdevDeviceIdException(this.id) : super('Device not found (id: $id)');

  final String id;
}

@immutable
class UdevEnvironmentException extends UdevDeviceException {
  const UdevEnvironmentException(this.environment)
      : super('Device not found (environment: $environment)');

  final Map<String, String> environment;
}
