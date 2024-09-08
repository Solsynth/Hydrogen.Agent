import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExperienceProvider extends GetxController {
  static List<int> experienceToLevelRequirements = [
    0, // Level 0
    100, // Level 1
    400, // Level 2
    900, // Level 3
    1600, // Level 4
    2500, // Level 5
    3600, // Level 6
    4900, // Level 7
    6400, // Level 8
    8100, // Level 9
    10000, // Level 10
    12100, // Level 11
    14400, // Level 12
    36800 // Level 13
  ];

  static List<String> levelLabelMapping =
      List.generate(experienceToLevelRequirements.length, (x) => 'userLevel$x');

  static (int level, String label) getLevelFromExp(int experience) {
    final exp = experienceToLevelRequirements.reversed
        .firstWhere((x) => x <= experience);
    final idx = experienceToLevelRequirements.indexOf(exp);
    return (idx, levelLabelMapping[idx]);
  }

  static double calcLevelUpProgress(int experience) {
    final exp = experienceToLevelRequirements.reversed
        .firstWhere((x) => x <= experience);
    final idx = experienceToLevelRequirements.indexOf(exp);
    if (idx + 1 >= experienceToLevelRequirements.length) return 1;
    final nextExp = experienceToLevelRequirements[idx + 1];
    return exp / nextExp;
  }

  static String calcLevelUpProgressLevel(int experience) {
    final exp = experienceToLevelRequirements.reversed
        .firstWhere((x) => x <= experience);
    final idx = experienceToLevelRequirements.indexOf(exp);
    if (idx + 1 >= experienceToLevelRequirements.length) return 'Infinity';
    final nextExp = experienceToLevelRequirements[idx + 1];
    final formatter =
        NumberFormat.compactCurrency(symbol: '', decimalDigits: 1);
    return '${formatter.format(exp)}/${formatter.format(nextExp)}';
  }
}
