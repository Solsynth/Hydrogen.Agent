import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExperienceProvider extends GetxController {
  static List<int> experienceToLevelRequirements = [
    0, // Level 0
    1000, // Level 1
    4000, // Level 2
    9000, // Level 3
    16000, // Level 4
    25000, // Level 5
    36000, // Level 6
    49000, // Level 7
    64000, // Level 8
    81000, // Level 9
    100000, // Level 10
    121000, // Level 11
    144000, // Level 12
    368000 // Level 13
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
    return (experience - exp).abs() / (exp - nextExp).abs();
  }

  static String calcLevelUpProgressLevel(int experience) {
    final exp = experienceToLevelRequirements.reversed
        .firstWhere((x) => x <= experience);
    final idx = experienceToLevelRequirements.indexOf(exp);
    if (idx + 1 >= experienceToLevelRequirements.length) return 'Infinity';
    final nextExp = exp - experienceToLevelRequirements[idx + 1];
    final formatter =
        NumberFormat.compactCurrency(symbol: '', decimalDigits: 1);
    return '${formatter.format((exp - experience).abs())}/${formatter.format(nextExp.abs())}';
  }
}
