import 'package:flutter/material.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final List<Map<String, dynamic>> _tasks = [
    {"title": "Finish Flutter project", "done": false},
    {"title": "Prepare for class", "done": true},
    {"title": "Read 20 pages of a book", "done": false},
    {"title": "Read 20 pages of a book", "done": false},
    {"title": "Read 20 pages of a book", "done": true},
    {"title": "I want to code", "done": true},
    {"title": "Read 20 pages of a book", "done": false},
    {"title": "I will go to school", "done": false},
  ];

  final TextEditingController _taskC = TextEditingController();

  void _addTask() {
    if (_taskC.text.trim().isEmpty) return;
    setState(() {
      _tasks.add({"title": _taskC.text.trim(), "done": false});
    });
    _taskC.clear();
    Navigator.pop(context); // close dialog
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Task"),
        content: TextField(
          controller: _taskC,
          decoration: const InputDecoration(
            hintText: "Enter task...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(onPressed: _addTask, child: const Text("Add")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.greenAccent,
        title: const Text(
          "To-Do List",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final task = _tasks[i];
          return Dismissible(
            key: ValueKey(task["title"]),
            background: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              setState(() => _tasks.removeAt(i));
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                leading: Checkbox(
                  value: task["done"],
                  onChanged: (val) {
                    setState(() => task["done"] = val);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                title: Text(
                  task["title"],
                  style: TextStyle(
                    fontSize: 16,
                    decoration: task["done"]
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: task["done"] ? Colors.grey : Colors.black,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        label: const Text("Add Task"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.greenAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
