import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Your Todos'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Todo> _todos = <Todo>[];
  bool isOpen = false;
  final TextEditingController _textFieldController = TextEditingController();

  Future<Database> initializeDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/database.db';
    return openDatabase(path, onCreate: (db, version) async {
      return await db.execute(
        'CREATE TABLE todo(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, completed INTEGER)',
      );
    }, version: 1);
  }

  Future<List<Todo>> getTodos() async {
    final db = await initializeDatabase();

    final List<Map<String, dynamic>> maps =
        await db.query('todo', orderBy: 'id DESC');

    List<Todo> todos = List.generate(maps.length, (i) {
      return Todo(
          id: maps[i]['id'] as int,
          name: maps[i]['name'] as String,
          completed: maps[i]['completed'] as double);
    });

    return todos;
  }

  Future<void> insertTodo(Todo todo) async {
    final db = await initializeDatabase();
    await db.insert(
      'todo',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTodo(int id) async {
    final db = await initializeDatabase();
    await db.delete(
      'todo',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateDog(Todo todo) async {
    final db = await initializeDatabase();
    await db.update(
      'todo',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  void updateListView() {
    Future<List<Todo>> todos = getTodos();
    todos.then((x) {
      setState(() {
        _todos = x;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    updateListView();
  }

  void _addTodoItem(String name) {
    insertTodo(Todo(name: name, completed: 0));
    setState(() {
      updateListView();
    });
    _textFieldController.clear();
  }

  void _handleTodoChange(Todo todo) {
    setState(() {
      todo.completed = todo.completed == 0 ? 1 : 0;
      updateDog(todo);
    });
  }

  void _deleteTodo(Todo todo) {
    deleteTodo(todo.id ?? 0);
    setState(() {
      updateListView();
    });
  }

  Future _displayDialog(BuildContext context) async {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: TextField(
              controller: _textFieldController,
              autofocus: false,
              maxLength: 50,
              decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Type your todo',
                  border: OutlineInputBorder(borderSide: BorderSide.none)),
            ),
          ),
          insetPadding: const EdgeInsets.all(15),
          title: const Text('Add a todo'),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )),
              onPressed: () {
                _textFieldController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel',
                  style: TextStyle(
                    color: Colors.white,
                  )),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_textFieldController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  _addTodoItem(_textFieldController.text);
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildList(BuildContext context) {
    if (isOpen) {
      return Container();
    }

    if (_todos.isNotEmpty) {
      return ListView.builder(
          itemCount: _todos.length,
          itemBuilder: (context, index) => TodoItem(
                todo: _todos[index],
                onTodoChanged: _handleTodoChange,
                deleteTodo: _deleteTodo,
              ));
    } else {
      return const Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image(
                image: AssetImage("images/anime.gif"),
                height: 130,
                width: 180,
              ),
              Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Text(
                      "Hey, there's nothing to do right now, please add it",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      )))
            ]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Text("All ${_todos.length.toString()} Todos",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )),
          )
        ],
      ),
      body: Container(color: Colors.white, child: buildList(context)),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () => _displayDialog(context),
        tooltip: 'Add a Todo',
        backgroundColor: Colors.redAccent,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueAccent,
        shape: const CircularNotchedRectangle(),
        child: Row(
          //children inside bottom appbar
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              "Todo: ${_todos.where((x) => x.completed == 0).length.toString()}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "Done: ${_todos.where((x) => x.completed == 1).length.toString()}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TodoItem extends StatelessWidget {
  final void Function(Todo todo) onTodoChanged;
  final void Function(Todo todo) deleteTodo;
  final Todo todo;

  TodoItem(
      {required this.todo,
      required this.onTodoChanged,
      required this.deleteTodo})
      : super(key: ObjectKey(todo));

  TextStyle? _getTextStyle(bool checked) {
    if (!checked) return null;

    return const TextStyle(
      color: Colors.white,
      decoration: TextDecoration.lineThrough,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: todo.completed == 1
          ? Colors.lightGreen.shade500
          : Colors.lightGreen.shade100,
      elevation: 6,
      margin: const EdgeInsets.only(top: 15, bottom: 0, right: 15, left: 15),
      child: ListTile(
        onTap: () {
          onTodoChanged(todo);
        },
        leading: Checkbox(
          checkColor: Colors.greenAccent,
          activeColor: Colors.black54,
          value: todo.completed == 1,
          onChanged: (value) {
            onTodoChanged(todo);
          },
        ),
        title: Row(children: <Widget>[
          Expanded(
            child: Text(todo.name, style: _getTextStyle(todo.completed == 1)),
          ),
          IconButton(
              iconSize: 24,
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              alignment: Alignment.centerRight,
              onPressed: () => showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete a Todo'),
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: const Text('Do you want to delete?'),
                      ),
                      insetPadding: const EdgeInsets.all(15),
                      actions: <Widget>[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              )),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('No',
                              style: TextStyle(
                                color: Colors.white,
                              )),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            deleteTodo(todo);
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  })),
        ]),
      ),
    );
  }
}

class Todo {
  int? id;
  String name;
  double completed;

  Todo({this.id, required this.name, required this.completed});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'completed': completed,
    };
  }
}

// FutureBuilder<List<Todo>>(
//             future: getTodos(),
//             builder:
//                 (BuildContext context, AsyncSnapshot<List<Todo>> snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(
//                   child: CircularProgressIndicator(
//                     color: Colors.deepPurpleAccent,
//                   ),
//                 );
//               }
//               if (snapshot.connectionState == ConnectionState.done) {
//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Text(
//                       'An ${snapshot.error} occurred',
//                       style: const TextStyle(fontSize: 18, color: Colors.red),
//                     ),
//                   );
//                 } else if (snapshot.hasData) {
//                   return Center(
//                     child: buildList(context),
//                   );
//                 }
//               }

//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             }),
//       )