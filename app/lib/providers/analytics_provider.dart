import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'connection_provider.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Time range in hours (0 = all day)
final timeRangeProvider = StateProvider<int>((ref) => 0);

final dataPointsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final api = ref.read(apiServiceProvider);
  final storage = ref.read(storageServiceProvider);
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  return api.getDataPoints(storage.inverterSerial, dateStr);
});

/// Filtered data points based on selected time range
final filteredDataPointsProvider = Provider.autoDispose<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final dataAsync = ref.watch(dataPointsProvider);
  final rangeHours = ref.watch(timeRangeProvider);

  return dataAsync.whenData((points) {
    if (rangeHours == 0 || points.isEmpty) return points;

    // Find the latest data point time
    DateTime? latest;
    for (final dp in points) {
      final timeStr = dp['time'] as String? ?? '';
      if (timeStr.isEmpty) continue;
      try {
        final dt = DateTime.parse(timeStr);
        if (latest == null || dt.isAfter(latest)) latest = dt;
      } catch (_) {}
    }
    if (latest == null) return points;

    final cutoff = latest.subtract(Duration(hours: rangeHours));
    return points.where((dp) {
      final timeStr = dp['time'] as String? ?? '';
      if (timeStr.isEmpty) return false;
      try {
        return DateTime.parse(timeStr).isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();
  });
});
