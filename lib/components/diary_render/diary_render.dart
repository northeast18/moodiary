import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/diary_type.dart';
import 'package:moodiary/components/markdown_embed/image_embed.dart';
import 'package:moodiary/components/quill_embed/audio_embed.dart';
import 'package:moodiary/components/quill_embed/image_embed.dart';
import 'package:moodiary/components/quill_embed/text_indent.dart';
import 'package:moodiary/components/quill_embed/video_embed.dart';
import 'package:moodiary/utils/theme_util.dart';

class DiaryRender extends StatefulWidget {
  final Diary diary;

  final ColorScheme? customColorScheme;

  /// Disable image embed
  final bool disableImage;

  /// Disable video embed
  final bool disableVideo;

  /// Disable audio embed
  final bool disableAudio;

  const DiaryRender({
    super.key,
    required this.diary,
    this.customColorScheme,
    this.disableImage = false,
    this.disableVideo = false,
    this.disableAudio = false,
  });

  @override
  State<DiaryRender> createState() => _DiaryRenderState();
}

class _DiaryRenderState extends State<DiaryRender> {
  QuillController? _quillController;

  Diary get diary => widget.diary;

  ColorScheme get colorScheme =>
      widget.customColorScheme ?? Theme.of(context).colorScheme;

  @override
  void initState() {
    if (diary.type == DiaryType.markdown.value) {
      // Markdown 类型，不需要初始化 QuillController
    } else {
      // 尝试解析为 Quill Delta 格式
      try {
        _quillController = QuillController(
          document: Document.fromJson(jsonDecode(diary.content)),
          readOnly: true,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // 如果解析失败，创建一个空的 QuillController
        // 并将日记类型视为 markdown
        _quillController = QuillController.basic();
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _quillController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DiaryRender oldWidget) {
    if (oldWidget.diary != diary ||
        oldWidget.customColorScheme != widget.customColorScheme) {
      if (diary.type != DiaryType.markdown.value && _quillController != null) {
        try {
          _quillController!.document = Document.fromJson(
            jsonDecode(diary.content),
          );
        } catch (e) {
          // 解析失败，保持现有状态
        }
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  Widget _buildMarkdownWidget({
    required Brightness brightness,
    required String data,
  }) {
    final config =
        brightness == Brightness.dark
            ? MarkdownConfig.darkConfig
            : MarkdownConfig.defaultConfig;
    return MarkdownBlock(
      data: data,
      config: config.copy(
        configs: [
          ImgConfig(
            builder: (src, _) {
              return MarkdownImageEmbed(isEdit: false, imageName: src);
            },
          ),
          brightness == Brightness.dark
              ? PreConfig.darkConfig.copy(theme: a11yDarkTheme)
              : const PreConfig().copy(theme: a11yLightTheme),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果是 markdown 类型，或者 QuillController 没有被正确初始化，使用 Markdown 渲染
    final isMarkdown = diary.type == DiaryType.markdown.value ||
        _quillController == null ||
        _quillController!.document.isEmpty();

    return isMarkdown
        ? Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildMarkdownWidget(
            brightness: colorScheme.brightness,
            data: diary.content,
          ),
        )
        : QuillEditor.basic(
          controller: _quillController!,
          config: QuillEditorConfig(
            showCursor: false,
            padding: const EdgeInsets.all(8.0),
            customStyles: ThemeUtil.getInstance(
              context,
              customColorScheme: colorScheme,
            ),
            embedBuilders: [
              ImageEmbedBuilder(isEdit: false),
              VideoEmbedBuilder(isEdit: false),
              AudioEmbedBuilder(isEdit: false),
              TextIndentEmbedBuilder(isEdit: false),
            ],
          ),
        );
  }
}
