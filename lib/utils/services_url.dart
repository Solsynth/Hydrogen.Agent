const serviceUrls = {
  'passport': 'https://id.solsynth.dev',
  'interactive': 'https://co.solsynth.dev',
  'messaging': 'https://im.solsynth.dev'
};

Uri getRequestUri(String service, String path) {
  final baseUrl = serviceUrls[service];
  return Uri.parse(baseUrl! + path);
}
