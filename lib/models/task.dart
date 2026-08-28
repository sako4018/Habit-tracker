class Task {
  final String id;
  final String name;
  final DateTime date;
  bool completed;

  Task({
    required this.id,
    required this.name,
    required this.date,
    this.completed = false,
  });

  bool isForDate(DateTime day) {
    return date.year == day.year &&
        date.month == day.month &&
        date.day == day.day;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'completed': completed,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      completed: map['completed'] as bool? ?? false,
    );
  }
}
