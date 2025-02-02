import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:PF/database/database_helper.dart';
import 'package:PF/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // For date formatting

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  HomeScreen({required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _taskController = TextEditingController();
  final _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _tasks = [];
  late AnimationController _animationController;
  late Animation<double> _animation;
  XFile? _selectedImage; // For avatar image
  bool _isExpanded = false; // To control the expansion of the input field

  @override
  void initState() {
    super.initState();
    _fetchTasks();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    // Initialize animation
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchTasks() async {
    final tasks = await _dbHelper.getTasksByUser(widget.user['username']);
    setState(() {
      _tasks = tasks;
    });
  }

  void _addTask() async {
    final taskText = _taskController.text.trim();
    if (taskText.isEmpty) {
      _showMessage('Task cannot be empty.');
      return;
    }

    await _dbHelper.insertTask({
      'task': taskText,
      'isDone': 0,
      'dateAdded': DateFormat('yyyy MMMM d').format(DateTime.now()),
      'username': widget.user['username'],
    });

    _taskController.clear();
    _fetchTasks();
    setState(() {
      _isExpanded = false; // Collapse the input field after adding a task
    });
  }

  void _deleteTask(int id) async {
    await _dbHelper.deleteTask(id);
    _fetchTasks();
  }

  void _toggleTaskStatus(int id, bool isDone) async {
    await _dbHelper.updateTaskStatus(id, !isDone);
    _fetchTasks();
  }

  void _logout() async {
    // Clear login state and user details from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Redirect to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // Function to group tasks by date
  Map<String, List<Map<String, dynamic>>> _groupTasksByDate(List<Map<String, dynamic>> tasks) {
    final groupedTasks = <String, List<Map<String, dynamic>>>{};
    for (final task in tasks) {
      final date = task['dateAdded'];
      if (!groupedTasks.containsKey(date)) {
        groupedTasks[date] = [];
      }
      groupedTasks[date]!.add(task);
    }
    return groupedTasks;
  }

  // Confirm task deletion
  void _confirmDeleteTask(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.blue.shade800)),
          ),
          TextButton(
            onPressed: () {
              _deleteTask(id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.user['username']}'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade800,
                Colors.purple.shade600,
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(widget.user['username']),
                accountEmail: Text(widget.user['email']),
                currentAccountPicture: GestureDetector(
                  onTap: _pickImage, // Allow the user to pick an image
                  child: CircleAvatar(
                    backgroundImage: _selectedImage != null
                        ? FileImage(File(_selectedImage!.path))
                        : null,
                    child: _selectedImage == null
                        ? Icon(Icons.person, color: Colors.blue.shade800)
                        : null,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
              ListTile(
                leading: Icon(Icons.home, color: Colors.white),
                title: Text('Home', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.white),
                title: Text('Settings', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Add settings functionality here
                },
              ),
              ListTile(
                leading: Icon(Icons.info, color: Colors.white),
                title: Text('About', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Add about functionality here
                },
              ),
              Divider(color: Colors.white70),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.white),
                title: Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade800,
                  Colors.purple.shade600,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: FadeTransition(
                      opacity: _animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 1),
                          end: Offset.zero,
                        ).animate(_animationController),
                        child: ListView(
                          children: _groupTasksByDate(_tasks).entries.map((entry) {
                            final date = entry.key;
                            final tasks = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(
                                    date == DateFormat('yyyy MMMM d').format(DateTime.now())
                                        ? "Today's Tasks"
                                        : "$date Tasks",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...tasks.map((task) => Card(
                                  color: Colors.white.withOpacity(0.1),
                                  margin: EdgeInsets.symmetric(vertical: 5),
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: task['isDone'] == 1,
                                      onChanged: (value) {
                                        _toggleTaskStatus(task['id'], task['isDone'] == 1);
                                      },
                                      activeColor: Colors.blue.shade800,
                                    ),
                                    title: Text(
                                      task['task'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        decoration: task['isDone'] == 1
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      task['dateAdded'],
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _confirmDeleteTask(task['id']),
                                    ),
                                  ),
                                )),
                                Divider(color: Colors.white70),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Floating Action Button at the middle bottom
          Positioned(
            left: 16, // Add some padding
            right: 16, // Add some padding
            bottom: 20, // Position at the bottom
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: TextField(
                        controller: _taskController,
                        style: TextStyle(color: Colors.blue.shade800),
                        decoration: InputDecoration(
                          hintText: 'New Task',
                          hintStyle: TextStyle(color: Colors.blue.shade800.withOpacity(0.5)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add, // Plus icon
                      color: Colors.blue.shade800,
                    ),
                    onPressed: _addTask, // Add task when pressed
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}