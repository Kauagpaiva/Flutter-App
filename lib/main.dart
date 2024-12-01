import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Tarefas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todos os campos são obrigatórios')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/fazer_login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final jwtToken = responseData['token'];
        final username = responseData['nome'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login realizado com sucesso!')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(jwtToken: jwtToken, username: username, userEmail: email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de login: Email ou senha inválidos')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _openSignUpPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEED4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
     
                  onPressed: _togglePasswordVisibility,
                ),
              ),
              obscureText: _obscureText,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
            SizedBox(height: 12),
            ElevatedButton(
                    onPressed: _openSignUpPage,
                    child: Text('Cadastrar-se'),
              )
          ],
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _jwtToken;

  Future<void> _signUp() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final phone = _phoneController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('As senhas devem ser iguais')),
      );
      return;
    }

    final url =
        Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/registra_usuario');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': name,
          'email': email,
          'celular': phone,
          'senha': password,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cadastro realizado com sucesso!')),
        );
        _getTokenAndCreateTable();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cadastro inválido')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error')),
      );
    }
  }

  Future<void> _getTokenAndCreateTable() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/fazer_login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _jwtToken = responseData['token'];
        });
        _createTaskTable();
      } else {
        print('Erro ao resgatar token');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error')),
      );
    }
  }

  Future<void> _createTaskTable() async {
    final email = _emailController.text;

    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/tarefas');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_jwtToken}',
        },
        body: jsonEncode({'email': email, 'valor': {}}),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ToDo List criada com sucesso!')),
        );
      } else {
        print(json.decode(response.body));
      }
    } catch (error) {
      print('Erro: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEED4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                labelText: 'Nome'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                labelText: 'Celular'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                labelText: 'Senha'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                labelText: 'Confirmar Senha'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signUp,
              child: Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  String title;
  bool isCompleted;
  bool isDeleting;
  Task(
      {required this.title, this.isCompleted = false, this.isDeleting = false});
}

class TodoHome extends StatefulWidget {
  final String username;
  final String jwtToken;
  final String userEmail;

  const TodoHome({
    super.key,
    required this.jwtToken,
    required this.userEmail,
    required this.username,
  });

  @override
  _TodoHomeState createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> {
  List<Task> tasks = [];
  final TextEditingController _taskController = TextEditingController();

  void initState() {
    super.initState();
    _loadTasksFromServer();
  }

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
      _saveTasksToServer();
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
          _saveTasksToServer();
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
    _saveTasksToServer();
  }

  List<Map<String, dynamic>> convertTasksToJson(List<Task> tasks) {
    List<Map<String, dynamic>> tasksJson = tasks.map((task) {
      return {
        'title': task.title,
        'isCompleted': task.isCompleted,
        'isDeleting': task.isDeleting,
      };
    }).toList();

    return tasksJson;
  }

  List<Task> convertJsonToTasks(List<dynamic> tasksJson) {

    return tasksJson.map((taskMap) {
      return Task(
        title: taskMap['title'],
        isCompleted: taskMap['isCompleted'],
        isDeleting: taskMap['isDeleting'],
      );
    }).toList();
  }

  Future<void> _saveTasksToServer() async {
    final tasksJson = convertTasksToJson(tasks);

    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/tarefas');
    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.jwtToken}',
        },
        body: jsonEncode({
          'email': widget.userEmail,
          'valor': tasksJson,
        }),
      );

      if (response.statusCode == 201) {
        print('Tarefas salvas com sucesso!');
      } else if (response.statusCode == 401) {
        final decodedBody = json.decode(response.body);
        if (decodedBody['code'] == "PGRST301") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        print(json.decode(response.body));
      }
    } catch (error) {
      ;
    }
  }

  Future<void> _loadTasksFromServer() async {
    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/tarefas');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.jwtToken}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final tasksJson = responseData[0]['valor'];
        
        if (tasksJson.isEmpty) {
        setState(() {
          tasks = [];
        });
        } else {
          setState(() {
            tasks = convertJsonToTasks(tasksJson);
          });
        }
        
      } else {
        print('Erro ao carregar tarefas');
      }
    } catch (error) {
      print('Erro: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    )),
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

// Sidebar Widget
class Sidebar extends StatelessWidget {
  final Function(String) onSelect;
  final VoidCallback onLogout;

  Sidebar({required this.onSelect, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('Lista de Tarefas'),
            onTap: () => onSelect('tasks'),
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Chat'),
            onTap: () => onSelect('chat'),
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Iniciar Novo Chat'),
            onTap: () => onSelect('new_chat'),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatefulWidget {
  final String jwtToken;
  final String username;
  final String userEmail;

  HomeScreen({required this.jwtToken, required this.username, required this.userEmail});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentScreen = 'chat';

  void _handleNavigation(String screen) {
    setState(() {
      _currentScreen = screen;
    });
    Navigator.pop(context); // Fecha a sidebar após seleção
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> createNewChat() async {
    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/cria_conversa');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.jwtToken}',
        },
      );

      if (response.statusCode == 200) {
        print("Novo chat criado com sucesso");
      } else {
        print("Erro ao criar novo chat: ");
        print(response.statusCode);
      }
    } catch (error) {
      print('Erro: $error');
    }
  }

  Future<void> getChats() async {
    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/conversas');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.jwtToken}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // get chatid
        // get messages
      } else {
        print('Erro ao carregar mensagens');
      }
    } catch (error) {
      print('Erro: $error');
    }
  }

  

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_currentScreen == 'tasks') {
      content = TodoHome(jwtToken: widget.jwtToken, username: widget.username, userEmail: widget.userEmail);
    } else {
      if (_currentScreen == 'new_chat') {
        createNewChat();
        
      }
      // add a get chats to get the new chat id
      content = ChatScreen(jwtToken: widget.jwtToken, username: widget.username);
      
    }

    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      drawer: Sidebar(onSelect: _handleNavigation, onLogout: _logout),
      body: content,
    );
  }
}

// Chat Screen
class ChatScreen extends StatefulWidget {
  final String jwtToken;
  final String username;

  ChatScreen({required this.jwtToken, required this.username});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  List<Map<String, String>> _messages = [];
  
  void initState() {
    super.initState();
    getMessages();
  }
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({'papel': widget.username, 'conteudo': text});
      });
      _messageController.clear();

      // Simula recebimento da API
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _messages.add({'papel': 'assistente', 'conteudo': 'Resposta à: $text'});
        });
      });
    }
  }

  Future<void> getMessages() async {
    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/conversas');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.jwtToken}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print(responseData);
        if (!responseData.isEmpty) {
          final messages = responseData[0]['mensagens'];
          if (messages.isEmpty) {
          setState(() {
            _messages = [];
          });
          } else {
            setState(() {
              _messages = [{'papel': 'assistente', 'conteudo': 'Chat carregado com sucesso'}];
            });
          }
        }
      } else {
        print('Erro ao carregar mensagens');
      }
    } catch (error) {
      print('Erro: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isUser = message['papel'] != "assistente";
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(message['conteudo']!,
                      style: TextStyle(color: Colors.white)),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                    labelText: 'Digite sua mensagem'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Placeholder Task Screen
class TaskScreen extends StatelessWidget {
  final String jwtToken;

  TaskScreen({required this.jwtToken});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Tela de Tarefas'));
  }
}

