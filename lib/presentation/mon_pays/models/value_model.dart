// models/value_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'value_model.g.dart';

@JsonSerializable()
class Value extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? iconCode;
  final String? category;

  const Value({
    required this.id,
    required this.title,
    this.description,
    this.iconCode,
    this.category,
  });

  Value copyWith({
    String? id,
    String? title,
    String? description,
    String? iconCode,
    String? category,
  }) {
    return Value(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconCode: iconCode ?? this.iconCode,
      category: category ?? this.category,
    );
  }

  factory Value.fromJson(Map<String, dynamic> json) => _$ValueFromJson(json);
  Map<String, dynamic> toJson() => _$ValueToJson(this);

  @override
  List<Object?> get props => [id, title, description, iconCode, category];
}
