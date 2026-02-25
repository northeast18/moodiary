import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:moodiary/common/models/ai_provider.dart';
import 'package:moodiary/common/values/border.dart';
import 'package:moodiary/components/base/button.dart';
import 'package:moodiary/components/base/text.dart';
import 'package:moodiary/l10n/l10n.dart';
import 'package:moodiary/utils/ai_config_util.dart';
import 'package:moodiary/utils/notice_util.dart';

import 'assistant_logic.dart';

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Bind.find<AssistantLogic>();
    final state = Bind.find<AssistantLogic>().state;

    Widget buildInput() {
      return Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                focusNode: logic.focusNode,
                controller: logic.textEditingController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  fillColor: context.theme.colorScheme.surfaceContainerHighest,
                  filled: true,
                  isDense: true,
                  hintText: '消息',
                  border: const OutlineInputBorder(
                    borderRadius: AppBorderRadius.largeBorderRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton.filled(
              onPressed: () {
                logic.checkGetAi();
              },
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      );
    }

    Widget buildChat() {
      return SliverPadding(
        padding: const EdgeInsets.all(4.0),
        sliver: SliverList.builder(
          itemBuilder: (context, index) {
            final timeList = state.messages.keys.toList();
            final messageList = state.messages.values.toList();
            if (messageList[index].role == 'user') {
              return Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 8.0,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.circleQuestion,
                            size: 16.0,
                          ),
                          Text(
                            '${timeList[index].hour.toString().padLeft(2, '0')}:${timeList[index].minute.toString().padLeft(2, '0')}:${timeList[index].second.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                      MarkdownBlock(
                        data: messageList[index].content,
                        selectable: true,
                        config: context.isDarkMode
                            ? MarkdownConfig.darkConfig
                            : MarkdownConfig.defaultConfig,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Card.filled(
                color: context.theme.colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 8.0,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.bots,
                            color: context.theme.colorScheme.tertiary,
                          ),
                          Text(
                            '${timeList[index].hour.toString().padLeft(2, '0')}:${timeList[index].minute.toString().padLeft(2, '0')}:${timeList[index].second.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                      MarkdownBlock(
                        data: messageList[index].content,
                        selectable: true,
                        config: context.isDarkMode
                            ? MarkdownConfig.darkConfig
                            : MarkdownConfig.defaultConfig,
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          itemCount: state.messages.length,
        ),
      );
    }

    Widget buildEmpty() {
      return const Center(child: FaIcon(FontAwesomeIcons.comments, size: 46.0));
    }

    return GetBuilder<AssistantLogic>(
      builder: (_) {
        return Scaffold(
          body: Stack(
            children: [
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        controller: logic.scrollController,
                        slivers: [
                          SliverAppBar(
                            title: AdaptiveText(
                              context.l10n.settingFunctionAIAssistant,
                              isTitle: true,
                            ),
                            pinned: true,
                            leading: const PageBackButton(),
                            actions: [
                              // AI提供商选择
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return SimpleDialog(
                                        title: const Text('选择提供商'),
                                        children: AIProviderType.values.map((
                                          type,
                                        ) {
                                          final isCustom =
                                              type == AIProviderType.custom;
                                          return SimpleDialogOption(
                                            child: Row(
                                              spacing: 4.0,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    spacing: 8.0,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          type ==
                                                                  AIProviderType
                                                                      .custom
                                                              ? AIConfigUtil.getCustomProviderName()
                                                              : AIProviders.getTypeName(
                                                                  type,
                                                                ),
                                                        ),
                                                      ),
                                                      if (isCustom)
                                                        const Icon(
                                                          Icons
                                                              .add_circle_outline_rounded,
                                                          size: 16,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (state.providerType.value ==
                                                    type) ...[
                                                  const Icon(
                                                    Icons.check_rounded,
                                                  ),
                                                ],
                                              ],
                                            ),
                                            onPressed: () {
                                              if (isCustom) {
                                                // 切换到自定义提供商并打开配置对话框
                                                logic.changeProvider(type);
                                                Navigator.pop(context);
                                                _showConfigDialog(context, logic);
                                              } else {
                                                logic.changeProvider(type);
                                                Navigator.pop(context);
                                              }
                                            },
                                          );
                                        }).toList(),
                                      );
                                    },
                                  );
                                },
                                child: Obx(() {
                                  return Text(
                                    state.providerType.value ==
                                            AIProviderType.custom
                                        ? AIConfigUtil.getCustomProviderName()
                                        : AIProviders.getTypeName(
                                            state.providerType.value,
                                          ),
                                  );
                                }),
                              ),
                              IconButton(
                                onPressed: () {
                                  _showModelSelector(context, logic, state);
                                },
                                icon: const Icon(Icons.layers_rounded),
                              ),
                              IconButton(
                                onPressed: () {
                                  _showConfigDialog(context, logic);
                                },
                                icon: const Icon(Icons.settings_rounded),
                              ),
                              IconButton(
                                onPressed: () {
                                  logic.newChat();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                              // 保存对话为日记
                              IconButton(
                                onPressed: state.messages.isEmpty
                                    ? null
                                    : () {
                                        logic.saveChatAsDiary();
                                      },
                                icon: const Icon(Icons.book_rounded),
                                tooltip: '保存为日记',
                              ),
                            ],
                          ),
                          buildChat(),
                        ],
                      ),
                    ),
                    buildInput(),
                  ],
                ),
              ),
              if (state.messages.isEmpty) ...[buildEmpty()],
            ],
          ),
        );
      },
    );
  }

  void _showModelSelector(
    BuildContext context,
    AssistantLogic logic,
    dynamic state,
  ) {
    final provider = AIConfigUtil.getCurrentProvider();
    final currentModel = AIConfigUtil.getCurrentModel();
    final models = provider.models;

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('选择模型'),
          children: models.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 48,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        const Text('当前提供商没有可用的模型'),
                        const SizedBox(height: 8),
                        Text(
                          '请前往设置配置模型',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showConfigDialog(context, logic);
                          },
                          icon: const Icon(Icons.settings_rounded),
                          label: const Text('前往设置'),
                        ),
                      ],
                    ),
                  ),
                ]
              : models.map((model) {
                  return SimpleDialogOption(
                    child: Row(
                      spacing: 4.0,
                      children: [
                        Expanded(child: Text(model)),
                        if (currentModel == model) ...[
                          const Icon(Icons.check_rounded),
                        ],
                      ],
                    ),
                    onPressed: () async {
                      await AIConfigUtil.setModel(model);
                      logic.newChat();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
        );
      },
    );
  }

  void _showConfigDialog(BuildContext context, AssistantLogic logic) {
    final providerType = AIConfigUtil.getProviderType();
    final provider = AIConfigUtil.getCurrentProvider();
    final apiKeyController = TextEditingController();
    final baseUrlController = TextEditingController();
    final modelInputController = TextEditingController();
    final providerName = providerType == AIProviderType.custom
        ? AIConfigUtil.getCustomProviderName()
        : AIProviders.getTypeName(providerType);

    // 已选择的模型列表
    List<String> selectedModels = List.from(
      AIConfigUtil.getCustomModelsForProvider(providerType).isNotEmpty
          ? AIConfigUtil.getCustomModelsForProvider(providerType)
          : provider.models,
    );

    // 可选模型列表（从API获取）
    List<String> availableModels = [];

    bool isLoadingModels = false;
    bool isTestingConnection = false;

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
                  Expanded(child: Text('API配置 - $providerName')),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (providerType == AIProviderType.hunyuan) ...[
                        const Text('腾讯混元需要在实验室页面配置 ID 和 Key'),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Get.toNamed('/laboratory');
                          },
                          icon: const Icon(Icons.science_rounded),
                          label: const Text('前往实验室配置'),
                        ),
                      ] else ...[
                        // API Key 输入
                        Text(
                          'API Key',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: apiKeyController,
                          decoration: InputDecoration(
                            labelText: 'API Key',
                            hintText: 'sk-... 或 nvapi-...',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.key_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.visibility_rounded),
                              onPressed: () {
                                // 切换显示/隐藏
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Base URL 输入
                        Text(
                          'API 主机地址',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: baseUrlController,
                          decoration: InputDecoration(
                            labelText: '留空使用默认',
                            hintText: provider.baseUrl,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.link_rounded),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 已选模型区域
                        Row(
                          children: [
                            Text(
                              '已选模型 (${selectedModels.length})',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: isLoadingModels
                                  ? null
                                  : () async {
                                      final apiKey = apiKeyController.text.trim();
                                      final baseUrl = baseUrlController.text
                                          .trim()
                                          .isNotEmpty
                                          ? baseUrlController.text.trim()
                                          : provider.baseUrl;

                                      if (apiKey.isEmpty) {
                                        toast.info(message: '请先输入 API Key');
                                        return;
                                      }

                                      setDialogState(
                                        () => isLoadingModels = true,
                                      );

                                      final models = await AIConfigUtil
                                          .fetchModelsFromApi(
                                            baseUrl: baseUrl,
                                            apiKey: apiKey,
                                          );

                                      setDialogState(() {
                                        isLoadingModels = false;
                                        if (models.isNotEmpty) {
                                          availableModels = models;
                                          toast.success(
                                            message: '获取到 ${models.length} 个模型',
                                          );
                                        } else {
                                          toast.info(
                                            message: '未能获取模型，请手动添加',
                                          );
                                        }
                                      });
                                    },
                              icon: isLoadingModels
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('获取模型'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 已选模型列表
                        if (selectedModels.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '暂无已选模型',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          )
                        else
                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                shrinkWrap: true,
                                itemCount: selectedModels.length,
                                itemBuilder: (context, index) {
                                  final model = selectedModels[index];
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 0,
                                    ),
                                    title: Text(
                                      model,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 测试按钮
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: Icon(
                                            Icons.play_arrow_rounded,
                                            size: 20,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          tooltip: '测试此模型',
                                          onPressed: isTestingConnection
                                              ? null
                                              : () async {
                                                  final apiKey = apiKeyController
                                                      .text
                                                      .trim();
                                                  final baseUrl = baseUrlController
                                                          .text
                                                          .trim()
                                                          .isNotEmpty
                                                      ? baseUrlController.text
                                                          .trim()
                                                      : provider.baseUrl;

                                                  if (apiKey.isEmpty) {
                                                    toast.info(
                                                      message: '请先输入 API Key',
                                                    );
                                                    return;
                                                  }

                                                  setDialogState(
                                                    () =>
                                                        isTestingConnection = true,
                                                  );

                                                  final result = await AIConfigUtil
                                                      .testApiConnection(
                                                        baseUrl: baseUrl,
                                                        apiKey: apiKey,
                                                        model: model,
                                                      );

                                                  setDialogState(
                                                    () =>
                                                        isTestingConnection = false,
                                                  );

                                                  if (context.mounted) {
                                                    if (result.success) {
                                                      toast.success(
                                                        message:
                                                            '$model 连接成功',
                                                      );
                                                    } else {
                                                      toast.error(
                                                        message:
                                                            '$model 失败: ${result.message}',
                                                      );
                                                    }
                                                  }
                                                },
                                        ),
                                      // 删除按钮
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                          Icons.remove_circle_outline_rounded,
                                          size: 20,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                        tooltip: '移除',
                                        onPressed: () {
                                          setDialogState(() {
                                            selectedModels.remove(model);
                                            // 如果移除的模型在可选列表中，不需要添加回去（因为可能已存在）
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 可选模型区域（如果有获取到的模型）
                        if (availableModels.isNotEmpty) ...[
                          Text(
                            '可选模型 (${availableModels.length})',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableModels.length,
                              itemBuilder: (context, index) {
                                final model = availableModels[index];
                                final isSelected = selectedModels.contains(
                                  model,
                                );
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: Text(
                                    model,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant
                                          : null,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 20,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        )
                                      : IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: Icon(
                                            Icons.add_circle_outline_rounded,
                                            size: 20,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          tooltip: '添加',
                                          onPressed: () {
                                            setDialogState(() {
                                              if (!selectedModels.contains(
                                                model,
                                              )) {
                                                selectedModels.add(model);
                                              }
                                            });
                                          },
                                        ),
                                  enabled: !isSelected,
                                  onTap: isSelected
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            if (!selectedModels.contains(
                                              model,
                                            )) {
                                              selectedModels.add(model);
                                            }
                                          });
                                        },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 手动添加模型
                        Text(
                          '手动添加模型',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: modelInputController,
                                decoration: const InputDecoration(
                                  hintText: '输入模型代号',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (value) {
                                  final model = value.trim();
                                  if (model.isNotEmpty &&
                                      !selectedModels.contains(model)) {
                                    setDialogState(() {
                                      selectedModels.add(model);
                                      modelInputController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () {
                                final model = modelInputController.text.trim();
                                if (model.isNotEmpty &&
                                    !selectedModels.contains(model)) {
                                  setDialogState(() {
                                    selectedModels.add(model);
                                    modelInputController.clear();
                                  });
                                }
                              },
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
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
                  FilledButton.tonalIcon(
                    onPressed: selectedModels.isEmpty
                        ? null
                        : () async {
                            // 保存配置
                            await AIConfigUtil.setApiKey(apiKeyController.text);
                            await AIConfigUtil.setBaseUrl(
                              baseUrlController.text,
                            );
                            // 保存模型列表
                            await AIConfigUtil.setCustomModelsForProvider(
                              providerType,
                              selectedModels,
                            );
                            // 设置第一个模型为当前模型
                            await AIConfigUtil.setModel(selectedModels.first);

                            if (context.mounted) {
                              Navigator.pop(context);
                              toast.success(message: '配置已保存');
                              logic.update();
                            }
                          },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('保存'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
