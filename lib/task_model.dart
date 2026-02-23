class TaskItem {
  int? id;
  String title;
  String description;
  String time;
  bool isDone;
  bool isExpanded;
  String date; // Format: YYYY-MM-DD

  TaskItem({
    this.id,
    required this.title,
    required this.description,
    required this.time,
    this.isDone = false,
    this.isExpanded = false,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time': time,
      'date': date,
      'isDone': isDone ? 1 : 0,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: map['date'],
      time: map['time'],
      isDone: map['isDone'] == 1,
    );
  }
}
