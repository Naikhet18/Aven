import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';

class ExportService {
  Future<void> exportOrdersToCsv(List<Order> orders) async {
    List<List<dynamic>> csvData = [
      // Header row
      ['Order ID', 'Order Number', 'Date', 'Type', 'Table', 'Status', 'Payment Status', 'Subtotal', 'Tax', 'Discount', 'Total'],
    ];

    for (var order in orders) {
      csvData.add([
        order.id,
        order.orderNumber,
        order.createdAt?.toIso8601String() ?? '',
        order.orderType,
        order.tableNumber ?? '',
        order.status,
        order.paymentStatus,
        order.subtotal,
        order.tax,
        order.discount,
        order.total,
      ]);
    }

    String csvString = const ListToCsvConverter().convert(csvData);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/orders_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvString);

    await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: 'Order Export'));
  }
}
