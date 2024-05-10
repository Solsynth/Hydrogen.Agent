import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solian/utils/services_url.dart';

class HttpClient extends http.BaseClient {
  final bool isUnauthorizedRetry;
  final Future<String> Function()? onUnauthorizedRetry;
  final Function(String atk, String rtk)? onTokenRefreshed;

  final _client = http.Client();

  HttpClient({
    this.isUnauthorizedRetry = true,
    this.onUnauthorizedRetry,
    this.onTokenRefreshed,
    String? defaultToken,
    String? defaultRefreshToken,
  }) {
    currentToken = defaultToken;
    currentRefreshToken = defaultRefreshToken;
  }

  String? currentToken;
  String? currentRefreshToken;

  Future<String> refreshToken(String token) async {
    final res = await _client.post(
      getRequestUri('passport', '/api/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': token, 'grant_type': 'refresh_token'}),
    );
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      throw Exception('An error occurred when trying refresh token: $message');
    }
    final result = jsonDecode(utf8.decode(res.bodyBytes));
    currentToken = result['access_token'];
    currentRefreshToken = result['refresh_token'];
    if (onTokenRefreshed != null) {
      onTokenRefreshed!(currentToken!, currentRefreshToken!);
    }
    return currentToken!;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Authorization'] = 'Bearer $currentToken';

    final res = await _client.send(request);
    if (res.statusCode == 401 && currentToken != null && isUnauthorizedRetry) {
      if (onUnauthorizedRetry != null) {
        currentToken = await onUnauthorizedRetry!();
      } else if (currentRefreshToken != null) {
        currentToken = await refreshToken(currentRefreshToken!);
      } else {
        final result = await http.Response.fromStream(res);
        throw Exception(utf8.decode(result.bodyBytes));
      }

      http.BaseRequest newRequest;
      if (request is http.Request) {
        newRequest = http.Request(request.method, request.url)
          ..encoding = request.encoding
          ..bodyBytes = request.bodyBytes;
      } else if (request is http.MultipartRequest) {
        newRequest = http.MultipartRequest(request.method, request.url)
          ..fields.addAll(request.fields)
          ..files.addAll(request.files);
      } else {
        throw Exception('unsupported request type to auto retry');
      }

      newRequest
        ..persistentConnection = request.persistentConnection
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..headers.addAll(request.headers)
        ..headers['Authorization'] = 'Bearer $currentToken';

      return await _client.send(newRequest);
    }

    return res;
  }
}
