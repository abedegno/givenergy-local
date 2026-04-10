class InverterSetting {
  final int id;
  final String name;
  final String validation;
  final dynamic value;

  const InverterSetting({
    required this.id,
    required this.name,
    required this.validation,
    this.value,
  });

  factory InverterSetting.fromJson(Map<String, dynamic> json) {
    return InverterSetting(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      validation: (json['validation'] as String?) ?? '',
      value: json['value'],
    );
  }
}
