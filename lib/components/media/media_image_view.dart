import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moodiary/components/base/image.dart';
import 'package:moodiary/l10n/l10n.dart';
import 'package:moodiary/pages/image/image_view.dart';
import 'package:moodiary/utils/file_util.dart';
import 'package:moodiary/utils/notice_util.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class MediaImageComponent extends StatelessWidget {
  final DateTime dateTime;
  final List<String> imageList;
  final VoidCallback? onRefresh;

  const MediaImageComponent({
    super.key,
    required this.dateTime,
    required this.imageList,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
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
                DateFormat.yMMMMEEEEd().format(dateTime),
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.theme.colorScheme.secondary,
                ),
              ),
              Row(
                children: [
                  Text(
                    context.l10n.mediaImageCount(imageList.length),
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.theme.colorScheme.tertiary,
                    ),
                  ),
                  if (imageList.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: '清空当天',
                      onPressed: () => _deleteDayImages(context),
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
            crossAxisSpacing: 1.5,
            mainAxisSpacing: 1.5,
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return GestureDetector(
              onLongPress: () => _showDeleteDialog(context, imageList[index]),
              child: Stack(
                children: [
                  MoodiaryImage(
                    imagePath: imageList[index],
                    size: 120,
                    heroTag: '$heroPrefix$index',
                    onTap: () async {
                      await showImageView(
                        context,
                        imageList,
                        index,
                        heroTagPrefix: heroPrefix,
                      );
                    },
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _showDeleteDialog(context, imageList[index]),
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
          itemCount: imageList.length,
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除图片'),
          content: Text('确定要删除 ${basename(imagePath)} 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await FileUtil.deleteFile(imagePath);
                if (success) {
                  toast.success(message: '删除成功');
                  onRefresh?.call();
                } else {
                  toast.error(message: '删除失败');
                }
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _deleteDayImages(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空当天图片'),
          content: Text('确定要删除 ${imageList.length} 张图片吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                for (final image in imageList) {
                  await FileUtil.deleteFile(image);
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
