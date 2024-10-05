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

  void addTask() {
    String taskText = _taskController.text.trim();
    if (taskText.isNotEmpty && !tasks.any((task) => task.title == taskText)) {
      setState(() {
        tasks.insert(0, Task(title: taskText));
      });
      _taskController.clear();
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
      tasks.add(completedTask);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciador de Tarefas'),
      ),
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
                      labelText: 'Nova Tarefa',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addTask,
                  child: Text('Incluir'),
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
                  background: Container(color: Colors.green),
                  secondaryBackground: Container(color: Colors.red),
                  onDismissed: (direction) {
                    if (direction == DismissDirection.startToEnd) {
                      completeTask(index);
                    } else {
                      deleteTask(index);
                    }
                  },
                  child: ListTile(
                    tileColor: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    trailing: task.isDeleting
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Removendo...'),
                              TextButton(
                                onPressed: () => undoDelete(index),
                                child: Text('Desfazer'),
                              ),
                            ],
                          )
                        : Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) {
                              if (value == true) completeTask(index);
                            },
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
