import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/phonograms_data.dart';
import '../models/phonogram.dart';

class PhonogramProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  Set<int> _learnedIds = {};
  bool _quizReversed = false;
  int _drillStreak = 0;
  String _lastDrillDate = '';

  PhonogramProvider(this._prefs) {
    _load();
  }

  void _load() {
    final learned = _prefs.getStringList('learned_ids') ?? [];
    _learnedIds =
        learned.map((e) => int.tryParse(e) ?? -1).where((e) => e != -1).toSet();
    _quizReversed = _prefs.getBool('quiz_reversed') ?? false;
    _drillStreak = _prefs.getInt('drill_streak') ?? 0;
    _lastDrillDate = _prefs.getString('last_drill_date') ?? '';
    debugPrint('[Provider] Loaded — learned: ${_learnedIds.length}, streak: $_drillStreak, lastDrill: "$_lastDrillDate", quizReversed: $_quizReversed');
  }

  List<Phonogram> get allPhonograms => kPhonograms;
  Set<int> get learnedIds => _learnedIds;
  bool get quizReversed => _quizReversed;
  int get learnedCount => _learnedIds.length;
  int get drillStreak => _drillStreak;

  bool isLearned(int id) => _learnedIds.contains(id);

  void toggleLearned(int id) {
    final wasLearned = _learnedIds.contains(id);
    if (wasLearned) {
      _learnedIds.remove(id);
    } else {
      _learnedIds.add(id);
    }
    debugPrint('[Provider] toggleLearned(id=$id) — was: $wasLearned → now: ${!wasLearned} | total learned: ${_learnedIds.length}');
    _prefs.setStringList(
        'learned_ids', _learnedIds.map((e) => e.toString()).toList());
    notifyListeners();
  }

  void resetProgress() {
    debugPrint('[Provider] resetProgress() — clearing ${_learnedIds.length} learned IDs + streak');
    _learnedIds.clear();
    _drillStreak = 0;
    _lastDrillDate = '';
    _prefs.setStringList('learned_ids', []);
    _prefs.setInt('drill_streak', 0);
    _prefs.setString('last_drill_date', '');
    notifyListeners();
  }

  void setQuizReversed(bool value) {
    debugPrint('[Provider] setQuizReversed($value)');
    _quizReversed = value;
    _prefs.setBool('quiz_reversed', value);
    notifyListeners();
  }

  void recordDrillSession() {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    debugPrint('[Provider] recordDrillSession() — today: $todayStr, lastDrill: "$_lastDrillDate", currentStreak: $_drillStreak');

    if (_lastDrillDate == todayStr) {
      debugPrint('[Provider] Already drilled today — streak unchanged');
      return;
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (_lastDrillDate == yesterdayStr) {
      _drillStreak += 1;
      debugPrint('[Provider] Consecutive day — streak incremented to $_drillStreak');
    } else {
      _drillStreak = 1;
      debugPrint('[Provider] Streak broken (last was "$_lastDrillDate") — reset to 1');
    }

    _lastDrillDate = todayStr;
    _prefs.setInt('drill_streak', _drillStreak);
    _prefs.setString('last_drill_date', _lastDrillDate);
    notifyListeners();
  }
}
