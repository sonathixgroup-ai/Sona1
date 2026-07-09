// lib/presentation/mon_pays/models/historical_figure_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'historical_figure_model.g.dart';

/// Modèle représentant une figure historique
@JsonSerializable()
class HistoricalFigure extends Equatable {
  final String id;
  final String name;
  final String period; // Ex: "1925-1961"
  final String? description;
  final String? imageUrl;

  const HistoricalFigure({
    required this.id,
    required this.name,
    required this.period,
    this.description,
    this.imageUrl,
  });

  HistoricalFigure copyWith({
    String? id,
    String? name,
    String? period,
    String? description,
    String? imageUrl,
  }) {
    return HistoricalFigure(
      id: id ?? this.id,
      name: name ?? this.name,
      period: period ?? this.period,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory HistoricalFigure.fromJson(Map<String, dynamic> json) =>
      _$HistoricalFigureFromJson(json);

  Map<String, dynamic> toJson() => _$HistoricalFigureToJson(this);

  @override
  List<Object?> get props => [id, name, period, description, imageUrl];
}
