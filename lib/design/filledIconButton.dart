import 'package:flutter/material.dart';

class FilledIconButton extends IconButton {
  final Color backgroundColor;
  final Color iconColor;

  FilledIconButton({
    super.key,
    required IconData icon,
    required this.backgroundColor,
    this.iconColor = Colors.black,
    double iconSize = 24,
    super.onPressed,
  }) : super(
          icon: Icon(icon, size: iconSize),
          iconSize: iconSize,
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(backgroundColor),
            shape: const WidgetStatePropertyAll(CircleBorder()),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                final int disabledAlpha = (iconColor.a * 0.4).round();
                return iconColor.withAlpha(disabledAlpha);
              }
              return iconColor;
            }),
          ),
        );

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color bg = enabled
        ? backgroundColor
        : backgroundColor.withAlpha((backgroundColor.alpha * 0.5).round());
    return Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: super.build(context),
    );
  }
}
