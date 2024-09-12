import 'package:get/get.dart';
import 'package:solian/models/realm.dart';

class NavigationStateProvider extends GetxController {
  final Rx<Realm?> focusedRealm = Rx(null);
}
