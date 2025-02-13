import 'package:stock_scan_app/models/inventory_item.dart';

class Storage {
  final String id;
  String name;
  final List<InventoryItem> items;
  int? iconId;

  Storage({required this.id, required this.name, this.items = const [], this.iconId});
}
