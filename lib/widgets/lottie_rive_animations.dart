import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 1. Lottie Loading Indicator
class LottieLoading extends StatelessWidget {
  final double size;
  final String? assetPath;

  const LottieLoading({
    super.key,
    this.size = 100,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        assetPath ??
            'assets/animations/loading.json', // Placeholder for actual asset
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const CircularProgressIndicator(),
      ),
    );
  }
}

/// 2. Lottie Success Animation
class LottieSuccess extends StatelessWidget {
  final double size;
  final String? assetPath;
  final VoidCallback? onComplete;

  const LottieSuccess({
    super.key,
    this.size = 150,
    this.assetPath,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        assetPath ?? 'assets/animations/success.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: false,
        onLoaded: (composition) {
          Future.delayed(composition.duration, () {
            if (onComplete != null) onComplete!();
          });
        },
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.check_circle, size: 50, color: Colors.blue),
      ),
    );
  }
}

/// 3. Rive Animated Character / Icon
class RiveHeroIcon extends StatelessWidget {
  final String assetPath;
  final String stateMachineName;
  final String? inputName;
  final bool? inputValue;

  const RiveHeroIcon({
    super.key,
    required this.assetPath,
    required this.stateMachineName,
    this.inputName,
    this.inputValue,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.dashboard, size: 100),
    );
  }
}
