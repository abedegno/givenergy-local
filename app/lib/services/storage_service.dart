import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  late SharedPreferences _prefs;

  static const _keyLocalUrl = 'local_url';
  static const _keyRemoteUrl = 'remote_url';
  static const _keyApiToken = 'api_token';
  static const _keyInverterSerial = 'inverter_serial';
  static const _keyRemoteAccessType = 'remote_access_type';
  static const _keyThemeMode = 'theme_mode';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get localUrl => _prefs.getString(_keyLocalUrl) ?? '';
  set localUrl(String value) => _prefs.setString(_keyLocalUrl, value);

  String get remoteUrl => _prefs.getString(_keyRemoteUrl) ?? '';
  set remoteUrl(String value) => _prefs.setString(_keyRemoteUrl, value);

  String get apiToken => _prefs.getString(_keyApiToken) ?? '';
  set apiToken(String value) => _prefs.setString(_keyApiToken, value);

  String get inverterSerial => _prefs.getString(_keyInverterSerial) ?? '';
  set inverterSerial(String value) =>
      _prefs.setString(_keyInverterSerial, value);

  String get remoteAccessType => _prefs.getString(_keyRemoteAccessType) ?? '';
  set remoteAccessType(String value) =>
      _prefs.setString(_keyRemoteAccessType, value);

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  set themeMode(String value) => _prefs.setString(_keyThemeMode, value);

  bool get isConfigured => localUrl.isNotEmpty && apiToken.isNotEmpty;
}
