// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryItem _$InventoryItemFromJson(Map<String, dynamic> json) =>
    InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toInt(),
      minStockLevel: (json['min_stock_level'] as num).toInt(),
      unit: json['unit'] as String,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      supplierId: json['supplier_id'] as String?,
      location: json['location'] as String,
      lastRestocked: json['last_restocked'] == null
          ? null
          : DateTime.parse(json['last_restocked'] as String),
    );

Map<String, dynamic> _$InventoryItemToJson(InventoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'description': instance.description,
      'quantity': instance.quantity,
      'min_stock_level': instance.minStockLevel,
      'unit': instance.unit,
      'unit_price': instance.unitPrice,
      'supplier_id': instance.supplierId,
      'location': instance.location,
      'last_restocked': instance.lastRestocked?.toIso8601String(),
    };

Supplier _$SupplierFromJson(Map<String, dynamic> json) => Supplier(
      id: json['id'] as String,
      name: json['name'] as String,
      contactPerson: json['contact_person'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
    );

Map<String, dynamic> _$SupplierToJson(Supplier instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'contact_person': instance.contactPerson,
      'phone': instance.phone,
      'email': instance.email,
      'address': instance.address,
    };

Inventory _$InventoryFromJson(Map<String, dynamic> json) => Inventory(
      items: (json['items'] as List<dynamic>)
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      suppliers: (json['suppliers'] as List<dynamic>)
          .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InventoryToJson(Inventory instance) => <String, dynamic>{
      'items': instance.items,
      'suppliers': instance.suppliers,
    };
