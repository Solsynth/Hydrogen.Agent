import 'package:get/get.dart';

class SolianMessages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'page': 'Page',
          'home': 'Home',
          'account': 'Account',
          'matureContent': 'Mature Content',
          'matureContentCaption': 'The content is rated and may not suitable for everyone to view'
        },
        'zh_CN': {
          'page': '页面',
          'home': '首页',
          'account': '账号',
          'matureContent': '成人内容',
          'matureContentCaption': '该内容可能会对您的社会关系产生影响，请确认四下环境后再查看'
        }
      };
}
