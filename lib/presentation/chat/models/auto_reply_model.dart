class AutoReply {
  final String id;
  final String userId;
  final bool isEnabled;
  final String trigger; // Keyword or pattern
  final String response;
  final AutoReplyTriggerType triggerType;
  final List<String>? keywords;
  final bool caseSensitive;
  final int priority; // 1-10, higher is more important
  final bool applyToGroups;
  final List<String>? excludeUsers;
  final bool useRegex;

  const AutoReply({
    required this.id,
    required this.userId,
    required this.isEnabled,
    required this.trigger,
    required this.response,
    this.triggerType = AutoReplyTriggerType.keyword,
    this.keywords,
    this.caseSensitive = false,
    this.priority = 5,
    this.applyToGroups = true,
    this.excludeUsers,
    this.useRegex = false,
  });

  AutoReply copyWith({
    String? id,
    String? userId,
    bool? isEnabled,
    String? trigger,
    String? response,
    AutoReplyTriggerType? triggerType,
    List<String>? keywords,
    bool? caseSensitive,
    int? priority,
    bool? applyToGroups,
    List<String>? excludeUsers,
    bool? useRegex,
  }) {
    return AutoReply(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isEnabled: isEnabled ?? this.isEnabled,
      trigger: trigger ?? this.trigger,
      response: response ?? this.response,
      triggerType: triggerType ?? this.triggerType,
      keywords: keywords ?? this.keywords,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      priority: priority ?? this.priority,
      applyToGroups: applyToGroups ?? this.applyToGroups,
      excludeUsers: excludeUsers ?? this.excludeUsers,
      useRegex: useRegex ?? this.useRegex,
    );
  }
}

enum AutoReplyTriggerType {
  keyword,
  regex,
  mention,
  schedule,
  reaction
}
