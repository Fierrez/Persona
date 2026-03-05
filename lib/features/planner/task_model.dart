class Task {
  final String id;
  final String title;
  final String description;
  final String priority;
  final DateTime? dueDate;
  bool isCompleted;
  final List<String> tags;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = 'Medium',
    this.dueDate,
    this.isCompleted = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'tags': tags,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        priority: json['priority'] ?? 'Medium',
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        isCompleted: json['isCompleted'] ?? false,
        tags: List<String>.from(json['tags'] ?? []),
      );
}
