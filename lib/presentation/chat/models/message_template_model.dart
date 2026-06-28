class MessageTemplate {
  final String id;
  final String userId;
  final String name;
  final String content;
  final String? category;
  final List<String> tags;
  final bool isFavorite;
  final int useCount;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final List<String>? placeholders; // Variables like {name}, {date}
  final String? imageUrl;
  final List<TemplateAttachment>? attachments;

  const MessageTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.content,
    this.category,
    this.tags = const [],
    this.isFavorite = false,
    this.useCount = 0,
    required this.createdAt,
    this.lastUsedAt,
    this.placeholders,
    this.imageUrl,
    this.attachments,
  });

  MessageTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    String? content,
    String? category,
    List<String>? tags,
    bool? isFavorite,
    int? useCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    List<String>? placeholders,
    String? imageUrl,
    List<TemplateAttachment>? attachments,
  }) {
    return MessageTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      placeholders: placeholders ?? this.placeholders,
      imageUrl: imageUrl ?? this.imageUrl,
      attachments: attachments ?? this.attachments,
    );
  }

  String renderTemplate(Map<String, String> variables) {
    String result = content;
    variables.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}

class TemplateAttachment {
  final String id;
  final String url;
  final String fileName;
  final String mimeType;

  const TemplateAttachment({
    required this.id,
    required this.url,
    required this.fileName,
    required this.mimeType,
  });
}
