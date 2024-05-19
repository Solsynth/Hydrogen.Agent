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
  'heart': ReactInfo(icon: '❤️', attitude: 1),
  'laugh': ReactInfo(icon: '😂', attitude: 1),
  'angry': ReactInfo(icon: '😡', attitude: 2),
  'surprise': ReactInfo(icon: '😲', attitude: 0),
  'party': ReactInfo(icon: '🎉', attitude: 1),
  'wink': ReactInfo(icon: '😉', attitude: 1),
  'scream': ReactInfo(icon: '😱', attitude: 0),
  'sleep': ReactInfo(icon: '😴', attitude: 0),
  'thinking': ReactInfo(icon: '🤔', attitude: 0),
  'blush': ReactInfo(icon: '😊', attitude: 1),
  'cool': ReactInfo(icon: '😎', attitude: 1),
  'frown': ReactInfo(icon: '☹️', attitude: 2),
  'nauseated': ReactInfo(icon: '🤢', attitude: 2),
  'facepalm': ReactInfo(icon: '🤦', attitude: 0),
  'shrug': ReactInfo(icon: '🤷', attitude: 0),
  'joy': ReactInfo(icon: '🤣', attitude: 1),
  'relieved': ReactInfo(icon: '😌', attitude: 0),
  'disappointed': ReactInfo(icon: '😞', attitude: 2),
  'smirk': ReactInfo(icon: '😏', attitude: 1),
  'astonished': ReactInfo(icon: '😮', attitude: 0),
  'hug': ReactInfo(icon: '🤗', attitude: 1),
  'pray': ReactInfo(icon: '🙏', attitude: 1),
};
