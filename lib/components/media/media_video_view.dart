import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moodiary/components/base/button.dart';
import 'package:moodiary/components/base/image.dart';
import 'package:moodiary/l10n/l10n.dart';
import 'package:moodiary/pages/video/video_view.dart';
import 'package:moodiary/utils/file_util.dart';
import 'package:moodiary/utils/notice_util.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class MediaVideoComponent extends StatelessWidget {
  final DateTime dateTime;
  final List<String> videoList;
  final VoidCallback? onRefresh;

  const MediaVideoComponent({
    super.key,
    required this.dateTime,
    required this.videoList,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // 将视频路径转换为缩略图路径
    final thumbnailList =
        videoList.map((e) {
          final id = e.split('video-')[1].split('.')[0];
          return '${dirname(e)}/thumbnail-$id.jpeg';
        }).toList();
    final heroPrefix = const Uuid().v4();
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
                    context.l10n.mediaVideoCount(videoList.length),
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.theme.colorScheme.tertiary,
                    ),
                  ),
                  if (videoList.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: '清空当天',
                      onPressed: () => _deleteDayVideos(context),
                    ),
                ],
              ),
            ],
          ),
        ),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120,
            childAspectRatio: 1.0,
            crossAxisSpacing: 1.0,
            mainAxisSpacing: 1.0,
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return GestureDetector(
              onLongPress: () => _showDeleteDialog(context, videoList[index], thumbnailList[index]),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: MoodiaryImage(
                      imagePath: thumbnailList[index],
                      heroTag: '$heroPrefix$index',
                      onTap: () async {
                        await showVideoView(context, videoList, index);
                      },
                      size: 120,
                    ),
                  ),
                  const IgnorePointer(
                    child: FrostedGlassButton(
                      size: 32,
                      child: Center(child: Icon(Icons.play_arrow_rounded)),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _showDeleteDialog(context, videoList[index], thumbnailList[index]),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          itemCount: thumbnailList.length,
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, String videoPath, String thumbnailPath) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除视频'),
          content: Text('确定要删除 ${basename(videoPath)} 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FileUtil.deleteFile(videoPath);
                await FileUtil.deleteFile(thumbnailPath);
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

  void _deleteDayVideos(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空当天视频'),
          content: Text('确定要删除 ${videoList.length} 个视频吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                for (final video in videoList) {
                  final id = video.split('video-')[1].split('.')[0];
                  final thumbnail = '${dirname(video)}/thumbnail-$id.jpeg';
                  await FileUtil.deleteFile(video);
                  await FileUtil.deleteFile(thumbnail);
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
