abstract class ServiceFinder {
  static const bool devFlag = true;

  static Map<String, String> services = {
    'paperclip': devFlag ? 'http://localhost:8443' : 'https://usercontent.solsynth.dev',
    'passport': devFlag ? 'http://localhost:8444' : 'https://id.solsynth.dev',
    'interactive': devFlag ? 'http://localhost:8445' : 'https://co.solsynth.dev',
    'messaging': devFlag ? 'http://localhost:8446' : 'https://im.solsynth.dev',
  };
}