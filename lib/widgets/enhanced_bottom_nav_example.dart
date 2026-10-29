import 'package:flutter/material.dart';

class EnhancedCurvedBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;

  const EnhancedCurvedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.activeColor = const Color(0xff2398C3),
    this.inactiveColor,
    this.height = 75,
  });

  @override
  State<EnhancedCurvedBottomNav> createState() =>
      _EnhancedCurvedBottomNavState();
}

class _EnhancedCurvedBottomNavState extends State<EnhancedCurvedBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    _animationController.forward(from: 0);
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.activeColor!;
    final inactiveColor = widget.inactiveColor ?? Colors.grey[400]!;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background gradient effect
          Positioned.fill(
            child: CustomPaint(
              painter: GradientBackgroundPainter(
                activeIndex: widget.currentIndex,
                itemCount: 5,
                activeColor: activeColor,
              ),
            ),
          ),
          // Navigation items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  index: 0,
                  isActive: widget.currentIndex == 0,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  icon: Icons.view_list_rounded,
                  label: 'Browse',
                  index: 1,
                  isActive: widget.currentIndex == 1,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildCenterItem(
                  index: 2,
                  isActive: widget.currentIndex == 2,
                  activeColor: activeColor,
                ),
                _buildNavItem(
                  icon: Icons.bookmark_rounded,
                  label: 'Favorites',
                  index: 3,
                  isActive: widget.currentIndex == 3,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 4,
                  isActive: widget.currentIndex == 4,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            vertical: isActive ? 12 : 8,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      activeColor.withValues(alpha: 0.2),
                      activeColor.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1.0 + (0.2 * value),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? activeColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isActive ? activeColor : inactiveColor,
                        size: 24 + (4 * value),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // Label with fade animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - value)),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
              // Active indicator
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scaleX: value,
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 20,
                      height: 3,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterItem({
    required int index,
    required bool isActive,
    required Color activeColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Floating center button
            Positioned(
              top: -20,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        activeColor,
                        activeColor.withValues(alpha: 0.8),
                        activeColor.withValues(alpha: 0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: -5,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating ring effect
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 3.14159 * 2,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Center icon
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Label
            Positioned(
              bottom: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Text(
                      'Add',
                      style: TextStyle(
                        color: activeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for gradient background effect
class GradientBackgroundPainter extends CustomPainter {
  final int activeIndex;
  final int itemCount;
  final Color activeColor;

  GradientBackgroundPainter({
    required this.activeIndex,
    required this.itemCount,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          activeColor.withValues(alpha: 0.05),
          Colors.transparent,
          activeColor.withValues(alpha: 0.03),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
