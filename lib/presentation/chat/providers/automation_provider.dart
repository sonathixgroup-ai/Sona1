import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scheduled_message_model.dart';
import '../models/auto_reply_model.dart';
import '../models/message_template_model.dart';
import '../models/workflow_rule_model.dart';

// Scheduled Messages Provider
final scheduledMessagesProvider =
    StateNotifierProvider<ScheduledMessagesNotifier, List<ScheduledMessage>>((ref) {
  return ScheduledMessagesNotifier();
});

class ScheduledMessagesNotifier extends StateNotifier<List<ScheduledMessage>> {
  ScheduledMessagesNotifier() : super([]);

  void addScheduledMessage(ScheduledMessage message) {
    state = [...state, message];
  }

  void updateScheduledMessage(String messageId, ScheduledMessage updatedMessage) {
    state = state.map((msg) => msg.id == messageId ? updatedMessage : msg).toList();
  }

  void deleteScheduledMessage(String messageId) {
    state = state.where((msg) => msg.id != messageId).toList();
  }

  void toggleScheduledMessage(String messageId) {
    state = state.map((msg) {
      if (msg.id == messageId) {
        return msg.copyWith(isActive: !msg.isActive);
      }
      return msg;
    }).toList();
  }

  void setScheduledMessages(List<ScheduledMessage> messages) {
    state = messages;
  }
}

// Auto-Replies Provider
final autoRepliesProvider = StateNotifierProvider<AutoRepliesNotifier, List<AutoReply>>((ref) {
  return AutoRepliesNotifier();
});

class AutoRepliesNotifier extends StateNotifier<List<AutoReply>> {
  AutoRepliesNotifier() : super([]);

  void addAutoReply(AutoReply reply) {
    state = [...state, reply];
  }

  void updateAutoReply(String replyId, AutoReply updatedReply) {
    state = state.map((reply) => reply.id == replyId ? updatedReply : reply).toList();
  }

  void deleteAutoReply(String replyId) {
    state = state.where((reply) => reply.id != replyId).toList();
  }

  void toggleAutoReply(String replyId) {
    state = state.map((reply) {
      if (reply.id == replyId) {
        return reply.copyWith(isEnabled: !reply.isEnabled);
      }
      return reply;
    }).toList();
  }

  void setAutoReplies(List<AutoReply> replies) {
    state = replies;
  }
}

// Message Templates Provider
final messageTemplatesProvider =
    StateNotifierProvider<MessageTemplatesNotifier, List<MessageTemplate>>((ref) {
  return MessageTemplatesNotifier();
});

class MessageTemplatesNotifier extends StateNotifier<List<MessageTemplate>> {
  MessageTemplatesNotifier() : super([]);

  void addTemplate(MessageTemplate template) {
    state = [...state, template];
  }

  void updateTemplate(String templateId, MessageTemplate updatedTemplate) {
    state = state
        .map((template) => template.id == templateId ? updatedTemplate : template)
        .toList();
  }

  void deleteTemplate(String templateId) {
    state = state.where((template) => template.id != templateId).toList();
  }

  void toggleFavorite(String templateId) {
    state = state.map((template) {
      if (template.id == templateId) {
        return template.copyWith(isFavorite: !template.isFavorite);
      }
      return template;
    }).toList();
  }

  void incrementUseCount(String templateId) {
    state = state.map((template) {
      if (template.id == templateId) {
        return template.copyWith(
          useCount: template.useCount + 1,
          lastUsedAt: DateTime.now(),
        );
      }
      return template;
    }).toList();
  }

  void setTemplates(List<MessageTemplate> templates) {
    state = templates;
  }
}

// Workflow Rules Provider
final workflowRulesProvider =
    StateNotifierProvider<WorkflowRulesNotifier, List<WorkflowRule>>((ref) {
  return WorkflowRulesNotifier();
});

class WorkflowRulesNotifier extends StateNotifier<List<WorkflowRule>> {
  WorkflowRulesNotifier() : super([]);

  void addWorkflowRule(WorkflowRule rule) {
    state = [...state, rule];
  }

  void updateWorkflowRule(String ruleId, WorkflowRule updatedRule) {
    state = state.map((rule) => rule.id == ruleId ? updatedRule : rule).toList();
  }

  void deleteWorkflowRule(String ruleId) {
    state = state.where((rule) => rule.id != ruleId).toList();
  }

  void toggleWorkflowRule(String ruleId) {
    state = state.map((rule) {
      if (rule.id == ruleId) {
        return rule.copyWith(isEnabled: !rule.isEnabled);
      }
      return rule;
    }).toList();
  }

  void reorderRules(int oldIndex, int newIndex) {
    final rules = List<WorkflowRule>.from(state);
    final rule = rules.removeAt(oldIndex);
    rules.insert(newIndex, rule);
    state = rules;
  }

  void setWorkflowRules(List<WorkflowRule> rules) {
    state = rules;
  }
}
