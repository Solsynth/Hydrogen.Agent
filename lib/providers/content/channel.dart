import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exceptions/unauthorized.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/widgets/account/relative_select.dart';
import 'package:uuid/uuid.dart';

class ChannelProvider extends GetxController {
  RxBool isLoading = false.obs;

  Future<Response> getChannel(String alias, {String realm = 'global'}) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('messaging');

    final resp = await client.get('/channels/$realm/$alias');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> getMyChannelProfile(String alias,
      {String realm = 'global'}) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('messaging');

    final resp = await client.get('/channels/$realm/$alias/me');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response?> getChannelOngoingCall(String alias,
      {String realm = 'global'}) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('messaging');

    final resp = await client.get('/channels/$realm/$alias/calls/ongoing');
    if (resp.statusCode == 404) {
      return null;
    } else if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> listChannel({String scope = 'global'}) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('messaging');

    final resp = await client.get('/channels/$scope');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<List<Channel>> listAvailableChannel({
    String scope = 'global',
    bool isDirect = false,
  }) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('messaging');

    final resp =
        await client.get('/channels/$scope/me/available?direct=$isDirect');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return List.from(resp.body.map((x) => Channel.fromJson(x)));
  }

  Future<Response> createChannel(String scope, dynamic payload) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('messaging');

    final resp = await client.post('/channels/$scope', payload);
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response?> createDirectChannel(
      BuildContext context, String scope) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final related = await showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) => RelativeSelector(
        title: 'channelOrganizeDirectHint'.tr,
      ),
    );
    if (related == null) return null;

    final prof = auth.userProfile.value!;
    final client = await auth.configureClient('messaging');

    final resp = await client.post('/channels/$scope/dm', {
      'alias': const Uuid().v4().replaceAll('-', '').substring(0, 12),
      'name': 'DM',
      'description':
          'A direct message channel between @${prof['name']} and @${related.name}',
      'related_user': related.id,
      'is_encrypted': false,
    });
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> updateChannel(String scope, int id, dynamic payload) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('messaging');

    final resp = await client.put('/channels/$scope/$id', payload);
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }
}
