const serviceUrls = {
  'passport': 'https://id.solsynth.dev',
  'interactive': 'https://co.solsynth.dev',
  'messaging': 'http://192.168.50.83:8447' // 'https://im.solsynth.dev'
};

Uri getRequestUri(String service, String path) {
  final baseUrl = serviceUrls[service];
  return Uri.parse(baseUrl! + path);
}
