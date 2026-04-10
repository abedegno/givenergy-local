import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart' show ConnectionState;
import '../services/api_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Override in main');
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.read(storageServiceProvider));
});

final connectionStateProvider = StateProvider<ConnectionState>((ref) {
  return ConnectionState.disconnected;
});
