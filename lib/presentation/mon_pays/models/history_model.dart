// models/history_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'history_model.g.dart';

@JsonSerializable()
class HistoricalFigure extends Equatable {
  final String id;
  final String name;
  final String period;
  final String? description;
  final String? imageUrl;
  final String? biography;

  const HistoricalFigure({
    required this.id,
    required this.name,
    required this.period,
    this.description,
    this.imageUrl,
    this.biography,
  });

  HistoricalFigure copyWith({
    String? id,
    String? name,
    String? period,
    String? description,
    String? imageUrl,
    String? biography,
  }) {
    return HistoricalFigure(
      id: id ?? this.id,
      name: name ?? this.name,
      period: period ?? this.period,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      biography: biography ?? this.biography,
    );
  }

  factory HistoricalFigure.fromJson(Map<String, dynamic> json) => _$HistoricalFigureFromJson(json);
  Map<String, dynamic> toJson() => _$HistoricalFigureToJson(this);

  @override
  List<Object?> get props => [id, name, period, description, imageUrl, biography];
}
