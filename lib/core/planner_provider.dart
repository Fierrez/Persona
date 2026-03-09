import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:persona_app/features/planner/task_model.dart';
import 'package:table_calendar/table_calendar.dart';

class PlannerProvider with ChangeNotifier {
  final _storage = SecureStorageService();
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  PlannerProvider() {
    _loadTasks();
  }

  void reset() {
    _tasks = [];
    notifyListeners();
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();
    final data = await _storage.readList("planner_tasks");
    _tasks = data.map((item) => Task.fromJson(item)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    await _storage.write("planner_tasks", _tasks.map((e) => e.toJson()).toList());
  }

  List<Task> getTasksForDay(DateTime day) {
    return _tasks.where((t) => isSameDay(t.dueDate, day)).toList();
  }

  List<Task> getUpcomingTasks({int limit = 3}) {
    final now = DateTime.now();
    final upcoming = _tasks.where((t) => !t.isCompleted && (t.dueDate?.isAfter(now) ?? false)).toList();
    upcoming.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return upcoming.take(limit).toList();
  }
}
