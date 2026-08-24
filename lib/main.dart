import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(
    DevicePreview(
      // Only wraps the UI in a phone frame for local web debugging.
      // Disabled automatically in release builds.
      enabled: !const bool.fromEnvironment('dart.vm.product'),
      builder: (context) => const HabitTrackerApp(),
    ),
  );
}

// ---------- THEME ----------

class AppColors {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const accent = Color(0xFFBB86FC);
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onPrimary: Colors.black,
      onSurface: Colors.white,
      error: Colors.redAccent,
    );

    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.surface,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}

// ---------- MODEL ----------

class Habit {
  String id;
  String name;
  String emoji;
  Set<String> completedDates; // format: yyyy-MM-dd

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    Set<String>? completedDates,
  }) : completedDates = completedDates ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'completedDates': completedDates.toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: (json['emoji'] as String?)?.trim().isNotEmpty == true
            ? json['emoji'] as String
            : '⭐',
        completedDates: Set<String>.from(json['completedDates'] ?? const []),
      );

  static String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isDoneOn(DateTime date) => completedDates.contains(keyFor(date));

  void toggle(DateTime date) {
    final key = keyFor(date);
    if (completedDates.contains(key)) {
      completedDates.remove(key);
    } else {
      completedDates.add(key);
    }
  }

  int get currentStreak {
    int streak = 0;
    DateTime day = DateTime.now();
    if (!isDoneOn(day)) {
      day = day.subtract(const Duration(days: 1));
    }
    while (isDoneOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get totalCompleted => completedDates.length;

  /// Last 7 days (oldest -> newest, ending today). true = completed.
  List<bool> get last7Days {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return isDoneOn(day);
    });
  }
}

String _generateId() {
  final rnd = Random();
  return '${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(999999)}';
}

// ---------- STORAGE ----------

class HabitStorage {
  static const _storageKey = 'habits_data_v2';

  static Future<List<Habit>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];
      final List decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => Habit.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Habit load error: $e');
      return [];
    }
  }

  static Future<bool> save(List<Habit> habits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(habits.map((h) => h.toJson()).toList());
      return await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('Habit save error: $e');
      return false;
    }
  }
}

// ---------- HOME SCREEN ----------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> habits = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await HabitStorage.load();
    setState(() {
      habits = loaded;
      loading = false;
    });
  }

  Future<void> _persist() => HabitStorage.save(habits);

  void _toggleToday(Habit habit) {
    final willBeDone = !habit.isDoneOn(DateTime.now());
    setState(() => habit.toggle(DateTime.now()));
    _persist();
    if (willBeDone) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _deleteHabit(Habit habit) async {
    setState(() => habits.removeWhere((h) => h.id == habit.id));
    _persist();
  }

  Future<void> _addHabit() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _AddHabitDialog(),
    );
    if (result == null) return;

    final newHabit = Habit(
      id: _generateId(),
      name: result['name']!,
      emoji: result['emoji']!,
    );

    setState(() => habits.add(newHabit));
    _persist();
  }

  void _openCalendar(Habit habit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitCalendarScreen(
          habit: habit,
          onChanged: () {
            setState(() {});
            _persist();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final doneToday = habits.where((h) => h.isDoneOn(today)).length;

    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Днес',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            habits.isEmpty
                                ? 'Добави първия си навик 👇'
                                : '$doneToday от ${habits.length} изпълнени',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (habits.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Няма добавени навици все още.\nНатисни + за да започнеш.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.grey.shade500, fontSize: 15),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final habit = habits[index];
                            return _HabitCard(
                              key: ValueKey(habit.id),
                              habit: habit,
                              onToggleToday: () => _toggleToday(habit),
                              onDelete: () => _deleteHabit(habit),
                              onOpenCalendar: () => _openCalendar(habit),
                            );
                          },
                          childCount: habits.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHabit,
        icon: const Icon(Icons.add),
        label: const Text('Нов навик'),
      ),
    );
  }
}

