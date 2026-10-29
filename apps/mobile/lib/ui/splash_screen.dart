import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

const _bgTop = Color(0xFF0F3A2D);
const _bgMid = Color(0xFF0D3226);
const _bgBottom = Color(0xFF0A261D);
const _gold = Color(0xFFF0A91E);
const _softText = Color(0xFFB8D0C5);
const _dimText = Color(0xFF8FB0A2);
const _trackColor = Color(0x1FFFFFFF);

/// Shortest time the splash stays on screen, so it doesn't flash by when the
/// database opens instantly. Tests override this with [Duration.zero].
final splashMinDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 1500),
);

/// Shown while the device key is read and the encrypted database is opened
/// (see [databaseProvider]), then fades into [next].
///
/// Waiting on the database here, rather than on a fixed timer alone, means the
/// first real screen never builds against a database that isn't open yet.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, required this.next});

  final Widget next;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _minTimer;
  bool _minElapsed = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _minTimer = Timer(ref.read(splashMinDurationProvider), () {
      if (mounted) setState(() => _minElapsed = true);
    });
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => widget.next,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    if (_minElapsed && db.hasValue && !_leaving) {
      _leaving = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
    }

    final failed = db.hasError && !db.hasValue;
    if (failed) {
      debugPrint('Splash: database failed to open: ${db.error}');
    }

    final artHeight = MediaQuery.sizeOf(context).height * 0.6;

    return Scaffold(
      backgroundColor: _bgBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgMid, _bgBottom],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Up to 60% of the screen, but it gives way to the text below on
              // short screens (small phones, split-screen) instead of overflowing.
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: artHeight),
                  child: const SizedBox.expand(child: _Artwork()),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Amrutham',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Your family's health, in files you own",
                style: TextStyle(color: _softText, fontSize: 15),
              ),
              const SizedBox(height: 22),
              const Text(
                'ధన్వంతరి · धन्वन्तरि',
                style: TextStyle(
                  color: _gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (failed)
                _OpenFailed(onRetry: () => ref.invalidate(databaseProvider))
              else
                const _Opening(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// The deity artwork, faded into the background along its bottom edge.
class _Artwork extends StatelessWidget {
  const _Artwork();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black, Colors.black, Colors.transparent],
        stops: [0, 0.78, 1],
      ).createShader(rect),
      child: Image.asset(
        'assets/images/dhanvantari.webp',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        semanticLabel: 'Dhanvantari, the god of medicine',
        // Decorative: if the asset ever fails to load, the splash still works.
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _Opening extends StatelessWidget {
  const _Opening();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            minHeight: 4,
            color: _gold,
            backgroundColor: _trackColor,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Opening your vault',
          style: TextStyle(color: _dimText, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _OpenFailed extends StatelessWidget {
  const _OpenFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "We couldn't open your vault on this phone.",
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: const Color(0xFF2A1D00),
          ),
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
