import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'app_style.dart';
import 'restore_screen.dart';

/// First launch only. The recovery code is deliberately not asked for here —
/// it comes right before the first record is saved (recovery_flow_screen.dart).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF223D33),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'Amrutham',
                style: TextStyle(
                  color: onboardAmber,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Your family's health, in files you own.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Medicines, records and reminders, kept on your phone. '
                'No account. No server of ours.',
                style: TextStyle(
                  color: Color(0xFFB8D0C5),
                  fontSize: 17,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await ref.read(onboardingStoreProvider).markWelcomeSeen();
                    // The app gate (main.dart) swaps this screen for Home.
                    ref.invalidate(welcomeSeenProvider);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: onboardAmber,
                    foregroundColor: const Color(0xFF2A1D00),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Get started'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RestoreVaultScreen()),
                  ),
                  child: const Text(
                    'I already have a vault',
                    style: TextStyle(color: Color(0xFFB8D0C5)),
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
