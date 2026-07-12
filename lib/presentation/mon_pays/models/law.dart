// lib/presentation/mon_pays/models/law.dart
// Entité Law pour les lois, codes, constitutions

class Law {
  final String id;
  final String title;
  final String type; // 'constitution', 'code', 'loi', 'ordonnance', 'decret'
  final String category; // 'Constitution', 'Codes', 'Droits', 'Devoirs', 'Institutions', 'Justice', 'Administration', 'Symboles Nationaux', 'Citoyenneté'
  final String? number; // Numéro officiel
  final String? date; // Date de promulgation
  final String? summary;
  final String? content;
  final List<String> articles;
  final String? pdfUrl;

  Law({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    this.number,
    this.date,
    this.summary,
    this.content,
    this.articles = const [],
    this.pdfUrl,
  });

  factory Law.fromJson(Map<String, dynamic> json) {
    return Law(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      number: json['number'] as String?,
      date: json['date'] as String?,
      summary: json['summary'] as String?,
      content: json['content'] as String?,
      articles: List<String>.from(json['articles'] ?? []),
      pdfUrl: json['pdf_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'category': category,
    'number': number,
    'date': date,
    'summary': summary,
    'content': content,
    'articles': articles,
    'pdf_url': pdfUrl,
  };

  Law copyWith({
    String? id,
    String? title,
    String? type,
    String? category,
    String? number,
    String? date,
    String? summary,
    String? content,
    List<String>? articles,
    String? pdfUrl,
  }) {
    return Law(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      number: number ?? this.number,
      date: date ?? this.date,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      articles: articles ?? this.articles,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }
}
