import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exceptions/unauthorized.dart';
import 'package:solian/models/daily_sign.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';

class DailySignProvider extends GetxController {
  Future<List<DailySignRecord>> listLastRecord(int take) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('id');

    final resp = await client.get('/daily?take=$take');
    if (resp.statusCode != 200 && resp.statusCode != 404) {
      throw RequestException(resp);
    } else if (resp.statusCode == 404) {
      return List.empty();
    }

    final result = PaginationResult.fromJson(resp.body);

    return List.from(
      result.data?.map((x) => DailySignRecord.fromJson(x)) ?? [],
    );
  }

  Future<DailySignRecord?> getToday() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('id');

    final resp = await client.get('/daily/today');
    if (resp.statusCode != 200 && resp.statusCode != 404) {
      throw RequestException(resp);
    } else if (resp.statusCode == 404) {
      return null;
    }

    return DailySignRecord.fromJson(resp.body);
  }

  Future<DailySignRecord> signToday() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('id');

    final resp = await client.post('/daily', {});
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return DailySignRecord.fromJson(resp.body);
  }
}
