import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import 'file_util.dart';

class CustomImageUtil {
  static final _picker = ImagePicker();

  static String getCoverPath(String fileName) {
    return FileUtil.getRealPath('cover', fileName);
  }

  static String getBackgroundPath(String fileName) {
    return FileUtil.getRealPath('background', fileName);
  }

  static Future<String?> pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final fileName = 'cover-${const Uuid().v7()}.jpg';
    final targetPath = getCoverPath(fileName);
    await image.saveTo(targetPath);
    return fileName;
  }

  static Future<String?> pickBackgroundImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final fileName = 'background-${const Uuid().v7()}.jpg';
    final targetPath = getBackgroundPath(fileName);
    await image.saveTo(targetPath);
    return fileName;
  }

  static Future<bool> deleteCoverImage(String fileName) async {
    final filePath = getCoverPath(fileName);
    return await FileUtil.deleteFile(filePath);
  }

  static Future<bool> deleteBackgroundImage(String fileName) async {
    final filePath = getBackgroundPath(fileName);
    return await FileUtil.deleteFile(filePath);
  }

  static Future<void> cleanupUnusedImages({
    required List<String> usedCoverImages,
    required List<String> usedBackgroundImages,
  }) async {
    final coverFiles = await FileUtil.getDirFileName('cover');
    final backgroundFiles = await FileUtil.getDirFileName('background');

    for (final file in coverFiles) {
      if (!usedCoverImages.contains(file)) {
        await deleteCoverImage(file);
      }
    }

    for (final file in backgroundFiles) {
      if (!usedBackgroundImages.contains(file)) {
        await deleteBackgroundImage(file);
      }
    }
  }
}
