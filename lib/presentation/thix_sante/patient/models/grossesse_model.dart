class PregnancyProfile {
  final String id;
  final String userId;
  final DateTime lastPeriodDate;
  final DateTime dpa;
  PregnancyProfile({required this.id, required this.userId, required this.lastPeriodDate, required this.dpa});
  factory PregnancyProfile.fromJson(Map<String,dynamic> j)=> PregnancyProfile(
    id: j['id'], userId: j['user_id'],
    lastPeriodDate: DateTime.parse(j['last_period_date']),
    dpa: DateTime.parse(j['dpa']),
  );
  int get daysSince => DateTime.now().difference(lastPeriodDate).inDays;
  int get sa => daysSince ~/7;
  int get daysRemain => sa %7;
  int get remainingDays => dpa.difference(DateTime.now()).inDays;
  double get progress => (daysSince/280).clamp(0,1);
}

enum VitalType { poids, tension, glycemie, humeur, sommeil, symptome }

class PregnancyVital {
  final String id; final String userId; final VitalType type;
  final String value; final String? value2; final DateTime createdAt;
  PregnancyVital({required this.id, required this.userId, required this.type, required this.value, this.value2, required this.createdAt});
  factory PregnancyVital.fromJson(Map<String,dynamic> j)=> PregnancyVital(
    id: j['id'], userId: j['user_id'],
    type: VitalType.values.firstWhere((e)=> e.name==j['type'], orElse: ()=> VitalType.poids),
    value: j['value']??'', value2: j['value2'], createdAt: DateTime.parse(j['created_at']),
  );
}

class PregnancyKick {
  final String id; final DateTime createdAt;
  PregnancyKick({required this.id, required this.createdAt});
  factory PregnancyKick.fromJson(Map<String,dynamic> j)=> PregnancyKick(id: j['id'], createdAt: DateTime.parse(j['created_at']));
}

class PregnancyJournal {
  final String id; final String title; final String content;
  final String? photoUrl; final String? mood; final DateTime createdAt;
  PregnancyJournal({required this.id, required this.title, required this.content, this.photoUrl, this.mood, required this.createdAt});
  factory PregnancyJournal.fromJson(Map<String,dynamic> j)=> PregnancyJournal(
    id: j['id'], title: j['title']??'', content: j['content']??'',
    photoUrl: j['photo_url'], mood: j['mood'], createdAt: DateTime.parse(j['created_at']),
  );
}

class PregnancyContraction {
  final String id; final int durationSec; final int intervalSec; final DateTime createdAt;
  PregnancyContraction({required this.id, required this.durationSec, required this.intervalSec, required this.createdAt});
  factory PregnancyContraction.fromJson(Map<String,dynamic> j)=> PregnancyContraction(
    id: j['id'], durationSec: j['duration_sec']??0, intervalSec: j['interval_sec']??0, createdAt: DateTime.parse(j['created_at']),
  );
}

class PregnancyChecklist {
  final String id; final String item; final String category; bool done;
  PregnancyChecklist({required this.id, required this.item, required this.category, required this.done});
  factory PregnancyChecklist.fromJson(Map<String,dynamic> j)=> PregnancyChecklist(id: j['id'], item: j['item'], category: j['category'], done: j['done']??false);
}

class BabyWeekInfo {
  final String fruit; final String size; final String weight; final String desc;
  BabyWeekInfo({required this.fruit, required this.size, required this.weight, required this.desc});
}
