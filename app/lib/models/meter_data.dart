class EnergyPeriod {
  final double solar;
  final double gridImport;
  final double gridExport;
  final double batteryCharge;
  final double batteryDischarge;
  final double consumption;

  const EnergyPeriod({
    required this.solar,
    required this.gridImport,
    required this.gridExport,
    required this.batteryCharge,
    required this.batteryDischarge,
    required this.consumption,
  });

  factory EnergyPeriod.fromJson(Map<String, dynamic> json) {
    final grid = json['grid'] as Map<String, dynamic>? ?? {};
    final battery = json['battery'] as Map<String, dynamic>? ?? {};
    return EnergyPeriod(
      solar: (json['solar'] as num?)?.toDouble() ?? 0.0,
      gridImport: (grid['import'] as num?)?.toDouble() ?? 0.0,
      gridExport: (grid['export'] as num?)?.toDouble() ?? 0.0,
      batteryCharge: (battery['charge'] as num?)?.toDouble() ?? 0.0,
      batteryDischarge: (battery['discharge'] as num?)?.toDouble() ?? 0.0,
      consumption: (json['consumption'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MeterData {
  final String time;
  final EnergyPeriod today;
  final EnergyPeriod total;

  const MeterData({
    required this.time,
    required this.today,
    required this.total,
  });

  factory MeterData.fromJson(Map<String, dynamic> json) {
    return MeterData(
      time: (json['time'] as String?) ?? '',
      today: json['today'] != null
          ? EnergyPeriod.fromJson(json['today'] as Map<String, dynamic>)
          : EnergyPeriod.fromJson({}),
      total: json['total'] != null
          ? EnergyPeriod.fromJson(json['total'] as Map<String, dynamic>)
          : EnergyPeriod.fromJson({}),
    );
  }
}
