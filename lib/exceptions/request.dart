import 'package:get/get.dart';

class RequestException implements Exception {
  final Response data;

  const RequestException(this.data);

  @override
  String toString() => 'Request failed ${data.statusCode}: ${data.bodyString}';
}
