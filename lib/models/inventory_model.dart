import 'package:json_annotation/json_annotation.dart';

part 'inventory_model.g.dart';

@JsonSerializable()
class InventoryItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final int quantity;
  @JsonKey(name: 'min_stock_level')
  final int minStockLevel;
  final String unit;
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  @JsonKey(name: 'supplier_id')
  final String? supplierId;
  final String location;
  @JsonKey(name: 'last_restocked')
  final DateTime? lastRestocked;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.quantity,
    required this.minStockLevel,
    required this.unit,
    this.unitPrice = 0.0,
    this.supplierId,
    required this.location,
    this.lastRestocked,
  });

  bool get isLowStock => quantity <= minStockLevel;

  factory InventoryItem.fromJson(Map<String, dynamic> json) => _$InventoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryItemToJson(this);
}

@JsonSerializable()
class Supplier {
  final String id;
  final String name;
  @JsonKey(name: 'contact_person')
  final String contactPerson;
  final String phone;
  final String email;
  final String address;

  Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);
  Map<String, dynamic> toJson() => _$SupplierToJson(this);
}

@JsonSerializable()
class Inventory {
  final List<InventoryItem> items;
  final List<Supplier> suppliers;

  Inventory({
    required this.items,
    required this.suppliers,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) => _$InventoryFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryToJson(this);
}
