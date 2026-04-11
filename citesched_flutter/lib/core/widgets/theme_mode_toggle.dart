import 'package:flutter/material.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({super.key, this.compact = false});

  final bool compact;
  ThemeMode _nextThemeMode(ThemeMode current) {
    return current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            themeModeNotifier.value = _nextThemeMode(mode);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  size: compact ? 16 : 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Text(
                    isDark ? 'Light Mode' : 'Dark Mode',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
