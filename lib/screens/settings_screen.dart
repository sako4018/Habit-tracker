import 'package:flutter/material.dart';

import '../services/habit_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onDataCleared;

  const SettingsScreen({
    super.key,
    required this.onDataCleared,
  });

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Изчистване на данни',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Това ще изтрие всички навици и историята им. '
              'Действието не може да бъде отменено.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отказ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Изчисти',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await HabitStorage.clearAll();
      onDataCleared();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            children: [
              SettingsRow(
                icon: Icons.palette_outlined,
                title: 'Акцентен цвят',
                trailing: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              const Divider(
                color: Colors.white10,
                height: 1,
              ),

              const SettingsRow(
                icon: Icons.notifications_outlined,
                title: 'Напомняния',
                trailing: Text(
                  'Скоро',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),

              const Divider(
                color: Colors.white10,
                height: 1,
              ),

              const SettingsRow(
                icon: Icons.reorder,
                title: 'Пренареждане на навици',
                trailing: Text(
                  'Скоро',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SectionCard(
            children: [
              SettingsRow(
                icon: Icons.delete_outline,
                title: 'Изчисти всички данни',
                titleColor: Colors.redAccent,
                onTap: () => _confirmClear(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              'Habit Tracker · v1.0',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: titleColor ?? Colors.grey.shade300,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
        ),
      ),
      trailing: trailing,
    );
  }
}