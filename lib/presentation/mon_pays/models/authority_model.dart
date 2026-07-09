// models/authority_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../enums/authority_type.dart';

part 'authority_model.g.dart';

@JsonSerializable()
class Authority extends Equatable {
  final String id;
  final String name;
  final String title;
  final AuthorityType type;
  final String? party;
  final String? biography;
  final String? photoUrl;
  final String? startDate;
  final String? endDate;

  const Authority({
    required this.id,
    required this.name,
    required this.title,
    required this.type,
    this.party,
    this.biography,
    this.photoUrl,
    this.startDate,
    this.endDate,
  });

  Authority copyWith({
    String? id,
    String? name,
    String? title,
    AuthorityType? type,
    String? party,
    String? biography,
    String? photoUrl,
    String? startDate,
    String? endDate,
  }) {
    return Authority(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      type: type ?? this.type,
      party: party ?? this.party,
      biography: biography ?? this.biography,
      photoUrl: photoUrl ?? this.photoUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  factory Authority.fromJson(Map<String, dynamic> json) => _$AuthorityFromJson(json);
  Map<String, dynamic> toJson() => _$AuthorityToJson(this);

  @override
  List<Object?> get props => [id, name, title, type, party, biography, photoUrl, startDate, endDate];
}
