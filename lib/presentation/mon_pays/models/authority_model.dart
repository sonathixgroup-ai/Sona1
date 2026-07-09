// lib/presentation/mon_pays/models/authority_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'authority_model.g.dart';

/// Modèle représentant une autorité (dirigeant)
@JsonSerializable()
class Authority extends Equatable {
  final String id;
  final String name;
  final String title;
  final String? party;
  final String? biography;
  final String? photoUrl;

  const Authority({
    required this.id,
    required this.name,
    required this.title,
    this.party,
    this.biography,
    this.photoUrl,
  });

  Authority copyWith({
    String? id,
    String? name,
    String? title,
    String? party,
    String? biography,
    String? photoUrl,
  }) {
    return Authority(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      party: party ?? this.party,
      biography: biography ?? this.biography,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory Authority.fromJson(Map<String, dynamic> json) =>
      _$AuthorityFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorityToJson(this);

  @override
  List<Object?> get props => [id, name, title, party, biography, photoUrl];
}
