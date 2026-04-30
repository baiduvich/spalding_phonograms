import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/phonogram.dart';
import '../providers/phonogram_provider.dart';
import '../services/tts_service.dart';
import 'drill_screen.dart';

class PhonogramsScreen extends StatefulWidget {
  const PhonogramsScreen({super.key});

  @override
  State<PhonogramsScreen> createState() => _PhonogramsScreenState();
}

class _PhonogramsScreenState extends State<PhonogramsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phonograms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline_rounded),
            tooltip: 'Start Drill',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DrillScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<PhonogramProvider>(
          builder: (context, provider, _) {
            final learnedCount = provider.learnedCount;
            final progress = learnedCount / 70.0;

            final phonograms = _query.isEmpty
                ? provider.allPhonograms
                : provider.allPhonograms
                    .where((p) => p.letters.toLowerCase().contains(_query))
                    .toList();

            return Column(
              children: [
                // Streak row
                if (provider.drillStreak > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.md, AppTheme.sm, AppTheme.md, 0),
                    child: Row(
                      children: [
                        const Text(
                          '\u{1F525}',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${provider.drillStreak} day${provider.drillStreak == 1 ? '' : 's'} streak',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.md,
                    AppTheme.sm,
                    AppTheme.md,
                    AppTheme.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$learnedCount / 70 learned',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppTheme.surfaceAlt,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppTheme.md, AppTheme.sm, AppTheme.md, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _query = val.toLowerCase().trim()),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search phonograms...',
                      hintStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textSecondary),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                // Grid or empty state
                Expanded(
                  child: phonograms.isEmpty
                      ? const Center(
                          child: Text(
                            'No phonograms found',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(AppTheme.sm),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: AppTheme.sm,
                            mainAxisSpacing: AppTheme.sm,
                          ),
                          itemCount: phonograms.length,
                          itemBuilder: (context, index) {
                            final phonogram = phonograms[index];
                            final learned = provider.isLearned(phonogram.id);
                            return _PhonogramCard(
                              phonogram: phonogram,
                              isLearned: learned,
                              onTap: () =>
                                  _showDetail(context, phonogram, provider),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    Phonogram phonogram,
    PhonogramProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) {
        return Consumer<PhonogramProvider>(
          builder: (context, prov, _) {
            final isLearned = prov.isLearned(phonogram.id);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: AppTheme.lg,
                right: AppTheme.lg,
                top: AppTheme.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.lg),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          if (phonogram.keywords.isNotEmpty) {
                            TtsService().speak(phonogram.keywords.first);
                          }
                        },
                        child: Text(
                          phonogram.letters,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.xs),
                    Center(
                      child: Text(
                        'Phonogram #${phonogram.id}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.lg),
                    const Text(
                      'Sounds',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppTheme.sm),
                    ...List.generate(phonogram.soundLabels.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.xs),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppTheme.sm),
                            Expanded(
                              child: Text(
                                phonogram.soundLabels[i],
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppTheme.md),
                    const Text(
                      'Keywords',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppTheme.sm),
                    ...List.generate(phonogram.keywords.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.xs),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppTheme.sm),
                            Expanded(
                              child: Text(
                                phonogram.keywords[i],
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.volume_up_rounded,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                              onPressed: () =>
                                  TtsService().speak(phonogram.keywords[i]),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppTheme.xl),
                    SizedBox(
                      width: double.infinity,
                      height: AppTheme.minTouchTarget,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLearned
                              ? AppTheme.surfaceAlt
                              : AppTheme.primary,
                          foregroundColor: AppTheme.textPrimary,
                        ),
                        onPressed: () {
                          prov.toggleLearned(phonogram.id);
                        },
                        child: Text(
                          isLearned ? 'Mark as Unlearned' : 'Mark as Learned',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PhonogramCard extends StatelessWidget {
  final Phonogram phonogram;
  final bool isLearned;
  final VoidCallback onTap;

  const _PhonogramCard({
    required this.phonogram,
    required this.isLearned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isLearned ? AppTheme.surfaceAlt : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isLearned ? AppTheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 6,
              left: 8,
              child: Text(
                '#${phonogram.id}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            if (isLearned)
              const Positioned(
                top: 4,
                right: 6,
                child: Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppTheme.primary,
                ),
              ),
            Center(
              child: Text(
                phonogram.letters,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
