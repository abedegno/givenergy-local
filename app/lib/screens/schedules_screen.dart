import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connection_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../widgets/schedule_slot_card.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  // Independent toggles - not mutually exclusive
  bool _ecoMode = true;

  // Battery reserve
  double _batteryReserve = 4;

  // AC Charge
  bool _chargeEnabled = false;
  String _chargeStart = '00:30';
  String _chargeEnd = '05:00';
  int _chargeTargetSoc = 80;

  // DC Discharge
  bool _dischargeEnabled = false;
  String _dischargeStart = '16:00';
  String _dischargeEnd = '19:00';
  int _dischargeTargetSoc = 4;

  bool _loading = true;
  String? _serial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);
    final serial = storage.inverterSerial;
    if (serial.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    _serial = serial;

    final api = ref.read(apiServiceProvider);

    final results = await Future.wait([
      api.readSetting(serial, SettingIds.ecoMode),
      api.readSetting(serial, SettingIds.batteryReserve),
      api.readSetting(serial, SettingIds.enableCharge),
      api.readSetting(serial, SettingIds.enableDischarge),
      api.readSetting(serial, SettingIds.chargeSlot1Start),
      api.readSetting(serial, SettingIds.chargeSlot1End),
      api.readSetting(serial, SettingIds.chargeSlot1Soc),
      api.readSetting(serial, SettingIds.dischargeSlot1Start),
      api.readSetting(serial, SettingIds.dischargeSlot1End),
      api.readSetting(serial, SettingIds.dischargeSlot1Soc),
    ]);

    if (!mounted) return;

    setState(() {
      _ecoMode = _parseBool(results[0]?.value);

      final reserve = results[1]?.value;
      if (reserve != null) {
        _batteryReserve = (reserve is num)
            ? reserve.toDouble().clamp(4.0, 100.0)
            : double.tryParse(reserve.toString())?.clamp(4.0, 100.0) ?? 4.0;
      }

      _chargeEnabled = _parseBool(results[2]?.value);
      _dischargeEnabled = _parseBool(results[3]?.value);

      _chargeStart = _parseString(results[4]?.value, _chargeStart);
      _chargeEnd = _parseString(results[5]?.value, _chargeEnd);
      _chargeTargetSoc = _parseInt(results[6]?.value, _chargeTargetSoc);

      _dischargeStart = _parseString(results[7]?.value, _dischargeStart);
      _dischargeEnd = _parseString(results[8]?.value, _dischargeEnd);
      _dischargeTargetSoc = _parseInt(results[9]?.value, _dischargeTargetSoc);

      _loading = false;
    });
  }

  bool _parseBool(dynamic val) =>
      val == true || val == 1 || val == 'true';

  String _parseString(dynamic val, String fallback) {
    final s = val?.toString();
    return (s != null && s.isNotEmpty) ? s : fallback;
  }

  int _parseInt(dynamic val, int fallback) {
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  Future<void> _writeSetting(int id, dynamic value) async {
    final serial = _serial;
    if (serial == null || serial.isEmpty) return;
    final api = ref.read(apiServiceProvider);
    await api.writeSetting(serial, id, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schedules',
          style: TextStyle(color: GivLocalColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading settings...', style: TextStyle(color: GivLocalColors.textMuted)),
                ],
              ),
            )
          : _serial == null || _serial!.isEmpty
              ? _buildNotConnected()
              : _buildContent(),
    );
  }

  Widget _buildNotConnected() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No inverter connected.\nConfigure your connection in Settings.',
          textAlign: TextAlign.center,
          style: TextStyle(color: GivLocalColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eco Mode toggle
          _buildToggleCard(
            icon: Icons.eco,
            iconColor: GivLocalColors.battery,
            title: 'Eco Mode',
            subtitle: 'Match demand from solar and battery',
            value: _ecoMode,
            onChanged: (v) {
              setState(() => _ecoMode = v);
              _writeSetting(SettingIds.ecoMode, v);
            },
          ),
          const SizedBox(height: 16),

          // Battery Reserve
          const _SectionHeader(label: 'BATTERY RESERVE'),
          const SizedBox(height: 8),
          _buildReserveCard(),
          const SizedBox(height: 24),

          // AC Charge
          _buildToggleCard(
            icon: Icons.battery_charging_full,
            iconColor: GivLocalColors.solar,
            title: 'AC Charge',
            subtitle: 'Charge battery from grid during off-peak',
            value: _chargeEnabled,
            onChanged: (v) {
              setState(() => _chargeEnabled = v);
              _writeSetting(SettingIds.enableCharge, v);
            },
          ),
          if (_chargeEnabled) ...[
            const SizedBox(height: 8),
            ScheduleSlotCard(
              slotNumber: 1,
              startTime: _chargeStart,
              endTime: _chargeEnd,
              targetSoc: _chargeTargetSoc,
              enabled: _chargeEnabled,
              onToggle: (v) {
                setState(() => _chargeEnabled = v);
                _writeSetting(SettingIds.enableCharge, v);
              },
            ),
          ],
          const SizedBox(height: 16),

          // DC Discharge
          _buildToggleCard(
            icon: Icons.battery_alert,
            iconColor: GivLocalColors.home,
            title: 'DC Discharge',
            subtitle: 'Discharge battery during peak hours',
            value: _dischargeEnabled,
            onChanged: (v) {
              setState(() => _dischargeEnabled = v);
              _writeSetting(SettingIds.enableDischarge, v);
            },
          ),
          if (_dischargeEnabled) ...[
            const SizedBox(height: 8),
            ScheduleSlotCard(
              slotNumber: 1,
              startTime: _dischargeStart,
              endTime: _dischargeEnd,
              targetSoc: _dischargeTargetSoc,
              enabled: _dischargeEnabled,
              onToggle: (v) {
                setState(() => _dischargeEnabled = v);
                _writeSetting(SettingIds.enableDischarge, v);
              },
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? iconColor.withAlpha(15) : GivLocalColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? iconColor.withAlpha(60) : GivLocalColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: GivLocalColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: GivLocalColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: iconColor,
          ),
        ],
      ),
    );
  }

  Widget _buildReserveCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: GivLocalColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GivLocalColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Minimum charge to keep', style: TextStyle(color: GivLocalColors.textSecondary, fontSize: 13)),
              Text('${_batteryReserve.round()}%',
                  style: const TextStyle(color: GivLocalColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: GivLocalColors.battery,
              inactiveTrackColor: const Color(0x33FFFFFF),
              thumbColor: GivLocalColors.battery,
              overlayColor: const Color(0x2222C55E),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _batteryReserve,
              min: 4,
              max: 100,
              divisions: 96,
              onChanged: (v) => setState(() => _batteryReserve = v),
              onChangeEnd: (v) => _writeSetting(SettingIds.batteryReserve, v.round()),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('4%', style: TextStyle(color: GivLocalColors.textMuted, fontSize: 11)),
              Text('100%', style: TextStyle(color: GivLocalColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(color: GivLocalColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
    );
  }
}
