import 'dart:math';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastReadProvider extends GetxController {
  int? _feedLastReadAt;
  int? _messagesLastReadAt;

  int? get feedLastReadAt => _feedLastReadAt;
  int? get messagesLastReadAt => _messagesLastReadAt;

  set feedLastReadAt(int? value) {
    if (value == _feedLastReadAt) return;
    final newValue = max(_feedLastReadAt ?? 0, value ?? 0);
    if (newValue != _feedLastReadAt) {
      _feedLastReadAt = newValue;
      _saveToStorage();
    }
  }

  set messagesLastReadAt(int? value) {
    if (value == _messagesLastReadAt) return;
    final newValue = max(_messagesLastReadAt ?? 0, value ?? 0);
    if (newValue != _messagesLastReadAt) {
      _messagesLastReadAt = newValue;
      _saveToStorage();
    }
  }

  LastReadProvider() {
    _revertFromStorage();
  }

  Future<void> _revertFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('feed_last_read_at')) {
      _feedLastReadAt = prefs.getInt('feed_last_read_at')!;
    }
    if (prefs.containsKey('messages_last_read_at')) {
      _messagesLastReadAt = prefs.getInt('messages_last_read_at');
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_feedLastReadAt != null) {
      prefs.setInt('feed_last_read_at', _feedLastReadAt!);
    }
    if (_messagesLastReadAt != null) {
      prefs.setInt('messages_last_read_at', _messagesLastReadAt!);
    }
  }
}
