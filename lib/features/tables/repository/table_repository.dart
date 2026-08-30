import 'package:khao_piyo_pos/shared/models/restaurant_table.dart';

abstract class TableRepository {
  Future<List<RestaurantTable>> getTables(String businessId);
  Future<void> addTable(RestaurantTable table);
  Future<void> updateTable(RestaurantTable table);
  Future<void> deleteTable(String tableId);
}
