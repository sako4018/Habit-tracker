class Task {
  String id;
  String name;
  DateTime date;
  bool isCompleted;

  Task({
    required this.id,
    required this.name,
    required this.date,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        name: json['name'] as String,
        date: DateTime.parse(json['date'] as String),
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  bool isForDate(DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }

  void toggle() {
    isCompleted = !isCompleted;
  }
}