// lib/presentation/network/models/opportunity_model.dart

class OpportunityModel {
  final String id;
  final String title;
  final String company;
  final String location;

  OpportunityModel({required this.id, required this.title, required this.company, required this.location});

  factory OpportunityModel.fromMap(Map<String, dynamic> m) => OpportunityModel(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        company: m['company'] as String? ?? '',
        location: m['location'] as String? ?? '',
      );
}
