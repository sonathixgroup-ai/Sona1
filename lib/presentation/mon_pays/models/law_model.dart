// models/law_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../enums/law_type.dart';

part 'law_model.g.dart';

@JsonSerializable()
class Law extends Equatable {
  final String id;
  final String title;
  final LawType type;
  final String? content;
  final String? summary;
  final String? dateAdopted;
  final String? datePublished;

  const Law({
    required this.id,
    required this.title,
    required this.type,
    this.content,
    this.summary,
    this.dateAdopted,
    this.datePublished,
  });

  Law copyWith({
    String? id,
    String? title,
    LawType? type,
    String? content,
    String? summary,
    String? dateAdopted,
    String? datePublished,
  }) {
    return Law(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      dateAdopted: dateAdopted ?? this.dateAdopted,
      datePublished: datePublished ?? this.datePublished,
    );
  }

  factory Law.fromJson(Map<String, dynamic> json) => _$LawFromJson(json);
  Map<String, dynamic> toJson() => _$LawToJson(this);

  @override
  List<Object?> get props => [id, title, type, content, summary, dateAdopted, datePublished];
}
