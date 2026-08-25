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
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

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

  /// Longest streak ever recorded for this habit.
  int get bestStreak {
    if (completedDates.isEmpty) return 0;

    final dates = completedDates
        .map((s) {
          final parts = s.split('-');

          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        })
        .toList()
      ..sort();

    int best = 1;
    int current = 1;

    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;

      if (diff == 1) {
        current++;

        if (current > best) {
          best = current;
        }
      } else if (diff > 1) {
        current = 1;
      }
    }

    return best;
  }

  int get totalCompleted => completedDates.length;

  /// Последните 7 дни: от най-стария към днес.
  List<bool> get last7Days {
    final today = DateTime.now();

    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return isDoneOn(day);
    });
  }
}