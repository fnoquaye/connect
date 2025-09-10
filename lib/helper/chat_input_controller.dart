// Create this as a separate file: chat_input_controller.dart

import 'package:flutter/material.dart';
import '../models/messages.dart';

class ChatInputController {
  static final ValueNotifier<Message?> replyToMessageNotifier = ValueNotifier(null);
  static final ValueNotifier<Message?> editingMessageNotifier = ValueNotifier(null);

  // Helper methods for cleaner access
  static void setReplyMessage(Message? message) {
    editingMessageNotifier.value = null; // Clear edit state
    replyToMessageNotifier.value = message;
  }

  static void setEditMessage(Message? message) {
    replyToMessageNotifier.value = null; // Clear reply state
    editingMessageNotifier.value = message;
  }

  static void clearAll() {
    replyToMessageNotifier.value = null;
    editingMessageNotifier.value = null;
  }

  static void dispose() {
    replyToMessageNotifier.dispose();
    editingMessageNotifier.dispose();
  }
}