import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moodiary/api/api.dart';
import 'package:moodiary/common/models/ai_provider.dart';
import 'package:moodiary/common/models/hunyuan.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/diary_type.dart';
import 'package:moodiary/common/values/keyboard_state.dart';
import 'package:moodiary/components/keyboard_listener/keyboard_listener.dart';
import 'package:moodiary/pages/home/diary/diary_logic.dart';
import 'package:moodiary/persistence/isar.dart';
import 'package:moodiary/utils/ai_config_util.dart';
import 'package:moodiary/utils/notice_util.dart';

import 'assistant_state.dart';

class AssistantLogic extends GetxController {
  final AssistantState state = AssistantState();

  //输入框控制器
  late TextEditingController textEditingController = TextEditingController();

  //控制器
  late ScrollController scrollController = ScrollController();

  //聚焦对象
  late FocusNode focusNode = FocusNode();
  late final KeyboardObserver keyboardObserver;

  List<double> heightList = [];

  @override
  void onInit() {
    // 初始化状态
    state.providerType.value = AIConfigUtil.getProviderType();
    state.modelVersion.value = 0;

    // 监听配置对话框标志
    ever(state.showConfigDialog, (show) {
      if (show == true) {
        // 延迟执行，确保UI已更新
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Get.context != null) {
            _showConfigDialogFromLogic(Get.context!);
            state.showConfigDialog.value = false;
          }
        });
      }
    });

    keyboardObserver = KeyboardObserver(
      onStateChanged: (keyboardState) {
        switch (keyboardState) {
          case KeyboardState.opening:
            break;
          case KeyboardState.closing:
            unFocus();
            break;
          case KeyboardState.closed:
            break;
          case KeyboardState.unknown:
            break;
        }
      },
    );
    keyboardObserver.start();
    super.onInit();
  }

  @override
  void onClose() {
    keyboardObserver.stop();
    textEditingController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void handleBack() {
    if (focusNode.hasFocus) {
      unFocus();
      Future.delayed(const Duration(seconds: 1), () {
        Get.back();
      });
    } else {
      Get.back();
    }
  }

  void unFocus() {
    focusNode.unfocus();
  }

  void newChat() {
    state.messages = {};
    update();
  }

  void clearText() {
    textEditingController.clear();
  }

  //对话
  Future<void> getAi(String ask) async {
    // 检查API配置
    if (!AIConfigUtil.checkApiKeyConfigured()) {
      // 显示提示并打开配置对话框
      final providerType = AIConfigUtil.getProviderType();
      if (providerType == AIProviderType.hunyuan) {
        toast.info(message: '请先在实验室配置腾讯云ID和Key');
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.toNamed('/laboratory');
        });
      } else {
        toast.info(message: '请先配置API Key');
        // 通知视图打开配置对话框
        state.showConfigDialog.value = true;
      }
      return;
    }

    //清空输入框
    clearText();
    //失去焦点
    unFocus();
    //拿到用户提问后，对话上下文中增加一项用户提问
    final askTime = DateTime.now().toLocal();
    state.messages[askTime] = Message(role: 'user', content: ask);
    update();
    toBottom();

    // 获取当前提供商类型
    final providerType = AIConfigUtil.getProviderType();

    //带着上下文请求
    try {
      final stream = await Api.getAIChat(state.messages.values.toList());

      if (stream == null) {
        // API调用失败，移除用户消息并提示
        state.messages.remove(askTime);
        update();
        toast.error(message: '无法连接到AI服务，请检查网络和配置');
        return;
      }

      //如果收到了请求，添加一个回答上下文
      final replyTime = DateTime.now().toLocal();
      state.messages[replyTime] = const Message(role: 'assistant', content: '');
      update();

      //接收stream
      stream.listen(
        (content) {
          if (content != '' && content.contains('data')) {
            try {
              final dataStr = content.split('data: ')[1];

              // 腾讯混元使用HunyuanResponse
              if (providerType == AIProviderType.hunyuan) {
                final HunyuanResponse result = HunyuanResponse.fromJson(
                  jsonDecode(dataStr),
                );
                final currentMessage = state.messages[replyTime]!;
                state.messages[replyTime] = currentMessage.copyWith(
                  content:
                      currentMessage.content +
                      result.choices!.first.delta!.content!,
                );
                HapticFeedback.vibrate();
                update();
                toBottom();
              } else {
                // OpenAI格式
                final Map<String, dynamic> result = jsonDecode(dataStr);
                final delta = result['choices']?[0]?['delta'];
                if (delta != null && delta['content'] != null) {
                  final currentMessage = state.messages[replyTime]!;
                  state.messages[replyTime] = currentMessage.copyWith(
                    content: currentMessage.content + delta['content'],
                  );
                  HapticFeedback.vibrate();
                  update();
                  toBottom();
                }
              }
            } catch (e) {
              // 忽略解析错误
            }
          }
        },
        onError: (error) {
          // 处理流错误
          toast.error(message: 'AI响应出错: $error');
        },
      );
    } catch (e) {
      // 网络或其他异常
      state.messages.remove(askTime);
      update();
      toast.error(message: '请求失败: $e');
    }
  }

  void toBottom() {
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
  }

  String getText() {
    return textEditingController.text;
  }

  Future<void> checkGetAi() async {
    final text = getText();
    if (text != '') {
      await getAi(text);
    } else {
      toast.info(message: '还没有输入问题');
    }
  }

  void changeProvider(AIProviderType type) async {
    state.providerType.value = type;
    state.messages = {};
    await AIConfigUtil.setProviderType(type);
    update();
  }

  void changeModel(int version) {
    state.modelVersion.value = version;
    state.messages = {};
  }

  /// 保存对话为日记
  Future<void> saveChatAsDiary() async {
    if (state.messages.isEmpty) {
      toast.info(message: '暂无对话内容可保存');
      return;
    }

    // 构建对话内容
    final buffer = StringBuffer();
    buffer.writeln('# AI对话记录');
    buffer.writeln('');
    buffer.writeln('**时间**: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');

    for (final entry in state.messages.entries) {
      final time = entry.key;
      final message = entry.value;
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      if (message.role == 'user') {
        buffer.writeln('### 🧑 用户 ($timeStr)');
        buffer.writeln('');
        buffer.writeln(message.content);
        buffer.writeln('');
      } else {
        buffer.writeln('### 🤖 助手 ($timeStr)');
        buffer.writeln('');
        buffer.writeln(message.content);
        buffer.writeln('');
      }
      buffer.writeln('---');
      buffer.writeln('');
    }

    // 创建日记
    final now = DateTime.now().toLocal();
    final diary = Diary()
      ..title = 'AI对话 - ${DateFormat('MM-dd HH:mm').format(now)}'
      ..content = buffer.toString()
      ..contentText = buffer.toString().replaceAll('#', '').replaceAll('*', '').replaceAll('-', '')
      ..time = now
      ..lastModified = now
      ..type = DiaryType.markdown.value
      ..mood = 0.5
      ..show = true
      ..categoryId = null;

    try {
      await IsarUtil.insertADiary(diary);
      toast.success(message: '对话已保存为日记');
      // 刷新主页日记列表
      if (Bind.isRegistered<DiaryLogic>()) {
        await Bind.find<DiaryLogic>().updateDiary(null, jump: false);
      }
    } catch (e) {
      toast.error(message: '保存失败: $e');
    }
  }

  /// 从Logic层打开配置对话框
  void _showConfigDialogFromLogic(BuildContext context) {
    final providerType = AIConfigUtil.getProviderType();
    final provider = AIConfigUtil.getCurrentProvider();
    final controller = TextEditingController();
    final baseUrlController = TextEditingController();
    final providerName = providerType == AIProviderType.custom
        ? AIConfigUtil.getCustomProviderName()
        : AIProviders.getTypeName(providerType);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                spacing: 8.0,
                children: [
                  const Icon(Icons.settings_rounded),
                  Text('API配置 - $providerName'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (providerType == AIProviderType.hunyuan) ...[
                      const Text('腾讯混元需要在实验室页面配置 ID 和 Key'),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Get.toNamed('/laboratory');
                        },
                        icon: const Icon(Icons.science_rounded),
                        label: const Text('前往实验室配置'),
                      ),
                    ] else ...[
                      Text(
                        '请输入 ${provider.name} 的 API Key',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          hintText: 'sk-...',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.key_rounded),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: baseUrlController,
                        decoration: InputDecoration(
                          labelText: 'Base URL (可选)',
                          hintText: provider.baseUrl,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.link_rounded),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '如使用官方 API，可留空 Base URL',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
                if (providerType != AIProviderType.hunyuan)
                  TextButton(
                    onPressed: () async {
                      await AIConfigUtil.setApiKey(controller.text);
                      await AIConfigUtil.setBaseUrl(baseUrlController.text);
                      if (context.mounted) {
                        Navigator.pop(context);
                        toast.success(message: '配置已保存');
                      }
                    },
                    child: const Text('保存'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
