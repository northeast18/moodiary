/// AI提供商类型
enum AIProviderType {
  hunyuan,
  openai,
  zhipu,
  deepseek,
  siliconflow,
  nvidia,
  gemini,
  minimax,
  moonshot,
  volcengine,
  qwen,
  baichuan,
  custom,
}

/// AI提供商配置
class AIProvider {
  const AIProvider({
    required this.type,
    required this.name,
    required this.baseUrl,
    this.models = const [],
    this.apiKey,
    this.stream = true,
  });

  final AIProviderType type;
  final String name;
  final String baseUrl;
  final List<String> models;
  final String? apiKey;
  final bool stream;

  AIProvider copyWith({
    AIProviderType? type,
    String? name,
    String? baseUrl,
    List<String>? models,
    String? apiKey,
    bool? stream,
  }) {
    return AIProvider(
      type: type ?? this.type,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      models: models ?? this.models,
      apiKey: apiKey ?? this.apiKey,
      stream: stream ?? this.stream,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'name': name,
      'baseUrl': baseUrl,
      'models': models,
      'stream': stream,
    };
  }

  static AIProvider fromJson(Map<String, dynamic> json) {
    return AIProvider(
      type: AIProviderType.values[json['type'] as int],
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      models: (json['models'] as List<dynamic>).cast<String>(),
      stream: json['stream'] as bool? ?? true,
    );
  }
}

/// 预设的AI提供商
class AIProviders {
  static const hunyuan = AIProvider(
    type: AIProviderType.hunyuan,
    name: '腾讯混元',
    baseUrl: 'https://hunyuan.tencentcloudapi.com',
    models: ['hunyuan-lite', 'hunyuan-standard', 'hunyuan-pro', 'hunyuan-turbo'],
    stream: true,
  );

  static const openai = AIProvider(
    type: AIProviderType.openai,
    name: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    models: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo'],
    stream: true,
  );

  static const zhipu = AIProvider(
    type: AIProviderType.zhipu,
    name: '智谱AI',
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    models: ['glm-4-plus', 'glm-4', 'glm-4-air', 'glm-4-flash'],
    stream: true,
  );

  static const deepseek = AIProvider(
    type: AIProviderType.deepseek,
    name: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
    models: ['deepseek-chat', 'deepseek-coder'],
    stream: true,
  );

  static const siliconflow = AIProvider(
    type: AIProviderType.siliconflow,
    name: '硅基流动',
    baseUrl: 'https://api.siliconflow.cn/v1',
    models: [
      'deepseek-ai/DeepSeek-V3',
      'Qwen/Qwen2.5-72B-Instruct',
      'meta-llama/Llama-3.1-70B-Instruct',
    ],
    stream: true,
  );

  static const nvidia = AIProvider(
    type: AIProviderType.nvidia,
    name: '英伟达 NIM',
    baseUrl: 'https://integrate.api.nvidia.com/v1',
    models: [
      'meta/llama-3.3-70b-instruct',
      'meta/llama-3.1-405b-instruct',
      'meta/llama-3.1-70b-instruct',
      'meta/llama-3.1-8b-instruct',
      'nvidia/llama-3.1-nemotron-70b-instruct',
      'mistralai/mistral-large',
      'google/gemma-2-27b-it',
    ],
    stream: true,
  );

  static const gemini = AIProvider(
    type: AIProviderType.gemini,
    name: 'Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    models: ['gemini-2.0-flash-exp', 'gemini-1.5-pro', 'gemini-1.5-flash'],
    stream: true,
  );

  static const minimax = AIProvider(
    type: AIProviderType.minimax,
    name: 'MiniMax',
    baseUrl: 'https://api.minimax.chat/v1',
    models: ['abab6.5s-chat', 'abab6.5-chat'],
    stream: true,
  );

  static const moonshot = AIProvider(
    type: AIProviderType.moonshot,
    name: '月之暗面',
    baseUrl: 'https://api.moonshot.cn/v1',
    models: ['moonshot-v1-8k', 'moonshot-v1-32k', 'moonshot-v1-128k'],
    stream: true,
  );

  static const volcengine = AIProvider(
    type: AIProviderType.volcengine,
    name: '火山引擎',
    baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
    models: ['ep-20241105115448-wcgjd', 'doubao-pro-32k', 'doubao-pro-256k'],
    stream: true,
  );

  static const qwen = AIProvider(
    type: AIProviderType.qwen,
    name: '阿里千问',
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    models: ['qwen-max', 'qwen-plus', 'qwen-turbo', 'qwen-long'],
    stream: true,
  );

  static const baichuan = AIProvider(
    type: AIProviderType.baichuan,
    name: '百川智能',
    baseUrl: 'https://api.baichuan-ai.com/v1',
    models: ['Baichuan4', 'Baichuan3-Turbo', 'Baichuan2-Turbo'],
    stream: true,
  );

  static const custom = AIProvider(
    type: AIProviderType.custom,
    name: '自定义',
    baseUrl: 'https://api.openai.com/v1',
    models: ['gpt-4o', 'gpt-3.5-turbo'],
    stream: true,
  );

  static const List<AIProvider> defaultProviders = [
    hunyuan,
    openai,
    zhipu,
    deepseek,
    siliconflow,
    nvidia,
    gemini,
    minimax,
    moonshot,
    volcengine,
    qwen,
    baichuan,
    custom,
  ];

  static AIProvider? getByType(AIProviderType type) {
    for (final provider in defaultProviders) {
      if (provider.type == type) {
        return provider;
      }
    }
    return null;
  }

  static String getTypeName(AIProviderType type, {String? customName}) {
    switch (type) {
      case AIProviderType.hunyuan:
        return '腾讯混元';
      case AIProviderType.openai:
        return 'OpenAI';
      case AIProviderType.zhipu:
        return '智谱AI';
      case AIProviderType.deepseek:
        return 'DeepSeek';
      case AIProviderType.siliconflow:
        return '硅基流动';
      case AIProviderType.nvidia:
        return '英伟达';
      case AIProviderType.gemini:
        return 'Gemini';
      case AIProviderType.minimax:
        return 'MiniMax';
      case AIProviderType.moonshot:
        return '月之暗面';
      case AIProviderType.volcengine:
        return '火山引擎';
      case AIProviderType.qwen:
        return '阿里千问';
      case AIProviderType.baichuan:
        return '百川智能';
      case AIProviderType.custom:
        // 返回保存的自定义名称或默认值
        return customName ?? '自定义';
    }
  }
}
