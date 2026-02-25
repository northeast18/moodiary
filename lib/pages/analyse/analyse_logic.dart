import 'dart:convert';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/api/api.dart';
import 'package:moodiary/common/models/ai_provider.dart';
import 'package:moodiary/common/models/hunyuan.dart';
import 'package:moodiary/persistence/isar.dart';
import 'package:moodiary/utils/ai_config_util.dart';
import 'package:moodiary/utils/array_util.dart';
import 'package:moodiary/utils/notice_util.dart';

import 'analyse_state.dart';

class AnalyseLogic extends GetxController {
  final AnalyseState state = AnalyseState();

  @override
  void onReady() async {
    await getMoodAndWeatherByRange(state.dateRange[0], state.dateRange[1]);
    super.onReady();
  }

  //选中两个日期后，查询指定范围内的日记
  Future<void> getMoodAndWeatherByRange(DateTime start, DateTime end) async {
    //清空原有数据
    clearResult();
    //获取数据开始
    state.finished = false;
    update();
    state.moodList = await IsarUtil.getMoodByDateRange(
      start,
      end.subtract(const Duration(days: -1)),
    );

    final weatherList = await IsarUtil.getWeatherByDateRange(
      start,
      end.subtract(const Duration(days: -1)),
    );
    for (final weather in weatherList) {
      if (weather.isNotEmpty) {
        state.weatherList.add(weather.first);
      }
    }
    state.moodMap = ArrayUtil.countList(state.moodList);
    state.weatherMap = ArrayUtil.countList(state.weatherList);
    state.finished = true;
    update();
  }

  void clearResult() {
    state.moodList.clear();
    state.weatherList.clear();
    state.moodMap.clear();
    state.weatherMap.clear();
  }

  //弹出日期选择框
  Future<void> openDatePicker(context) async {
    final result = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarViewMode: CalendarDatePicker2Mode.day,
        calendarType: CalendarDatePicker2Type.range,
        selectableDayPredicate: (date) => date.isBefore(DateTime.now()),
      ),
      dialogSize: const Size(325, 400),
      value: state.dateRange,
      borderRadius: BorderRadius.circular(20.0),
    );
    if (result != null) {
      state.dateRange[0] = result[0]!;
      state.dateRange[1] = result[1]!;
      update();
      getMoodAndWeatherByRange(result[0]!, result[1]!);
    }
  }

  Future<void> getAi() async {
    // 检查API配置
    if (!AIConfigUtil.checkApiKeyConfigured()) {
      final providerType = AIConfigUtil.getProviderType();
      if (providerType == AIProviderType.hunyuan) {
        toast.info(message: '请先在实验室配置腾讯云ID和Key');
      } else {
        toast.info(message: '请先在智能助手中配置API Key');
      }
      return;
    }

    state.reply = '';
    update();

    final providerType = AIConfigUtil.getProviderType();

    final stream = await Api.getAIChat([
      const Message(
        role: 'system',
        content:
            '我会给你一组来自一款日记APP的数据，其中包含了在某一段时间内，日记所记录的心情情况，根据这些数据，分析用户最近的心情状况，并给出合理的建议，心情的值是一个从0.0到1.0的浮点数，从小到大表示心情从坏到好，给你的值是一个Map，其中的Key是心情指数，Value是对应心情指数出现的次数。给出的输出应当是结论，不需要给出分析过程，不需要其他反馈。',
      ),
      Message(role: 'user', content: '心情：${state.moodMap.toString()}'),
    ]);

    if (stream == null) {
      toast.error(message: '无法连接到AI服务');
      return;
    }

    stream.listen((content) {
      if (content != '' && content.contains('data')) {
        try {
          final dataStr = content.split('data: ')[1];

          if (providerType == AIProviderType.hunyuan) {
            final HunyuanResponse result = HunyuanResponse.fromJson(
              jsonDecode(dataStr),
            );
            state.reply += result.choices!.first.delta!.content!;
          } else {
            // OpenAI格式
            final Map<String, dynamic> result = jsonDecode(dataStr);
            final delta = result['choices']?[0]?['delta'];
            if (delta != null && delta['content'] != null) {
              state.reply += delta['content'];
            }
          }
          update();
        } catch (e) {
          // 忽略解析错误
        }
      }
    });
  }
}
