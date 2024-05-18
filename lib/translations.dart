import 'package:get/get.dart';

class SolianMessages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'page': 'Page',
          'home': 'Home',
          'account': 'Account',
        },
        'zh_CN': {
          'page': '页面',
          'home': '首页',
          'account': '账号',
        }
      };
}
