import 'package:get/get.dart';
import 'package:moodiary/common/models/ai_provider.dart';
import 'package:moodiary/common/models/hunyuan.dart';
import 'package:moodiary/common/values/keyboard_state.dart';

class AssistantState {
  //对话上下文
  late Map<DateTime, Message> messages;

  //AI提供商类型
  late Rx<AIProviderType> providerType;

  //模型版本
  late RxInt modelVersion;

  late KeyboardState keyboardState;

  late int totalToken;

  // 显示配置对话框标志
  late RxBool showConfigDialog;

  AssistantState() {
    messages = {};

    providerType = (AIProviderType.hunyuan).obs;
    modelVersion = 0.obs;
    keyboardState = KeyboardState.closed;
    showConfigDialog = false.obs;

    ///Initialize variables
  }
}
