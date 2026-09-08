import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/profile_storage.dart';
import '../theme/accent_color_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/section_card.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onDataCleared;

  const SettingsScreen({
    super.key,
    required this.onDataCleared,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;

  TimeOfDay _notificationTime = const TimeOfDay(
    hour: 20,
    minute: 0,
  );

  bool _loadingNotifications = true;

  String _userName = '';
  Uint8List? _userPhoto;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await ProfileStorage.getName();
    final photoBase64 = await ProfileStorage.getPhotoBase64();

    if (!mounted) {
      return;
    }

    setState(() {
      _userName = name;
      _userPhoto = photoBase64 != null ? base64Decode(photoBase64) : null;
      _loadingProfile = false;
    });
  }

  Future<void> _openProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  Future<void> _loadNotificationSettings() async {
    final service = NotificationService.instance;

    final enabled = await service.isEnabled();
    final hour = await service.getHour();
    final minute = await service.getMinute();

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = enabled;

      _notificationTime = TimeOfDay(
        hour: hour,
        minute: minute,
      );

      _loadingNotifications = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final permission =
          await NotificationService.instance.requestPermission();

      if (!permission) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Разреши известията от настройките на телефона.',
            ),
          ),
        );

        return;
      }

      await NotificationService.instance.scheduleDailyNotification(
        hour: _notificationTime.hour,
        minute: _notificationTime.minute,
      );
    } else {
      await NotificationService.instance.cancelDailyNotification();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _selectNotificationTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      helpText: 'Избери час за напомняне',
      cancelText: 'Отказ',
      confirmText: 'Запази',
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _notificationTime = selectedTime;
    });

    if (_notificationsEnabled) {
      await NotificationService.instance.scheduleDailyNotification(
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      );
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _openAccentPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Акцентен цвят',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  alignment: WrapAlignment.center,
                  children: AccentColorController.options.map((option) {
                    return GestureDetector(
                      onTap: () async {
                        await AccentColorController.instance
                            .setColor(option.color);

                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      child: Column(
                        children: [
                          ValueListenableBuilder<Color>(
                            valueListenable:
                                AccentColorController.instance.notifier,
                            builder: (context, current, _) {
                              final selected = current == option.color;

                              return Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: option.color,
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        )
                                      : null,
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.black,
                                      )
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            option.name,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

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
      // Самото изчистване (навици + задачи) се прави в onDataCleared.
      widget.onDataCleared();
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'ПРОФИЛ',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),

          SectionCard(
            children: [
              ListTile(
                onTap: _openProfile,
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.background,
                  backgroundImage:
                      _userPhoto != null ? MemoryImage(_userPhoto!) : null,
                  child: _userPhoto == null
                      ? const Icon(
                          Icons.person,
                          color: Colors.grey,
                        )
                      : null,
                ),
                title: Text(
                  _loadingProfile
                      ? '...'
                      : (_userName.isEmpty ? 'Профил' : _userName),
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Име / снимка',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SectionCard(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'ИЗВЕСТИЯ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.notifications_outlined,
                  color: _notificationsEnabled
                      ? AppColors.accent
                      : Colors.grey.shade300,
                ),
                title: const Text(
                  'Ежедневни напомняния',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _notificationsEnabled
                      ? 'Ще получаваш напомняне всеки ден'
                      : 'Напомнянията са изключени',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                trailing: _loadingNotifications
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeThumbColor: AppColors.accent,
                      ),
              ),
              if (_notificationsEnabled) ...[
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  onTap: _selectNotificationTime,
                  leading: Icon(
                    Icons.schedule_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text(
                    'Час на напомняне',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Всеки ден по това време',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_notificationTime),
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          SectionCard(
            children: [
              ListTile(
                onTap: () => _openAccentPicker(context),
                leading: const Icon(
                  Icons.palette_outlined,
                  color: Colors.grey,
                ),
                title: const Text(
                  'Акцентен цвят',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: ValueListenableBuilder<Color>(
                  valueListenable: AccentColorController.instance.notifier,
                  builder: (context, color, _) {
                    return Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
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
              'Streakly · v1.0',
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
        style: TextStyle(color: titleColor ?? Colors.white),
      ),
      trailing: trailing,
    );
  }
}