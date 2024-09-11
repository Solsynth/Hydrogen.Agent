import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

class AppTranslations extends Translations {
  static const List<String> supportedLocales = ['zh_cn', 'en_us'];

  final Map<String, Map<String, String>> messages = {};

  static Future<void> init() async {
    final AppTranslations inst = Get.find();
    inst.messages.clear();
    for (final locale in supportedLocales) {
      inst.messages[locale] = jsonDecode(
        await rootBundle.loadString('assets/locales/$locale.json'),
      )
          .map((key, value) => MapEntry(key, value.toString()))
          .cast<String, String>();
    }
  }

  @override
  Map<String, Map<String, String>> get keys => messages;
}
