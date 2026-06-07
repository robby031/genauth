import 'package:flutter/material.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/screens/lock_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.fromDrawer = false});

  final bool fromDrawer;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await StorageService.instance.setOnboardingCompleted(true);
    if (!mounted) return;
    if (widget.fromDrawer) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LockScreen()),
    );
  }

  void _nextPage(int lastIndex) {
    if (_currentPage == lastIndex) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.fromDrawer
        ? [
            _OnboardingData(
              title: context.l10n.onboardingGuideTitle1,
              description: context.l10n.onboardingGuideDesc1,
              icon: Icons.qr_code_2_outlined,
            ),
            _OnboardingData(
              title: context.l10n.onboardingGuideTitle2,
              description: context.l10n.onboardingGuideDesc2,
              icon: Icons.manage_search_outlined,
            ),
            _OnboardingData(
              title: context.l10n.onboardingGuideTitle3,
              description: context.l10n.onboardingGuideDesc3,
              icon: Icons.shield_outlined,
            ),
          ]
        : [
            _OnboardingData(
              title: context.l10n.onboardingTitle1,
              description: context.l10n.onboardingDesc1,
              icon: Icons.security_outlined,
            ),
            _OnboardingData(
              title: context.l10n.onboardingTitle2,
              description: context.l10n.onboardingDesc2,
              icon: Icons.qr_code_scanner,
            ),
            _OnboardingData(
              title: context.l10n.onboardingTitle3,
              description: context.l10n.onboardingDesc3,
              icon: Icons.lock_person_outlined,
            ),
          ];

    final scheme = Theme.of(context).colorScheme;
    final isLast = _currentPage == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    widget.fromDrawer ? context.l10n.cancel : context.l10n.skip,
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final item = pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            item.icon,
                            size: 42,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? scheme.primary
                          : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _nextPage(pages.length - 1),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isLast
                        ? (widget.fromDrawer
                              ? context.l10n.onboardingDone
                              : context.l10n.getStarted)
                        : context.l10n.next,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
