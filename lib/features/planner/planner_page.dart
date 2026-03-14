import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:persona_app/features/planner/task_model.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final SecureStorageService _storage = SecureStorageService();
  List<Task> _tasks = [];
  String _filterStatus = 'Pending'; 
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
    final descController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    String priority = 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("New Task", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: const Icon(Icons.close_rounded, size: 28)
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "Task Title",
                  prefixIcon: const Icon(Icons.edit_calendar_rounded),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Description (Optional)",
                  prefixIcon: const Icon(Icons.description_outlined),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: selectedTime);
                        if (time != null) setModalState(() => selectedTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: Color(0xFF2D62ED)),
                            const SizedBox(width: 12),
                            Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: priority,
                          isExpanded: true,
                          dropdownColor: Theme.of(context).cardTheme.color,
                          items: ['Low', 'Medium', 'High'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value, 
                              child: Row(
                                children: [
                                  Icon(Icons.flag_rounded, size: 18, color: _getPriorityColor(value)),
                                  const SizedBox(width: 8),
                                  Text(value),
                                ],
                              )
                            );
                          }).toList(),
                          onChanged: (val) => setModalState(() => priority = val!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D62ED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final now = DateTime.now();
                      final dueDate = DateTime(
                        now.year, now.month, now.day,
                        selectedTime.hour, selectedTime.minute,
                      );
                      final newTask = Task(
                        id: const Uuid().v4(),
                        title: titleController.text,
                        description: descController.text,
                        priority: priority,
                        dueDate: dueDate,
                      );
                      setState(() => _tasks.add(newTask));
                      _saveTasks();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Create Task", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    List<Task> displayTasks = [];
    if (_filterStatus == 'Recent') {
      displayTasks = _tasks.where((t) => t.dueDate != null && t.dueDate!.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
    } else if (_filterStatus == 'Pending') {
      displayTasks = _tasks.where((t) => !t.isCompleted).toList();
    } else {
      displayTasks = _tasks.where((t) => t.isCompleted).toList();
    }
    displayTasks.sort((a, b) => (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Planner"), 
        elevation: 0, 
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              headerStyle: HeaderStyle(
                titleTextStyle: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                formatButtonVisible: false,
                titleCentered: true,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                weekendStyle: TextStyle(color: Colors.redAccent.shade100),
              ),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarStyle: CalendarStyle(
                defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                weekendTextStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                todayDecoration: BoxDecoration(color: const Color(0xFF6391F4).withOpacity(0.2), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Color(0xFF2D62ED), fontWeight: FontWeight.bold),
                selectedDecoration: BoxDecoration(color: const Color(0xFF2D62ED), shape: BoxShape.circle),
                markersMaxCount: 1,
                markerDecoration: const BoxDecoration(color: Color(0xFFFB4B93), shape: BoxShape.circle),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              eventLoader: (day) => _tasks.where((t) => isSameDay(t.dueDate, day)).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Row(
              children: [
                _buildToggleButton('Recent'),
                _buildToggleButton('Pending'),
                _buildToggleButton('Completed'),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Text("Your Schedule", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          Expanded(
            child: displayTasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: displayTasks.length,
                    itemBuilder: (context, index) {
                      final task = displayTasks[index];
                      final timeStr = task.dueDate != null ? DateFormat('hh:mm a').format(task.dueDate!) : 'No time';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 4,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(task.priority),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D62ED))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted ? Colors.grey : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: task.description.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 72, top: 4),
                                  child: Text(task.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                )
                              : null,
                          trailing: Checkbox(
                            value: task.isCompleted,
                            activeColor: const Color(0xFF2D62ED),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            onChanged: (val) {
                              setState(() => task.isCompleted = val!);
                              _saveTasks();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          heroTag: "planner_add_fab",
          onPressed: _showAddTaskSheet,
          backgroundColor: const Color(0xFF2D62ED),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("New Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label) {
    final isSelected = _filterStatus == label;
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D62ED) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No ${_filterStatus.toLowerCase()} tasks", style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High': return Colors.redAccent;
      case 'Medium': return Colors.orangeAccent;
      default: return Colors.blueAccent;
    }
  }
}
