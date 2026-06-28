class AIChatState {
  const AIChatState({this.result});

  final AIChatResult? result;

  AIChatState copyWith({AIChatResult? result}) {
    return AIChatState(result: result ?? this.result);
  }
}

class AIChatResult {
  const AIChatResult({
    this.translation,
    this.summary,
    this.smartReplies = const [],
    this.sentiment,
    this.confidence,
    this.raw,
  });

  final String? translation;
  final String? summary;
  final List<String> smartReplies;
  final String? sentiment;
  final double? confidence;
  final Map<String, dynamic>? raw;
}
