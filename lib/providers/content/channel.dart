import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/friend_select.dart';
import 'package:uuid/uuid.dart';

class ChannelProvider extends GetxController {
  Future<Response> getChannel(String alias, {String realm = 'global'}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];

    final resp = await client.get('/api/channels/$realm/$alias');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response?> getChannelOngoingCall(String alias,
      {String realm = 'global'}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];

    final resp = await client.get('/api/channels/$realm/$alias/calls/ongoing');
    if (resp.statusCode == 404) {
      return null;
    } else if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> listChannel({String scope = 'global'}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.get('/api/channels/$scope');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> listAvailableChannel({String realm = 'global'}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.get('/api/channels/$realm/me/available');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> createChannel(String scope, dynamic payload) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.post('/api/channels/$scope', payload);
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response?> createDirectChannel(
      BuildContext context, String scope) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final related = await showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) => FriendSelect(
        title: 'channelOrganizeDirectHint'.tr,
      ),
    );
    if (related == null) return null;

    final prof = await auth.getProfile();
    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.post('/api/channels/$scope/dm', {
      'alias': const Uuid().v4().replaceAll('-', '').substring(0, 12),
      'name': 'DM',
      'description':
          'A direct message channel between @${prof.body['name']} and @${related.name}',
      'related_user': related.id,
      'is_encrypted': false,
    });
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> updateChannel(String scope, int id, dynamic payload) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.put('/api/channels/$scope/$id', payload);
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }
}
