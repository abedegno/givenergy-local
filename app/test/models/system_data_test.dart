import 'package:flutter_test/flutter_test.dart';
import 'package:givlocal_app/models/system_data.dart';

void main() {
  group('SystemData', () {
    test('parses full JSON correctly', () {
      final json = {
        'time': '2024-01-01T12:00:00Z',
        'status': 'normal',
        'solar': {
          'power': 3500,
          'arrays': [
            {
              'array': 1,
              'voltage': 380.5,
              'current': 4.6,
              'power': 1750,
            },
            {
              'array': 2,
              'voltage': 375.2,
              'current': 4.7,
              'power': 1750,
            },
          ],
        },
        'grid': {
          'voltage': 240.1,
          'current': 5.2,
          'power': -1200,
          'frequency': 50.0,
        },
        'battery': {
          'percent': 85,
          'power': 500,
          'temperature': 28.5,
        },
        'inverter': {
          'temperature': 35.0,
          'power': 2800,
          'output_voltage': 239.8,
          'output_frequency': 50.0,
          'eps_power': 0,
        },
        'consumption': 2300,
      };

      final data = SystemData.fromJson(json);

      expect(data.status, equals('normal'));
      expect(data.solar.power, equals(3500));
      expect(data.solar.arrays.length, equals(2));
      expect(data.grid.power, equals(-1200));
      expect(data.battery.percent, equals(85));
      expect(data.consumption, equals(2300));
    });

    test('handles missing fields with defaults', () {
      final data = SystemData.fromJson({});

      expect(data.time, equals(''));
      expect(data.status, equals(''));
      expect(data.solar.power, equals(0));
      expect(data.solar.arrays, isEmpty);
      expect(data.grid.power, equals(0));
      expect(data.grid.voltage, equals(0.0));
      expect(data.battery.percent, equals(0));
      expect(data.battery.temperature, equals(0.0));
      expect(data.inverter.outputVoltage, equals(0.0));
      expect(data.inverter.epsPower, equals(0));
      expect(data.consumption, equals(0));
    });
  });
}
