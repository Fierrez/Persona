import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'task_model.dart';
import 'package:uuid/uuid.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final SecureStorageService _storage = SecureStorageService();
  List<Task> _tasks = [];
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final data = await _storage.readList("planner_tasks");
    setState(() {
      _tasks = data.map((item) => Task.fromJson(item)).toList();
    });
  }

  Future<void> _saveTasks() async {
    await _storage.write("planner_tasks", _tasks.map((e) => e.toJson()).toList());
  }

  Future<void> _addTask() async {
    if (_titleController.text.isEmpty) return;
    final newTask = Task(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: '',
      priority: 'Medium',
      dueDate: null,
    );
    setState(() {
      _tasks.add(newTask);
      _titleController.clear();
    });
    await _saveTasks();
  }

  Future<void> _toggleTask(int index) async {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
    await _saveTasks();
  }

  Future<void> _deleteTask(int index) async {
    setState(() {
      _tasks.removeAt(index);
    });
    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Planner")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: "Add a new task..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTask,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Dismissible(
                  key: Key(task.id),
                  onDismissed: (_) => _deleteTask(index),
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, child: const Icon(Icons.delete, color: Colors.white)),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isCompleted,
                      onChanged: (_) => _toggleTask(index),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: task.priority != 'Medium' ? Text("Priority: ${task.priority}") : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
