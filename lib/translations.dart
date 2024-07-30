import 'package:get/get.dart';
import 'package:solian/translations/en_us.dart';
import 'package:solian/translations/zh_cn.dart';

class SolianMessages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': i18nEnglish,
        'zh_CN': i18nSimplifiedChinese,
      };
}
