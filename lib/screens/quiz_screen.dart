import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/phonogram.dart';
import '../providers/phonogram_provider.dart';
import '../services/rating_service.dart';

class _Question {
  final Phonogram phonogram;
  final String questionText;
  final String correctAnswer;
  final List<String> options;

  const _Question({
    required this.phonogram,
    required this.questionText,
    required this.correctAnswer,
    required this.options,
  });
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<_Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _quizDone = false;
  static const int _quizLength = 20;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildQuiz();
    });
  }

  void _buildQuiz() {
    debugPrint('[Quiz] Building quiz...');
    final provider = context.read<PhonogramProvider>();
    final all = List<Phonogram>.from(provider.allPhonograms)..shuffle(_random);
    final selected = all.take(_quizLength).toList();
    final quizReversed = provider.quizReversed;
    debugPrint('[Quiz] quizReversed=$quizReversed, selected ${selected.length} phonograms');

    final questions = selected.map((phonogram) {
      final String questionText;
      final String correctAnswer;
      final List<String> wrongPool;

      if (!quizReversed) {
        questionText = phonogram.letters;
        correctAnswer = phonogram.soundLabels.join(', ');
        wrongPool = all
            .where((p) => p.id != phonogram.id)
            .map((p) => p.soundLabels.join(', '))
            .toList()
          ..shuffle(_random);
      } else {
        correctAnswer = phonogram.letters;
        final sound = phonogram.soundLabels[_random.nextInt(phonogram.soundLabels.length)];
        questionText = sound;
        wrongPool = all
            .where((p) => p.id != phonogram.id)
            .map((p) => p.letters)
            .toList()
          ..shuffle(_random);
      }

      final wrongs = <String>[];
      for (final w in wrongPool) {
        if (!wrongs.contains(w) && w != correctAnswer && wrongs.length < 3) {
          wrongs.add(w);
        }
      }

      final opts = [correctAnswer, ...wrongs]..shuffle(_random);

      return _Question(
        phonogram: phonogram,
        questionText: questionText,
        correctAnswer: correctAnswer,
        options: opts,
      );
    }).toList();

    if (!mounted) return;
    debugPrint('[Quiz] Quiz built — ${questions.length} questions ready');
    setState(() {
      _questions = questions;
      _currentIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _quizDone = false;
    });
  }

  void _selectOption(int index) {
    if (_answered) return;
    final question = _questions[_currentIndex];
    final isCorrect = question.options[index] == question.correctAnswer;
    debugPrint('[Quiz] Q${_currentIndex + 1}: selected="${question.options[index]}" correct="${question.correctAnswer}" isCorrect=$isCorrect');

    setState(() {
      _selectedOption = index;
      _answered = true;
      if (isCorrect) _score++;
    });
    debugPrint('[Quiz] Score: $_score / ${_currentIndex + 1}');

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final done = _currentIndex + 1 >= _questions.length;
      if (done) RatingService.onQuizCompleted();
      setState(() {
        if (done) {
          _quizDone = true;
        } else {
          _currentIndex++;
          _selectedOption = null;
          _answered = false;
        }
      });
    });
  }

  Color _buttonColor(int index) {
    if (!_answered) return AppTheme.surface;
    final question = _questions[_currentIndex];
    final isCorrect = question.options[index] == question.correctAnswer;
    if (isCorrect) return AppTheme.success;
    if (index == _selectedOption) return AppTheme.danger;
    return AppTheme.surface;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhonogramProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quiz'),
          ),
          body: SafeArea(
            child: _questions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _quizDone
                    ? _buildEndScreen()
                    : _buildQuizView(),
          ),
        );
      },
    );
  }

  Widget _buildQuizView() {
    final question = _questions[_currentIndex];
    final total = _questions.length;
    final progress = (_currentIndex + 1) / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                'Score: $_score',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppTheme.lg),
          SizedBox(
            height: 80,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                question.questionText,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.xs),
          const Center(
            child: Text(
              'Choose the correct answer',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.md),
          Expanded(
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              itemCount: question.options.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.sm),
              itemBuilder: (context, index) {
                final isCorrect =
                    question.options[index] == question.correctAnswer;
                final isSelected = index == _selectedOption;
                final bgColor = _buttonColor(index);

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: _answered && (isCorrect || isSelected)
                        ? Colors.white
                        : AppTheme.textPrimary,
                    minimumSize:
                        const Size(double.infinity, AppTheme.minTouchTarget),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.md,
                      vertical: AppTheme.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      side: BorderSide(
                        color: _answered && isCorrect
                            ? AppTheme.success
                            : _answered && isSelected
                                ? AppTheme.danger
                                : AppTheme.surfaceAlt,
                        width: 1,
                      ),
                    ),
                  ),
                  onPressed: _answered ? null : () => _selectOption(index),
                  child: Text(
                    question.options[index],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.md),
        ],
      ),
    );
  }

  Widget _buildEndScreen() {
    final pct = (_score / _quizLength * 100).round();
    final emoji = pct >= 80 ? '🎉' : pct >= 60 ? '📚' : '💪';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              '$_score / $_quizLength',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
            const Text(
              'Correct',
              style: TextStyle(
                fontSize: 20,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.xxl),
            SizedBox(
              width: double.infinity,
              height: AppTheme.minTouchTarget,
              child: ElevatedButton(
                onPressed: _buildQuiz,
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
