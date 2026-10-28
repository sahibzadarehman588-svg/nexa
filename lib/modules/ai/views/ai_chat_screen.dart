import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ai_controller.dart';
import '../../../data/services/ai_service.dart';
import '../../../core/theme/app_colors.dart';

class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AIController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NEXIA AI Assistant'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('Clear Chat History'),
                  content: const Text('Are you sure you want to clear all chat history?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.clearHistory();
                        Get.back();
                        Get.snackbar(
                          'Success',
                          'Chat history cleared',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (!controller.isConfigured) {
            return _buildConfigWarning(context);
          }

          return Column(
            children: [
              Expanded(
                child: controller.messages.isEmpty
                    ? _buildEmptyState()
                    : _buildChatList(controller),
              ),
              _buildInputArea(controller),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildConfigWarning(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            const Text(
              'API Key Not Configured',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please add your Gemini API key in:\nlib/core/constants/ai_config.dart',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('How to Get API Key'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('1. Go to https://makersuite.google.com/app/apikey'),
                          SizedBox(height: 8),
                          Text('2. Sign in with your Google account'),
                          SizedBox(height: 8),
                          Text('3. Click "Create API Key"'),
                          SizedBox(height: 8),
                          Text('4. Copy the API key'),
                          SizedBox(height: 8),
                          Text('5. Open lib/core/constants/ai_config.dart'),
                          SizedBox(height: 8),
                          Text('6. Replace YOUR_GEMINI_API_KEY_HERE with your key'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show Instructions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'NEXIA AI Assistant',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about productivity,\ntasks, inventory, or expenses.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(AIController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.messages.length,
      itemBuilder: (context, index) {
        final message = controller.messages[index];
        final isUser = message.role == 'user';
        return _buildMessageBubble(message, isUser);
      },
    );
  }

  Widget _buildMessageBubble(AIChatMessage message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(
          maxWidth: 280,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? AppColors.surface : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser)
                  IconButton(
                    icon: const Icon(Icons.volume_up, size: 16),
                    onPressed: () {
                      Get.find<AIController>().speakResponse(message.content);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser
                        ? AppColors.surface.withValues(alpha: 0.7)
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputArea(AIController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Obx(() => IconButton(
            icon: Icon(
              controller.isListening.value ? Icons.mic : Icons.mic_none,
              color: controller.isListening.value ? AppColors.error : AppColors.primary,
            ),
            onPressed: () {
              if (controller.isListening.value) {
                controller.stopVoiceInput();
              } else {
                controller.startVoiceInput();
              }
            },
          )),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: controller.currentInput.value),
              onChanged: (value) => controller.currentInput.value = value,
              decoration: InputDecoration(
                hintText: controller.isListening.value
                    ? 'Listening...'
                    : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  color: AppColors.primary,
                  onPressed: () {
                    if (controller.currentInput.value.trim().isNotEmpty) {
                      controller.sendMessage(controller.currentInput.value);
                    }
                  },
                )),
        ],
      ),
    );
  }
}
