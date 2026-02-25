import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import 'notice_util.dart';

/// 权限检查结果
class PermissionResult {
  final bool granted;
  final bool isPermanentlyDenied;
  final String? errorMessage;

  const PermissionResult({
    required this.granted,
    this.isPermanentlyDenied = false,
    this.errorMessage,
  });

  factory PermissionResult.granted() => const PermissionResult(granted: true);

  factory PermissionResult.denied({String? message}) => PermissionResult(
        granted: false,
        isPermanentlyDenied: false,
        errorMessage: message,
      );

  factory PermissionResult.permanentlyDenied({String? message}) => PermissionResult(
        granted: false,
        isPermanentlyDenied: true,
        errorMessage: message,
      );
}

class PermissionUtil {
  //权限申请
  static Future<bool> checkPermission(Permission permission) async {
    if (Platform.isMacOS) {
      return true;
    }
    //检查当前权限
    final status = await permission.status;
    //如果还没有授权或者拒绝过
    if (status.isDenied) {
      //尝试申请权限
      final permissionStatus = await permission.request();
      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        toast.info(message: '请授予相关权限');
        return false;
      } else {
        return true;
      }
    } else if (status.isPermanentlyDenied) {
      toast.error(message: '相关权限被禁用，请去设置中手动开启');
      Future.delayed(const Duration(seconds: 2), () => openAppSettings());
      return false;
    } else {
      return true;
    }
  }

  /// 带详细结果的权限检查
  static Future<PermissionResult> checkPermissionWithResult(
    Permission permission,
  ) async {
    if (Platform.isMacOS) {
      return PermissionResult.granted();
    }

    // 检查当前权限状态
    final status = await permission.status;

    // 如果已授权
    if (status.isGranted) {
      return PermissionResult.granted();
    }

    // 如果已经被永久拒绝
    if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied(
        message: '相关权限被禁用，请去设置中手动开启',
      );
    }

    // 如果是limited状态（如iOS的相册权限）
    if (status.isLimited) {
      return PermissionResult.granted();
    }

    // 尝试请求权限
    final permissionStatus = await permission.request();

    if (permissionStatus.isGranted || permissionStatus.isLimited) {
      return PermissionResult.granted();
    }

    if (permissionStatus.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied(
        message: '相关权限被禁用，请去设置中手动开启',
      );
    }

    // 权限被拒绝
    return PermissionResult.denied(message: '请授予相关权限');
  }
}
