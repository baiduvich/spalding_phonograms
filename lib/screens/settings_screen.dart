import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../providers/phonogram_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = 'Phonograms v${info.version}';
    });
  }

  Future<void> _rateApp() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      await inAppReview.openStoreListing();
    }
  }

  Future<void> _contactUs() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'baid.marouane1@gmail.com',
      query: 'subject=Phonograms App Feedback',
    );
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client.')),
        );
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(
      'https://sites.google.com/view/odtconverterreader/home',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open privacy policy.')),
        );
      }
    }
  }

  void _showResetDialog(PhonogramProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Reset Progress',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will clear all your learned phonograms. Are you sure?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.resetProgress();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress reset.')),
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhonogramProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: SafeArea(
            child: ListView(
              children: [
                const SizedBox(height: AppTheme.md),
                _sectionHeader('Study'),
                SwitchListTile(
                  title: const Text(
                    'Quiz Mode: Sound → Phonogram',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    'Show a sound, pick the phonogram letters',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  value: provider.quizReversed,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (val) => provider.setQuizReversed(val),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.refresh,
                    color: AppTheme.danger,
                  ),
                  title: const Text(
                    'Reset Progress',
                    style: TextStyle(
                      color: AppTheme.danger,
                      fontSize: 16,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () => _showResetDialog(provider),
                ),
                const Divider(color: AppTheme.divider, height: AppTheme.lg),
                _sectionHeader('Support'),
                ListTile(
                  leading: const Icon(
                    Icons.star_outline,
                    color: AppTheme.textSecondary,
                  ),
                  title: const Text(
                    'Rate App',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: _rateApp,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.mail_outline,
                    color: AppTheme.textSecondary,
                  ),
                  title: const Text(
                    'Contact Us',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: _contactUs,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.shield_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  title: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: _openPrivacyPolicy,
                ),
                const Divider(color: AppTheme.divider, height: AppTheme.lg),
                const SizedBox(height: AppTheme.xl),
                if (_version.isNotEmpty)
                  Center(
                    child: Text(
                      _version,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: AppTheme.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.md,
        vertical: AppTheme.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
