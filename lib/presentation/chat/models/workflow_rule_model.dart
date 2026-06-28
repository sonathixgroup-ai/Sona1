class WorkflowRule {
  final String id;
  final String userId;
  final String name;
  final String description;
  final bool isEnabled;
  final WorkflowTrigger trigger;
  final List<WorkflowAction> actions;
  final WorkflowCondition? condition;
  final int executionOrder; // Lower executes first
  final bool stopIfMatched; // Stop executing other rules
  final DateTime createdAt;
  final DateTime? lastExecutedAt;
  final int executionCount;

  const WorkflowRule({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.trigger,
    required this.actions,
    this.condition,
    this.executionOrder = 0,
    this.stopIfMatched = false,
    required this.createdAt,
    this.lastExecutedAt,
    this.executionCount = 0,
  });

  WorkflowRule copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool? isEnabled,
    WorkflowTrigger? trigger,
    List<WorkflowAction>? actions,
    WorkflowCondition? condition,
    int? executionOrder,
    bool? stopIfMatched,
    DateTime? createdAt,
    DateTime? lastExecutedAt,
    int? executionCount,
  }) {
    return WorkflowRule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      trigger: trigger ?? this.trigger,
      actions: actions ?? this.actions,
      condition: condition ?? this.condition,
      executionOrder: executionOrder ?? this.executionOrder,
      stopIfMatched: stopIfMatched ?? this.stopIfMatched,
      createdAt: createdAt ?? this.createdAt,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      executionCount: executionCount ?? this.executionCount,
    );
  }
}

class WorkflowTrigger {
  final WorkflowTriggerType type;
  final Map<String, dynamic> params;

  const WorkflowTrigger({
    required this.type,
    required this.params,
  });
}

enum WorkflowTriggerType {
  messageReceived,
  messageContains,
  userMentioned,
  messageReacted,
  messageEdited,
  userJoined,
  timeSchedule,
  custom
}

class WorkflowAction {
  final WorkflowActionType type;
  final Map<String, dynamic> params;
  final int delaySeconds; // Delay before execution

  const WorkflowAction({
    required this.type,
    required this.params,
    this.delaySeconds = 0,
  });
}

enum WorkflowActionType {
  sendMessage,
  sendNotification,
  createReminder,
  moveToFolder,
  addLabel,
  archiveConversation,
  muteConversation,
  pinMessage,
  createTask,
  triggerWebhook,
  custom
}

class WorkflowCondition {
  final WorkflowConditionType type;
  final String field;
  final String operator; // ==, !=, contains, regex, etc.
  final dynamic value;

  const WorkflowCondition({
    required this.type,
    required this.field,
    required this.operator,
    required this.value,
  });
}

enum WorkflowConditionType { text, number, date, user, conversation }
