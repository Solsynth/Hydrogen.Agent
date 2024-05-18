class ReactInfo {
  final String icon;
  final int attitude;

  ReactInfo({required this.icon, required this.attitude});
}

final Map<String, ReactInfo> reactions = {
  'thumb_up': ReactInfo(icon: '👍', attitude: 1),
  'thumb_down': ReactInfo(icon: '👎', attitude: 2),
  'just_okay': ReactInfo(icon: '😅', attitude: 0),
  'cry': ReactInfo(icon: '😭', attitude: 0),
  'confuse': ReactInfo(icon: '🧐', attitude: 0),
  'retard': ReactInfo(icon: '🤪', attitude: 0),
  'clap': ReactInfo(icon: '👏', attitude: 1),
};
