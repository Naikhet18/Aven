import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class BusinessSettings {
  final String name;
  final String address;
  final String phone;
  final String gstNumber;
  final String receiptFooter;
  final double taxRatePercent;
  final String currencySymbol;
  final int loyaltyPointsPerCurrencyUnit; // e.g. 1 point earned per 100 spent
  final int tableCount;

  BusinessSettings({
    required this.name,
    required this.address,
    required this.phone,
    required this.gstNumber,
    required this.receiptFooter,
    this.taxRatePercent = 0,
    this.currencySymbol = '₹',
    this.loyaltyPointsPerCurrencyUnit = 100,
    this.tableCount = 12,
  });

  BusinessSettings copyWith({
    String? name,
    String? address,
    String? phone,
    String? gstNumber,
    String? receiptFooter,
    double? taxRatePercent,
    String? currencySymbol,
    int? loyaltyPointsPerCurrencyUnit,
    int? tableCount,
  }) {
    return BusinessSettings(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      gstNumber: gstNumber ?? this.gstNumber,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      loyaltyPointsPerCurrencyUnit: loyaltyPointsPerCurrencyUnit ?? this.loyaltyPointsPerCurrencyUnit,
      tableCount: tableCount ?? this.tableCount,
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
      taxRatePercent: prefs.getDouble('setting_tax_rate') ?? 0,
      currencySymbol: prefs.getString('setting_currency_symbol') ?? '₹',
      loyaltyPointsPerCurrencyUnit: prefs.getInt('setting_loyalty_rate') ?? 100,
      tableCount: prefs.getInt('setting_table_count') ?? 12,
    );
  }

  Future<void> updateSettings(BusinessSettings newSettings) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('setting_business_name', newSettings.name);
    await prefs.setString('setting_business_address', newSettings.address);
    await prefs.setString('setting_business_phone', newSettings.phone);
    await prefs.setString('setting_business_gst', newSettings.gstNumber);
    await prefs.setString('setting_receipt_footer', newSettings.receiptFooter);
    await prefs.setDouble('setting_tax_rate', newSettings.taxRatePercent);
    await prefs.setString('setting_currency_symbol', newSettings.currencySymbol);
    await prefs.setInt('setting_loyalty_rate', newSettings.loyaltyPointsPerCurrencyUnit);
    await prefs.setInt('setting_table_count', newSettings.tableCount);

    state = newSettings;
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, BusinessSettings>(() {
  return SettingsNotifier();
});
