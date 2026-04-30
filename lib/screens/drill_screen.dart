import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/phonogram_provider.dart';
import '../services/rating_service.dart';
import '../services/tts_service.dart';

class DrillScreen extends StatefulWidget {
  const DrillScreen({super.key});

  @override
  State<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<DrillScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      debugPrint('[Drill] Flipping card back to front (card ${_currentIndex + 1})');
      _controller.reverse();
      setState(() => _isFlipped = false);
    } else {
      debugPrint('[Drill] Flipping card to back (card ${_currentIndex + 1})');
      _controller.forward();
      setState(() => _isFlipped = true);
    }
  }

  void _goNext(PhonogramProvider provider) {
    final total = provider.allPhonograms.length;
    debugPrint('[Drill] Next — currently at ${_currentIndex + 1}/$total');
    if (_currentIndex + 1 >= total) {
      debugPrint('[Drill] Reached end — recording session & showing completion');
      provider.recordDrillSession();
      RatingService.onDrillCompleted();
      _showCompletionDialog(provider);
    } else {
      _controller.reset();
      setState(() {
        _isFlipped = false;
        _currentIndex++;
      });
      debugPrint('[Drill] Advanced to card ${_currentIndex + 1}/$total');
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      debugPrint('[Drill] Previous — going from ${_currentIndex + 1} to $_currentIndex');
      _controller.reset();
      setState(() {
        _isFlipped = false;
        _currentIndex--;
      });
    }
  }

  void _showCompletionDialog(PhonogramProvider provider) {
    final drillNav = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Drill Complete! \u{1F389}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.sm),
              const Text(
                'You reviewed all 70 phonograms',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.lg),
              SizedBox(
                width: double.infinity,
                height: AppTheme.minTouchTarget,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _controller.reset();
                    setState(() {
                      _isFlipped = false;
                      _currentIndex = 0;
                    });
                  },
                  child: const Text('Drill Again'),
                ),
              ),
              const SizedBox(height: AppTheme.sm),
              SizedBox(
                width: double.infinity,
                height: AppTheme.minTouchTarget,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.surfaceAlt),
                    foregroundColor: AppTheme.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    drillNav.pop();
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhonogramProvider>(
      builder: (context, provider, _) {
        final phonograms = provider.allPhonograms;
        final total = phonograms.length;
        final phonogram = phonograms[_currentIndex];
        final progress = (_currentIndex + 1) / total;
        final firstKeyword =
            phonogram.keywords.isNotEmpty ? phonogram.keywords.first : '';

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Drill'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.sm),
                  Text(
                    '${_currentIndex + 1} / $total',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.surfaceAlt,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: AppTheme.md),
                  // Card fills all remaining space
                  Expanded(
                    child: GestureDetector(
                      onTap: _flipCard,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final angle = _animation.value;
                          final isFront = angle <= pi / 2;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: isFront
                                ? _buildCardFront(phonogram.letters)
                                : Transform(
                                    alignment: Alignment.center,
                                    transform:
                                        Matrix4.identity()..rotateY(pi),
                                    child: _buildCardBack(
                                      phonogram.letters,
                                      phonogram.soundLabels,
                                      phonogram.keywords,
                                      firstKeyword,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.lg),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppTheme.surfaceAlt),
                              foregroundColor: AppTheme.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd),
                              ),
                            ),
                            onPressed: _currentIndex > 0 ? _goPrev : null,
                            child: const Text(
                              '← Previous',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.sm),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd),
                              ),
                            ),
                            onPressed: () => _goNext(provider),
                            child: const Text(
                              'Next →',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardFront(String letters) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            letters,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          const Text(
            'Tap to reveal sounds',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(
    String letters,
    List<String> soundLabels,
    List<String> keywords,
    String firstKeyword,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(
                Icons.volume_up_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
              onPressed: () {
                if (firstKeyword.isNotEmpty) {
                  TtsService().speak(firstKeyword);
                }
              },
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 52,
              left: AppTheme.lg,
              right: AppTheme.lg,
              bottom: AppTheme.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    letters,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.md),
                ...soundLabels.map((label) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.sm,
                          vertical: AppTheme.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: AppTheme.sm),
                ...keywords.map((kw) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.xs),
                      child: Text(
                        kw,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
