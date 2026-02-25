import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:moodiary/common/models/ai_provider.dart';
import 'package:moodiary/persistence/pref.dart';

/// AI配置工具类
class AIConfigUtil {
  static const String _providerTypeKey = 'ai_provider_type';
  static const String _modelKey = 'ai_model';
  static const String _apiKeyKey = 'ai_api_key';
  static const String _baseUrlKey = 'ai_base_url';
  static const String _customModelsKey = 'ai_custom_models';
  static const String _customProviderNameKey = 'ai_custom_provider_name';
  static const String _allProviderModelsKey = 'ai_all_provider_models';

  /// 获取当前提供商类型
  static AIProviderType getProviderType() {
    final typeIndex = PrefUtil.getValue<int>(_providerTypeKey) ?? 0;
    if (typeIndex >= AIProviderType.values.length) {
      return AIProviderType.openai;
    }
    return AIProviderType.values[typeIndex];
  }

  /// 设置提供商类型
  /// 切换提供商时会清除之前的 baseUrl，让新提供商使用自己的官方地址
  static Future<void> setProviderType(AIProviderType type) async {
    // 保存旧的提供商类型
    final oldType = getProviderType();

    // 如果切换到不同的提供商（且不是自定义），清除 baseUrl
    if (oldType != type && type != AIProviderType.custom) {
      await PrefUtil.removeValue(_baseUrlKey);
    }

    await PrefUtil.setValue(_providerTypeKey, type.index);
  }

  /// 获取当前模型
  static String getModel() {
    return PrefUtil.getValue<String>(_modelKey) ?? 'hunyuan-lite';
  }

  /// 设置模型
  static Future<void> setModel(String model) async {
    await PrefUtil.setValue(_modelKey, model);
  }

  /// 获取API Key
  static String? getApiKey() {
    return PrefUtil.getValue<String>(_apiKeyKey);
  }

