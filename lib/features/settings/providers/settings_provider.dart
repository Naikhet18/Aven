import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class BusinessSettings {
  final String name;
  final String address;
  final String phone;
  final String gstNumber;
  final String receiptFooter;

  BusinessSettings({
    required this.name,
    required this.address,
    required this.phone,
    required this.gstNumber,
    required this.receiptFooter,
  });

  BusinessSettings copyWith({
    String? name,
    String? address,
    String? phone,
    String? gstNumber,
    String? receiptFooter,
  }) {
    return BusinessSettings(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      gstNumber: gstNumber ?? this.gstNumber,
      receiptFooter: receiptFooter ?? this.receiptFooter,
    );
  }
}

class SettingsNotifier extends Notifier<BusinessSettings> {
  @override
  BusinessSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return BusinessSettings(
      name: prefs.getString('setting_business_name') ?? 'KhaoPiyo Food Stall',
      address: prefs.getString('setting_business_address') ?? '123 Main St',
      phone: prefs.getString('setting_business_phone') ?? '1234567890',
      gstNumber: prefs.getString('setting_business_gst') ?? '',
      receiptFooter: prefs.getString('setting_receipt_footer') ?? 'Thank you for your visit!',
    );
  }

  Future<void> updateSettings(BusinessSettings newSettings) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('setting_business_name', newSettings.name);
    await prefs.setString('setting_business_address', newSettings.address);
    await prefs.setString('setting_business_phone', newSettings.phone);
    await prefs.setString('setting_business_gst', newSettings.gstNumber);
    await prefs.setString('setting_receipt_footer', newSettings.receiptFooter);
    
    state = newSettings;
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, BusinessSettings>(() {
  return SettingsNotifier();
});
