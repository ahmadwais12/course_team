import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_widgets.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final List<Color>? gradientColors;
  final Widget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.gradientColors,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    // iOS: native Cupertino bar. Android: keep branded gradient AppBar.
    if (PlatformAdaptive.isApple) {
      return AdaptiveAppBar(
        title: title,
        actions: actions,
        showBackButton: showBackButton,
        bottom: bottom != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: bottom!,
              )
            : null,
      );
    }

    final theme = Theme.of(context);
    final colors = gradientColors ?? [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: showBackButton,
        actions: actions,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: bottom != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: bottom!,
              )
            : null,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom != null ? 48 : 0));
}
