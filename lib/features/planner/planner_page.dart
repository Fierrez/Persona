import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:table_calendar/table_calendar.dart';
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
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("New Task", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(hintText: "What needs to be done?"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final newTask = Task(
                    id: const Uuid().v4(),
                    title: titleController.text,
                    dueDate: _selectedDay,
                  );
                  setState(() => _tasks.add(newTask));
                  _saveTasks();
                  Navigator.pop(context);
                }
              },
              child: const Text("Add Task"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayTasks = _tasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate, _selectedDay);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Planner")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            eventLoader: (day) {
              return _tasks.where((t) => isSameDay(t.dueDate, day)).toList();
            },
          ),
          const Divider(),
          Expanded(
            child: dayTasks.isEmpty 
              ? const Center(child: Text("No tasks for this day"))
              : ListView.builder(
                  itemCount: dayTasks.length,
                  itemBuilder: (context, index) {
                    final task = dayTasks[index];
                    return ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (val) {
                          setState(() => task.isCompleted = val!);
                          _saveTasks();
                        },
                      ),
                      title: Text(task.title, style: TextStyle(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      )),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
