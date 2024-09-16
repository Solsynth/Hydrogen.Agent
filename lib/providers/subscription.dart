import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exceptions/unauthorized.dart';
import 'package:solian/models/subscription.dart';
import 'package:solian/providers/auth.dart';

class SubscriptionProvider extends GetxController {
  Future<Subscription?> getSubscriptionOnUser(int userId) async {
    final auth = Get.find<AuthProvider>();
    if (!auth.isAuthorized.value) throw const UnauthorizedException();

    final client = await auth.configureClient('co');
    final resp = await client.get('/subscriptions/users/$userId');
    if (resp.statusCode == 404) {
      return null;
    } else if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return Subscription.fromJson(resp.body);
  }

  Future<Subscription> subscribeToUser(int userId) async {
    final auth = Get.find<AuthProvider>();
    if (!auth.isAuthorized.value) throw const UnauthorizedException();

    final client = await auth.configureClient('co');
    final resp = await client.post('/subscriptions/users/$userId', {});
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return Subscription.fromJson(resp.body);
  }

  Future<void> unsubscribeFromUser(int userId) async {
    final auth = Get.find<AuthProvider>();
    if (!auth.isAuthorized.value) throw const UnauthorizedException();

    final client = await auth.configureClient('co');
    final resp = await client.delete('/subscriptions/users/$userId');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }
  }
}
