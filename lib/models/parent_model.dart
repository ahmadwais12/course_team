import 'package:json_annotation/json_annotation.dart';

part 'parent_model.g.dart';

@JsonSerializable()
class Parent {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final List<String> childIds;
  final String? address;

  Parent({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.childIds,
    this.address,
  });

  factory Parent.fromJson(Map<String, dynamic> json) => _$ParentFromJson(json);
  Map<String, dynamic> toJson() => _$ParentToJson(this);
}
