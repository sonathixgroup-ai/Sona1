// lib/presentation/thix_sante/patient/models/grossesse_model.dart
enum PregnancyType { singleton, jumeaux, triplets }

class PregnancyProfile {
  final String id; 
  final String userId;
  final DateTime lastPeriodDate; 
  final DateTime dpa;
  final PregnancyType type;

  PregnancyProfile({
    required this.id, 
    required this.userId, 
    required this.lastPeriodDate, 
    required this.dpa, 
    this.type = PregnancyType.singleton
  });

  factory PregnancyProfile.fromJson(Map<String, dynamic> j) => PregnancyProfile(
    id: j['id'], 
    userId: j['user_id'],
    lastPeriodDate: DateTime.parse(j['last_period_date']),
    dpa: DateTime.parse(j['dpa']),
    type: PregnancyType.values.firstWhere((e) => e.name == j['pregnancy_type'], orElse: () => PregnancyType.singleton),
  );

  int get daysSince => DateTime.now().difference(lastPeriodDate).inDays;
  int get sa => daysSince ~/ 7; 
  int get daysRemain => daysSince % 7;
  int get remainingDays => dpa.difference(DateTime.now()).inDays;
  double get progress => (daysSince / 280).clamp(0, 1);
  String trimester() => sa <= 13 ? "1er trimestre" : sa <= 27 ? "2e trimestre" : "3e trimestre";
}

class WeekAdvice {
  final String title; 
  final List<String> babyDevelopment;
  final List<String> motherAdvice; 
  final List<String> nutrition; 
  final List<String> avoid;

  WeekAdvice({
    required this.title, 
    required this.babyDevelopment, 
    required this.motherAdvice, 
    required this.nutrition, 
    required this.avoid
  });
}

class BabyWeekInfo { 
  final String fruit; 
  final String size; 
  final String weight; 
  final String desc; 

  BabyWeekInfo({
    required this.fruit, 
    required this.size, 
    required this.weight, 
    required this.desc
  }); 
}

class PregnancyVital { 
  final String id; 
  final String userId; 
  final String type; 
  final String value; 
  final String? value2; 
  final DateTime createdAt; 

  PregnancyVital({
    required this.id, 
    required this.userId, 
    required this.type, 
    required this.value, 
    this.value2, 
    required this.createdAt
  }); 

  factory PregnancyVital.fromJson(Map<String, dynamic> j) => PregnancyVital(
    id: j['id'], 
    userId: j['user_id'], 
    type: j['type'], 
    value: j['value'] ?? '', 
    value2: j['value2'], 
    createdAt: DateTime.parse(j['created_at'])
  ); 
}

class PregnancyKick { 
  final DateTime createdAt; 
  PregnancyKick({required this.createdAt}); 
  factory PregnancyKick.fromJson(Map<String, dynamic> j) => PregnancyKick(createdAt: DateTime.parse(j['created_at'])); 
}

class PregnancyJournal { 
  final String id; 
  final String title; 
  final String content; 
  final String? photoUrl; 
  final DateTime createdAt; 

  PregnancyJournal({
    required this.id, 
    required this.title, 
    required this.content, 
    this.photoUrl, 
    required this.createdAt
  }); 

  factory PregnancyJournal.fromJson(Map<String, dynamic> j) => PregnancyJournal(
    id: j['id'], 
    title: j['title'] ?? '', 
    content: j['content'] ?? '', 
    photoUrl: j['photo_url'], 
    createdAt: DateTime.parse(j['created_at'])
  ); 
}

class PregnancyContraction { 
  final int durationSec; 
  final int intervalSec; 
  final DateTime createdAt; 

  PregnancyContraction({
    required this.durationSec, 
    required this.intervalSec, 
    required this.createdAt
  }); 

  factory PregnancyContraction.fromJson(Map<String, dynamic> j) => PregnancyContraction(
    durationSec: j['duration_sec'] ?? 0, 
    intervalSec: j['interval_sec'] ?? 0, 
    createdAt: DateTime.parse(j['created_at'])
  ); 
}

class ChecklistItem {
  final String id;
  final String item;
  final bool done;

  ChecklistItem({
    required this.id, 
    required this.item, 
    required this.done,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      item: json['item'] ?? '',
      done: json['done'] ?? json['is_done'] ?? false,
    );
  }
}
