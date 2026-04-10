class DeviceInverter {
  final String serial;
  final String status;
  final String? firmwareVersion;
  final String? model;

  const DeviceInverter({
    required this.serial,
    required this.status,
    this.firmwareVersion,
    this.model,
  });

  factory DeviceInverter.fromJson(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>? ?? {};
    return DeviceInverter(
      serial: (json['serial'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      firmwareVersion: info['firmware_version'] as String?,
      model: info['model'] as String?,
    );
  }
}

class CommunicationDevice {
  final String serialNumber;
  final String type;
  final DeviceInverter inverter;

  const CommunicationDevice({
    required this.serialNumber,
    required this.type,
    required this.inverter,
  });

  factory CommunicationDevice.fromJson(Map<String, dynamic> json) {
    return CommunicationDevice(
      serialNumber: (json['serial_number'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      inverter: json['inverter'] != null
          ? DeviceInverter.fromJson(json['inverter'] as Map<String, dynamic>)
          : DeviceInverter.fromJson({}),
    );
  }
}
