// lib/presentation/mon_pays/models/law_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'law_model.g.dart';

/// Modèle représentant une loi ou valeur
@JsonSerializable()
class Law extends Equatable {
  final String id;
  final String title; // "Constitution", "Institutions", etc.
  final String? content;
  final String? category; // Groupe facultatif

  const Law({
    required this.id,
    required this.title,
    this.content,
    this.category,
  });

  Law copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
  }) {
    return Law(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
    );
  }

  factory Law.fromJson(Map<String, dynamic> json) => _$LawFromJson(json);

  Map<String, dynamic> toJson() => _$LawToJson(this);

  @override
  List<Object?> get props => [id, title, content, category];
}
