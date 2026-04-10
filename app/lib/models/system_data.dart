class SolarArray {
  final int array;
  final double voltage;
  final double current;
  final int power;

  const SolarArray({
    required this.array,
    required this.voltage,
    required this.current,
    required this.power,
  });

  factory SolarArray.fromJson(Map<String, dynamic> json) {
    return SolarArray(
      array: (json['array'] as num?)?.toInt() ?? 0,
      voltage: (json['voltage'] as num?)?.toDouble() ?? 0.0,
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      power: (json['power'] as num?)?.toInt() ?? 0,
    );
  }
}

class SolarData {
  final int power;
  final List<SolarArray> arrays;

  const SolarData({
    required this.power,
    required this.arrays,
  });

  factory SolarData.fromJson(Map<String, dynamic> json) {
    final rawArrays = json['arrays'] as List<dynamic>? ?? [];
    return SolarData(
      power: (json['power'] as num?)?.toInt() ?? 0,
      arrays: rawArrays
          .map((e) => SolarArray.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GridData {
  final double voltage;
  final double current;
  final int power;
  final double frequency;

  const GridData({
    required this.voltage,
    required this.current,
    required this.power,
    required this.frequency,
  });

  factory GridData.fromJson(Map<String, dynamic> json) {
    return GridData(
      voltage: (json['voltage'] as num?)?.toDouble() ?? 0.0,
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      power: (json['power'] as num?)?.toInt() ?? 0,
      frequency: (json['frequency'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BatteryData {
  final int percent;
  final int power;
  final double temperature;

  const BatteryData({
    required this.percent,
    required this.power,
    required this.temperature,
  });

  factory BatteryData.fromJson(Map<String, dynamic> json) {
    return BatteryData(
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      power: (json['power'] as num?)?.toInt() ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InverterData {
  final double temperature;
  final int power;
  final double outputVoltage;
  final double outputFrequency;
  final int epsPower;

  const InverterData({
    required this.temperature,
    required this.power,
    required this.outputVoltage,
    required this.outputFrequency,
    required this.epsPower,
  });

  factory InverterData.fromJson(Map<String, dynamic> json) {
    return InverterData(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      power: (json['power'] as num?)?.toInt() ?? 0,
      outputVoltage: (json['output_voltage'] as num?)?.toDouble() ?? 0.0,
      outputFrequency: (json['output_frequency'] as num?)?.toDouble() ?? 0.0,
      epsPower: (json['eps_power'] as num?)?.toInt() ?? 0,
    );
  }
}

class SystemData {
  final String time;
  final String status;
  final SolarData solar;
  final GridData grid;
  final BatteryData battery;
  final InverterData inverter;
  final int consumption;

  const SystemData({
    required this.time,
    required this.status,
    required this.solar,
    required this.grid,
    required this.battery,
    required this.inverter,
    required this.consumption,
  });

  factory SystemData.fromJson(Map<String, dynamic> json) {
    return SystemData(
      time: (json['time'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      solar: json['solar'] != null
          ? SolarData.fromJson(json['solar'] as Map<String, dynamic>)
          : SolarData.fromJson({}),
      grid: json['grid'] != null
          ? GridData.fromJson(json['grid'] as Map<String, dynamic>)
          : GridData.fromJson({}),
      battery: json['battery'] != null
          ? BatteryData.fromJson(json['battery'] as Map<String, dynamic>)
          : BatteryData.fromJson({}),
      inverter: json['inverter'] != null
          ? InverterData.fromJson(json['inverter'] as Map<String, dynamic>)
          : InverterData.fromJson({}),
      consumption: (json['consumption'] as num?)?.toInt() ?? 0,
    );
  }
}
