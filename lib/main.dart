import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TodoHome(),
    );
  }
}

class Task {
  String title;
  bool isCompleted;
  bool isDeleting;
  Task({required this.title, this.isCompleted = false, this.isDeleting = false});
}

class TodoHome extends StatefulWidget {
  @override
  _TodoHomeState createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> {
  final List<Task> tasks = [];
  final TextEditingController _taskController = TextEditingController();

  void reorderTasks() {
    setState(() {
      tasks.sort((a, b) {
        if (!a.isCompleted && b.isCompleted) {
          return -1;
        } else if (a.isCompleted && !b.isCompleted) {
          return 1; 
        } else {
          return 0; 
        }
      });
    });
  }

  void addTask() {
    String taskText = _taskController.text.trim();
    if (taskText.isNotEmpty && !tasks.any((task) => task.title == taskText)) {
      setState(() {
        tasks.insert(0, Task(title: taskText));
      });
      _taskController.clear();
      reorderTasks();
    }
  }

  void deleteTask(int index) {
    setState(() {
      tasks[index].isDeleting = true;
    });
    
    Timer(Duration(seconds: 3), () {
      if (tasks[index].isDeleting) {
        setState(() {
          tasks.removeAt(index);
        });
      }
    });
  }

  void undoDelete(int index) {
    setState(() {
      tasks[index].isDeleting = false;
    });
  }

  void completeTask(int index) {
    setState(() {
      tasks[index].isCompleted = true;
      Task completedTask = tasks.removeAt(index);

      int insertIndex = tasks.indexWhere((task) => task.isCompleted == true);
      if (insertIndex == -1) {
        tasks.add(completedTask);
      } else {
        tasks.insert(insertIndex, completedTask);
      }
    });
    reorderTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo List'),
        backgroundColor: Color(0xFFEED4FA),
      ),
      backgroundColor: Color(0xFFEED4FA),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    onSubmitted: (value) => addTask(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                      labelText: 'Nova Tarefa',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addTask,
                  child: Text('Incluir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    )
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Dismissible(
                  key: UniqueKey(),
                  background: Container(color: Color(0xFFD4FAE8)),
                  secondaryBackground: Container(color: Color(0xFFFAA49D)),
                  onDismissed: (direction) {
                    if (direction == DismissDirection.startToEnd) {
                      completeTask(index);
                    } else {
                      deleteTask(index);
                    }
                  },
                  child: ListTile(
                    tileColor: task.isDeleting
                        ? Color(0xFFFAA49D)
                        : (index % 2 == 0 ? Color(0xFFFAEDED) : Colors.white),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    trailing: task.isDeleting
                        ? TextButton(
                            onPressed: () => undoDelete(index),
                            child: Text('Desfazer'),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteTask(index),
                              ),
                              Checkbox(
                                value: task.isCompleted,
                                onChanged: (value) {
                                  if (value == true) completeTask(index);
                                },
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
    );
  }
}
