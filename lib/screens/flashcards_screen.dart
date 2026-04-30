import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/phonogram.dart';
import '../providers/phonogram_provider.dart';
import '../services/tts_service.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showUnlearnedOnly = false;
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

  List<Phonogram> _buildDeck(PhonogramProvider provider) {
    if (_showUnlearnedOnly) {
      return provider.allPhonograms
          .where((p) => !provider.isLearned(p.id))
          .toList();
    }
    return provider.allPhonograms;
  }

  void _flipCard(Phonogram phonogram) {
    if (_isFlipped) {
      _controller.reverse();
      setState(() {
        _isFlipped = false;
      });
    } else {
      _controller.forward();
      setState(() {
        _isFlipped = true;
      });
      // Auto-speak first keyword when flipping to back
      if (phonogram.keywords.isNotEmpty) {
        TtsService().speak(phonogram.keywords.first);
      }
    }
  }

  void _resetFlip() {
    _controller.reset();
    setState(() {
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhonogramProvider>(
      builder: (context, provider, _) {
        final deck = _buildDeck(provider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Flashcards'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showUnlearnedOnly = !_showUnlearnedOnly;
                    _currentIndex = 0;
                    _resetFlip();
                  });
                },
                child: Text(
                  _showUnlearnedOnly ? 'Unlearned' : 'All',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: deck.isEmpty
                ? _buildEmptyState()
                : _currentIndex >= deck.length
                    ? _buildCompletionScreen(deck)
                    : _buildStudyView(context, deck, provider),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppTheme.success),
            SizedBox(height: AppTheme.md),
            Text(
              'No cards to study!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.sm),
            Text(
              'Switch to "All" to study all phonograms.',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(List<Phonogram> deck) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Deck Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'You went through ${deck.length} cards.',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.xl),
            SizedBox(
              width: double.infinity,
              height: AppTheme.minTouchTarget,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _resetFlip();
                  });
                },
                child: const Text('Restart'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyView(
    BuildContext context,
    List<Phonogram> deck,
    PhonogramProvider provider,
  ) {
    final phonogram = deck[_currentIndex];
    final cardCount = deck.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.sm),
          Text(
            'Card ${_currentIndex + 1} of $cardCount',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.md),
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => _flipCard(phonogram),
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
                            ? _buildCardFront(phonogram)
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi),
                                child: _buildCardBack(phonogram),
                              ),
                      );
                    },
                  ),
                ),
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
                      if (phonogram.keywords.isNotEmpty) {
                        TtsService().speak(phonogram.keywords.first);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.md),
          const Text(
            'Tap card to flip',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.md),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppTheme.minTouchTarget,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.danger),
                      foregroundColor: AppTheme.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    onPressed: () {
                      if (provider.isLearned(phonogram.id)) {
                        provider.toggleLearned(phonogram.id);
                      }
                      _resetFlip();
                      setState(() {
                        _currentIndex = _currentIndex + 1;
                      });
                    },
                    child: const Text(
                      'Still Learning',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: SizedBox(
                  height: AppTheme.minTouchTarget,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    onPressed: () {
                      if (!provider.isLearned(phonogram.id)) {
                        provider.toggleLearned(phonogram.id);
                      }
                      _resetFlip();
                      setState(() {
                        _currentIndex = _currentIndex + 1;
                      });
                    },
                    child: const Text(
                      'Learned ✓',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),
        ],
      ),
    );
  }

  Widget _buildCardFront(Phonogram phonogram) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.surfaceAlt, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            phonogram.letters,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          const Text(
            'tap to flip',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Phonogram phonogram) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.primary, width: 1),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                phonogram.letters,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            const Text(
              'SOUNDS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            ...phonogram.soundLabels.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.xs),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.volume_up_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: AppTheme.xs),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: AppTheme.md),
            const Text(
              'KEYWORDS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            ...phonogram.keywords.map((k) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.xs),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.label_outline_rounded,
                        size: 14,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: AppTheme.xs),
                      Expanded(
                        child: Text(
                          k,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