// ---------- HABIT CARD ----------

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggleToday;
  final VoidCallback onDelete;
  final VoidCallback onOpenCalendar;

  const _HabitCard({
    super.key,
    required this.habit,
    required this.onToggleToday,
    required this.onDelete,
    required this.onOpenCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final streak = habit.currentStreak;
    final week = habit.last7Days;

    return Dismissible(
      key: ValueKey('dismiss_${habit.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Изтриване',
                    style: TextStyle(color: Colors.white)),
                content: Text('Да изтрия ли "${habit.name}"?',
                    style: const TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Отказ'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Изтрий',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onOpenCalendar,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child:
                        Text(habit.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              '$streak ${streak == 1 ? "ден" : "дни"} подред',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _CheckButton(
                    isDone: habit.isDoneOn(DateTime.now()),
                    onTap: onToggleToday,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final done = week[i];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 26,
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.accent
                              : AppColors.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- ANIMATED CHECK BUTTON ----------

class _CheckButton extends StatefulWidget {
  final bool isDone;
  final VoidCallback onTap;

  const _CheckButton({required this.isDone, required this.onTap});

  @override
  State<_CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<_CheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _showBurst = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final willBeDone = !widget.isDone;
    widget.onTap();
    if (willBeDone) {
      _controller.forward(from: 0);
      setState(() => _showBurst = true);
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) setState(() => _showBurst = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('check_button'),
      onTap: _handleTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_showBurst) const _BurstEffect(),
            AnimatedBuilder(
              animation: _scale,
              builder: (context, child) => Transform.scale(
                scale: _scale.value,
                child: child,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isDone ? AppColors.accent : Colors.transparent,
                  border: Border.all(
                    color: widget.isDone ? AppColors.accent : Colors.grey.shade600,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: widget.isDone
                    ? const Icon(Icons.check, color: Colors.black, size: 20)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurstEffect extends StatefulWidget {
  const _BurstEffect();

  @override
  State<_BurstEffect> createState() => _BurstEffectState();
}

class _BurstEffectState extends State<_BurstEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<double> _angles = List.generate(6, (i) => i * (360 / 6));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          children: _angles.map((angle) {
            final rad = angle * pi / 180;
            final distance = 26 * t;
            final dx = cos(rad) * distance;
            final dy = sin(rad) * distance;
            return Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: const Icon(Icons.star, size: 10, color: AppColors.accent),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ---------- ADD HABIT DIALOG ----------

class _AddHabitDialog extends StatefulWidget {
  const _AddHabitDialog();

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  final _emojiController = TextEditingController();
  final _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emojiController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Въведи име на навика');
      return;
    }
    if (emoji.isEmpty) {
      setState(() => _error = 'Въведи емоджи');
      return;
    }
    Navigator.pop(context, {'name': name, 'emoji': emoji});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Нов навик', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('emoji_field'),
            controller: _emojiController,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, color: Colors.white),
            maxLength: 2,
            decoration: InputDecoration(
              hintText: 'Емоджи, напр. 💧',
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              counterText: '',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('name_field'),
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Име, напр. Пий вода',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отказ'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
          ),
          child: const Text('Добави'),
        ),
      ],
    );
  }
}

// ---------- CALENDAR SCREEN ----------

class HabitCalendarScreen extends StatefulWidget {
  final Habit habit;
  final VoidCallback onChanged;

  const HabitCalendarScreen({
    super.key,
    required this.habit,
    required this.onChanged,
  });

  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  late DateTime _visibleMonth;

  static const _monthNames = [
    'Януари', 'Февруари', 'Март', 'Април', 'Май', 'Юни',
    'Юли', 'Август', 'Септември', 'Октомври', 'Ноември', 'Декември'
  ];
  static const _weekDayLabels = ['П', 'В', 'С', 'Ч', 'П', 'С', 'Н'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _toggleDay(DateTime day) {
    final today = DateTime.now();
    final dayOnly = DateTime(day.year, day.month, day.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (dayOnly.isAfter(todayOnly)) return;
    setState(() => widget.habit.toggle(day));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmpty = firstOfMonth.weekday - 1; // Monday = 1
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(habit.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(child: Text(habit.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _StatChip(label: 'Streak', value: '${habit.currentStreak} 🔥'),
                const SizedBox(width: 12),
                _StatChip(label: 'Общо дни', value: '${habit.totalCompleted}'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                Text(
                  '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: _weekDayLabels
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style:
                                  TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                itemCount: leadingEmpty + daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  if (index < leadingEmpty) return const SizedBox.shrink();
                  final dayNum = index - leadingEmpty + 1;
                  final date =
                      DateTime(_visibleMonth.year, _visibleMonth.month, dayNum);
                  final isFuture =
                      date.isAfter(DateTime(today.year, today.month, today.day));
                  final done = habit.isDoneOn(date);
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;

                  return GestureDetector(
                    onTap: isFuture ? null : () => _toggleDay(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: done ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday
                            ? Border.all(color: AppColors.accent, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isFuture
                              ? Colors.grey.shade700
                              : (done ? Colors.black : Colors.white),
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}