  /// 设置API Key
  static Future<void> setApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      await PrefUtil.removeValue(_apiKeyKey);
    } else {
      await PrefUtil.setValue(_apiKeyKey, key);
    }
  }

  /// 获取自定义Base URL
  static String? getBaseUrl() {
    return PrefUtil.getValue<String>(_baseUrlKey);
  }

  /// 设置自定义Base URL
  static Future<void> setBaseUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await PrefUtil.removeValue(_baseUrlKey);
    } else {
      await PrefUtil.setValue(_baseUrlKey, url);
    }
  }

  /// 保存自定义模型列表（兼容旧版）
  static Future<void> setCustomModels(List<String> models) async {
    await PrefUtil.setValue(_customModelsKey, jsonEncode(models));
  }

  /// 获取自定义模型列表（兼容旧版）
  static List<String> getCustomModels() {
    final modelsJson = PrefUtil.getValue<String>(_customModelsKey);
    if (modelsJson == null || modelsJson.isEmpty) {
      return ['gpt-4o', 'gpt-3.5-turbo'];
    }
    try {
      final List<dynamic> decoded = jsonDecode(modelsJson);
      return decoded.cast<String>();
    } catch (e) {
      return ['gpt-4o', 'gpt-3.5-turbo'];
    }
  }

  /// 获取所有提供商的自定义模型映射
  static Map<int, List<String>> _getAllProviderModels() {
    final jsonStr = PrefUtil.getValue<String>(_allProviderModelsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return {};
    }
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((key, value) {
        final List<dynamic> models = value as List<dynamic>;
        return MapEntry(int.parse(key), models.cast<String>());
      });
    } catch (e) {
      return {};
    }
  }

  /// 保存所有提供商的自定义模型映射
  static Future<void> _setAllProviderModels(
    Map<int, List<String>> modelsMap,
  ) async {
    final Map<String, dynamic> encoded = modelsMap.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    await PrefUtil.setValue(_allProviderModelsKey, jsonEncode(encoded));
  }

  /// 保存指定提供商的自定义模型列表
  static Future<void> setCustomModelsForProvider(
    AIProviderType type,
    List<String> models,
  ) async {
    final allModels = _getAllProviderModels();
    if (models.isEmpty) {
      allModels.remove(type.index);
    } else {
      allModels[type.index] = models;
    }
    await _setAllProviderModels(allModels);
  }

  /// 获取指定提供商的自定义模型列表
  static List<String> getCustomModelsForProvider(AIProviderType type) {
    final allModels = _getAllProviderModels();
    return allModels[type.index] ?? [];
  }

  /// 保存自定义提供商名称
  static Future<void> setCustomProviderName(String name) async {
    await PrefUtil.setValue(_customProviderNameKey, name);
  }

  /// 获取自定义提供商名称
  static String getCustomProviderName() {
    return PrefUtil.getValue<String>(_customProviderNameKey) ?? '自定义';
  }

  /// 获取当前提供商的配置
  static AIProvider getCurrentProvider() {
    final type = getProviderType();
    AIProvider? provider = AIProviders.getByType(type);

    // 如果是自定义类型，使用保存的自定义配置
    if (type == AIProviderType.custom) {
      final customName = getCustomProviderName();
      final customBaseUrl = getBaseUrl();
      final customModels = getCustomModels();
      provider = AIProvider(
        type: AIProviderType.custom,
        name: customName,
        baseUrl: customBaseUrl ?? 'https://api.openai.com/v1',
        models: customModels,
      );
    }

    if (provider == null) {
      return AIProviders.hunyuan;
    }

    final apiKey = getApiKey();
    final baseUrl = getBaseUrl();

    // 检查是否有自定义模型列表
    final customModels = getCustomModelsForProvider(type);
    final effectiveModels =
        customModels.isNotEmpty ? customModels : provider.models;

    return provider.copyWith(
      apiKey: apiKey,
      baseUrl: (baseUrl != null && baseUrl.isNotEmpty) ? baseUrl : provider.baseUrl,
      models: effectiveModels,
    );
  }

  /// 获取当前模型名称
  static String getCurrentModel() {
    final model = getModel();
    final provider = getCurrentProvider();

    if (provider.models.contains(model)) {
      return model;
    }

    return provider.models.first;
  }

  /// 获取当前模型索引
  static int getCurrentModelIndex() {
    final model = getCurrentModel();
    final provider = getCurrentProvider();
    return provider.models.indexOf(model);
  }

  /// 检查是否配置了API Key
  static bool checkApiKeyConfigured() {
    final type = getProviderType();
    final apiKey = getApiKey();

    // 腾讯混元使用 tencentId 和 tencentKey
    if (type == AIProviderType.hunyuan) {
      final tencentId = PrefUtil.getValue<String>('tencentId');
      final tencentKey = PrefUtil.getValue<String>('tencentKey');
      return (tencentId != null && tencentId.isNotEmpty) &&
             (tencentKey != null && tencentKey.isNotEmpty);
    }

    // 其他提供商使用 api_key
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// 获取腾讯云配置
  static Map<String, String>? getTencentConfig() {
    final id = PrefUtil.getValue<String>('tencentId');
    final key = PrefUtil.getValue<String>('tencentKey');
    if (id == null || key == null) {
      return null;
    }
    return {'id': id, 'key': key};
  }

  /// 从API获取可用模型列表
  static Future<List<String>> fetchModelsFromApi({
    required String baseUrl,
    required String apiKey,
  }) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 15);

      // 规范化 baseUrl
      String normalizedUrl = baseUrl.trim();
      // 移除末尾斜杠
      while (normalizedUrl.endsWith('/')) {
        normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
      }
      // 移除可能的 /chat/completions 后缀
      if (normalizedUrl.endsWith('/chat/completions')) {
        normalizedUrl = normalizedUrl.substring(
          0,
          normalizedUrl.length - '/chat/completions'.length,
        );
      }

      // 构建 models 端点 URL
      final modelsUrl = '$normalizedUrl/models';

      final response = await dio.get(
        modelsUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] is List) {
          final models = (data['data'] as List)
              .map((m) => m['id'] as String?)
              .whereType<String>()
              .toList();
          return models..sort();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 测试API连接
  static Future<ApiTestResult> testApiConnection({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      // 规范化 baseUrl
      String normalizedUrl = baseUrl.trim();
      // 移除末尾斜杠
      while (normalizedUrl.endsWith('/')) {
        normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
      }
      // 移除可能的 /chat/completions 后缀
      if (normalizedUrl.endsWith('/chat/completions')) {
        normalizedUrl = normalizedUrl.substring(
          0,
          normalizedUrl.length - '/chat/completions'.length,
        );
      }

      // 构建完整的 API URL
      final url = '$normalizedUrl/chat/completions';
      debugPrint('测试连接 URL: $url');
      debugPrint('测试模型: $model');

      final response = await dio.post(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'Hi'},
          ],
          'max_tokens': 5,
        },
      );

      debugPrint('响应状态码: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiTestResult(success: true, message: '连接成功！');
      } else {
        return ApiTestResult(
          success: false,
          message: 'HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.type}');
      debugPrint('Response: ${e.response?.data}');
      String errorMsg = '连接失败';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '连接超时，请检查网络';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = '网络连接失败，请检查地址';
      } else if (e.response?.statusCode == 401) {
        errorMsg = 'API密钥无效';
      } else if (e.response?.statusCode == 404) {
        errorMsg = 'API地址或模型不存在';
      } else if (e.response?.statusCode == 400) {
        // 尝试获取更详细的错误信息
        try {
          final data = e.response!.data;
          if (data is Map) {
            if (data['error'] is Map) {
              errorMsg = data['error']['message']?.toString() ?? '请求格式错误';
            } else {
              errorMsg = data['error']?.toString() ?? '请求格式错误';
            }
          }
        } catch (_) {
          errorMsg = '请求格式错误或模型不存在';
        }
      } else if (e.response?.data != null) {
        try {
          final errorData = e.response!.data;
          if (errorData is Map && errorData['error'] != null) {
            final err = errorData['error'];
            if (err is Map && err['message'] != null) {
              errorMsg = err['message'].toString();
            } else {
              errorMsg = err.toString();
            }
          }
        } catch (_) {}
      }
      return ApiTestResult(success: false, message: errorMsg);
    } catch (e) {
      debugPrint('其他错误: $e');
      return ApiTestResult(success: false, message: e.toString());
    }
  }
}

/// API测试结果
class ApiTestResult {
  final bool success;
  final String message;

  ApiTestResult({required this.success, required this.message});
}
