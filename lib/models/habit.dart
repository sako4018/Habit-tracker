class Habit {
  String id;
  String name;
  String emoji;
  Set<String> completedDates; // format: yyyy-MM-dd

  /// Денят, в който навикът е създаден.
  ///
  /// Съществува, за да не се броят за "пропуснати" дните преди навикът
  /// изобщо да е съществувал. Без него навик на три дни има таван
  /// ~10% успеваемост за прозорец от 30 дни.
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    Set<String>? completedDates,
    DateTime? createdAt,
  })  : completedDates = completedDates ?? {},
        createdAt = _dayOnly(createdAt ?? DateTime.now());

  static DateTime _dayOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'completedDates': completedDates.toList(),
        'createdAt': keyFor(createdAt),
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final completed =
        Set<String>.from(json['completedDates'] ?? const []);

    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: (json['emoji'] as String?)?.trim().isNotEmpty == true
          ? json['emoji'] as String
          : '⭐',
      completedDates: completed,
      createdAt: _readCreatedAt(json['createdAt'], completed),
    );
  }

  /// Навиците, запазени преди полето да съществува, нямат `createdAt`.
  /// За тях приемаме първото отчитане, а ако още нямат такова — днес.
  static DateTime _readCreatedAt(
    Object? raw,
    Set<String> completedDates,
  ) {
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);

      if (parsed != null) {
        return parsed;
      }
    }

    if (completedDates.isEmpty) {
      return DateTime.now();
    }

    final earliest = completedDates.reduce(
      (a, b) => a.compareTo(b) <= 0 ? a : b,
    );

    return DateTime.tryParse(earliest) ?? DateTime.now();
  }

  /// Колко дни навикът е бил проследяван, включително днешния.
  /// Никога под 1, за да не се дели на нула.
  int trackedDays([DateTime? now]) {
    final today = _dayOnly(now ?? DateTime.now());

    final days = today.difference(createdAt).inDays + 1;

    return days < 1 ? 1 : days;
  }

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