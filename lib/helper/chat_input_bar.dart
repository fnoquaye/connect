import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_user.dart';

class ChatInputBar extends StatefulWidget {
  final ChatUser recipient;
  final ValueNotifier<bool> isEmojiPickerVisible;
  final TextEditingController textController;
  final Future<void> Function(String) onSend;
  final Function(String) onTextChanged;

  const ChatInputBar({

  super.key,
  required this.recipient,
  required this.isEmojiPickerVisible,
  required this.textController,
  required this.onSend,
  required this.onTextChanged,
});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _isSending = false; // Tracks if a message is being sent
  final ValueNotifier<bool> _isTextEmpty = ValueNotifier(true); // Tracks if input is empty
  Timer? _debouncer; // Debounces text changes

  @override
  void dispose() {
    _debouncer?.cancel();
    _isTextEmpty.dispose();
    super.dispose();
  }

  void _handleTextChange(String value) {
    final isEmpty = value.trim().isEmpty;
    if (_isTextEmpty.value != isEmpty) {
      _isTextEmpty.value = isEmpty;
    }

    widget.onTextChanged(value); // Notify parent
    _debouncer?.cancel();
    _debouncer = Timer(const Duration(milliseconds: 150), () {});
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(30),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: ValueListenableBuilder<bool>(
                     valueListenable: widget.isEmojiPickerVisible,
                      builder: (context, isVisible, child) {
                        return Icon(
                          isVisible
                              ? Icons.keyboard
                              : Icons.emoji_emotions_outlined,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                        );
                      }),
                    onPressed: () {
                      widget.isEmojiPickerVisible.value = !widget.isEmojiPickerVisible.value;
                      if (widget.isEmojiPickerVisible.value) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.textController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      onChanged: _handleTextChange,
                      onTap: () {
                        if (widget.isEmojiPickerVisible.value) {
                          widget.isEmojiPickerVisible.value = false;
                        }
                      },
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isTextEmpty,
              builder: (context, isEmpty, child) {
                return IconButton(
                  icon: _isSending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: isEmpty || _isSending
                      ? null
                      : () async {
                    final msg = widget.textController.text.trim();
                    if (msg.isEmpty) return;

                    widget.textController.clear();
                    _handleTextChange('');
                    setState(() => _isSending = true);

                    await widget.onSend(msg);
                    if (mounted) setState(() => _isSending = false);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
