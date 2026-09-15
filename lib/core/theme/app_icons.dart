import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  static const IconData dashboard = Icons.home_rounded;
  static const IconData dashboardOutlined = Icons.home_outlined;

  static const IconData activities = Icons.checklist_rounded;
  static const IconData activitiesOutlined = Icons.checklist_outlined;

  static const IconData classes = Icons.school_rounded;
  static const IconData classesOutlined = Icons.school_outlined;

  static const IconData skills = Icons.emoji_events_rounded;
  static const IconData skillsOutlined = Icons.emoji_events_outlined;

  static const IconData profile = Icons.account_circle_rounded;
  static const IconData profileOutlined = Icons.account_circle_outlined;

  static const IconData validation = Icons.check_circle_rounded;
  static const IconData upload = Icons.upload_rounded;
  static const IconData path = Icons.alt_route_rounded;
  static const IconData github = Icons.code_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData bell = Icons.notifications_rounded;
}

class AnimatedCheckBadge extends StatelessWidget {
  const AnimatedCheckBadge({
    super.key,
    this.size = 48,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Icon(Icons.check_circle_rounded, color: resolvedColor, size: size),
        );
      },
    );
  }
}
