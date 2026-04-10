import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/system_data.dart';
import '../models/meter_data.dart';
import '../services/api_service.dart' show ConnectionState;
import 'connection_provider.dart';

class LiveData {
  final SystemData? system;
  final MeterData? meter;

  const LiveData({this.system, this.meter});

  LiveData copyWith({SystemData? system, MeterData? meter}) {
    return LiveData(
      system: system ?? this.system,
      meter: meter ?? this.meter,
    );
  }
}

class LiveDataNotifier extends StateNotifier<LiveData> {
  final Ref _ref;
  Timer? _timer;

  LiveDataNotifier(this._ref) : super(const LiveData());

  void startPolling(String serial) {
    _timer?.cancel();
    _poll(serial);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _poll(serial));
  }

  Future<void> _poll(String serial) async {
    final api = _ref.read(apiServiceProvider);
    final results = await Future.wait([
      api.getSystemData(serial),
      api.getMeterData(serial),
    ]);

    final systemData = results[0] as SystemData?;
    final meterData = results[1] as MeterData?;

    _ref.read(connectionStateProvider.notifier).state = api.connectionState;

    state = LiveData(
      system: systemData ?? state.system,
      meter: meterData ?? state.meter,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final liveDataProvider = StateNotifierProvider<LiveDataNotifier, LiveData>((ref) {
  return LiveDataNotifier(ref);
});
