import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:intl/intl.dart';

import 'package:task_management/task_model.dart';
import 'package:task_management/database_helper.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _pickedDate = DateTime.now();
  TimeOfDay _pickedTime = TimeOfDay.now();

  List<TaskItem> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await DatabaseHelper().getTasksByDate(
      DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _pickedDate) {
      if (!mounted) return;
      setState(() {
        _pickedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _pickedTime,
    );
    if (picked != null && picked != _pickedTime) {
      if (!mounted) return;
      setState(() {
        _pickedTime = picked;
      });
    }
  }

  void _showAddTaskDialog() {
    _pickedDate = DateTime.now();
    _pickedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                "Add New Task",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Task Title"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Task Description",
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Date: ${DateFormat('yyyy-MM-dd').format(_pickedDate)}",
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF386BF6),
                    ),
                    onTap: () async {
                      await _selectDate(context);
                      setDialogState(() {});
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Time: ${_pickedTime.format(context)}"),
                    trailing: const Icon(
                      Icons.access_time,
                      color: Color(0xFF386BF6),
                    ),
                    onTap: () async {
                      await _selectTime(context);
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF386BF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (_titleController.text.isNotEmpty) {
                      await DatabaseHelper().insertTask(
                        TaskItem(
                          title: _titleController.text,
                          description: _descriptionController.text,
                          time: _pickedTime.format(context),
                          date: DateFormat('yyyy-MM-dd').format(_pickedDate),
                        ),
                      );
                      _titleController.clear();
                      _descriptionController.clear();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      if (mounted) _loadTasks(); // Refresh list after adding
                    }
                  },
                  child: const Text(
                    "Save Task",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF386BF6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_box_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "My Tasks",
                        style: TextStyle(fontFamily: "ZenDots", fontSize: 22),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.notifications_rounded,
                    color: Color(0xFF386BF6),
                    size: 28,
                  ),
                ],
              ),
            ),

            // Kalender Section
            EasyDateTimeLine(
              initialDate: DateTime.now(),
              onDateChange: (selectedDate) {
                setState(() => _selectedDate = selectedDate);
                _loadTasks();
              },
              headerProps: const EasyHeaderProps(
                monthPickerType: MonthPickerType.switcher,
                dateFormatter: DateFormatter.fullDateMonthAsStrDY(),
              ),
              dayProps: const EasyDayProps(
                height: 85.0,
                width: 65.0,
                activeDayStyle: DayStyle(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    color: Color(0xFF386BF6),
                  ),
                  dayNumStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  dayStrStyle: TextStyle(color: Colors.white),
                ),
                inactiveDayStyle: DayStyle(
                  dayNumStyle: TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ),
            ),

            // Judul List Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate) ==
                            DateFormat('yyyy-MM-dd').format(DateTime.now())
                        ? "Today's Task"
                        : "Task for ${DateFormat('dd MMM').format(_selectedDate)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See All",
                      style: TextStyle(color: Color(0xFF386BF6)),
                    ),
                  ),
                ],
              ),
            ),

            // Task List Section (Dinamis dengan FutureBuilder)
            // Task List Section (Manual State Management)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tasks.isEmpty
                  ? const Center(child: Text("No Tasks for This Day"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              task.isExpanded = !task.isExpanded;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              decoration: task.isDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: task.isDone
                                                  ? Colors.grey
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            task.time,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        task.isDone = !task.isDone;
                                        await DatabaseHelper().updateTask(task);
                                        // _loadTasks(); // Opsional: reload dari DB untuk update UI
                                        // Atau cukup setState lokal jika update DB sukses change
                                        setState(() {});
                                      },
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: task.isDone
                                                ? const Color(0xFF386BF6)
                                                : Colors.grey.shade300,
                                            width: 2,
                                          ),
                                          color: task.isDone
                                              ? const Color(0xFF386BF6)
                                              : Colors.transparent,
                                        ),
                                        child: task.isDone
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                // Bagian Deskripsi yang muncul saat di-klik
                                if (task.isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Divider(color: Colors.grey[200]),
                                        const Text(
                                          "Description:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          task.description,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF386BF6),
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
