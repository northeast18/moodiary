import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moodiary/components/audio_player/audio_player_view.dart';
import 'package:moodiary/l10n/l10n.dart';
import 'package:moodiary/utils/file_util.dart';
import 'package:moodiary/utils/notice_util.dart';

class MediaAudioComponent extends StatelessWidget {
  final DateTime dateTime;
  final List<String> audioList;
  final VoidCallback? onRefresh;

  const MediaAudioComponent({
    super.key,
    required this.dateTime,
    required this.audioList,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat.yMMMEd().format(dateTime),
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.theme.colorScheme.secondary,
                ),
              ),
              Row(
                children: [
                  Text(
                    context.l10n.mediaAudioCount(audioList.length),
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.theme.colorScheme.tertiary,
                    ),
                  ),
                  if (audioList.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: '清空当天',
                      onPressed: () => _deleteDayAudios(context),
                    ),
                ],
              ),
            ],
          ),
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Dismissible(
              key: Key(audioList[index]),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) async {
                await FileUtil.deleteFile(audioList[index]);
                toast.success(message: '删除成功');
                onRefresh?.call();
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: AudioPlayerComponent(path: audioList[index]),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemCount: audioList.length,
        ),
      ],
    );
  }

  void _deleteDayAudios(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空当天音频'),
          content: Text('确定要删除 ${audioList.length} 个音频吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                for (final audio in audioList) {
                  await FileUtil.deleteFile(audio);
                }
                toast.success(message: '删除成功');
                onRefresh?.call();
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
