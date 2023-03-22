// main.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  // await Hive.deleteBoxFromDisk('todo_list');
  await Hive.openBox('todo_list');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const HomePage(),
    );
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _items = [];

  final _shoppingBox = Hive.box('todo_list');
  bool cbFlag = false;

  @override
  void initState() {
    super.initState();
    _refreshItems(); // Load data when app starts
  }

  // Get all items from the database
  void _refreshItems() {
    final data = _shoppingBox.keys.map((key) {
      final value = _shoppingBox.get(key);
      return {"key": key, "name": value["name"], "date": value['date'], "isDone": value['isDone']};
    }).toList();

    setState(() {
      _items = data.reversed.toList();
      // we use "reversed" to sort items in order from the latest to the oldest
    });
  }

  // Create new item
  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _shoppingBox.add(newItem);
    _refreshItems(); // update the UI
  }

  // Retrieve a single item from the database by using its key
  // Our app won't use this function but I put it here for your reference
  Map<String, dynamic> _readItem(int key) {
    final item = _shoppingBox.get(key);
    return item;
  }

  // Update a single item
  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _shoppingBox.put(itemKey, item);
    _refreshItems(); // Update the UI
  }

  // Delete a single item
  Future<void> _deleteItem(int itemKey) async {
    await _shoppingBox.delete(itemKey);
    _refreshItems(); // update the UI

    // Display a snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An item has been deleted')));
  }

  // TextFields' controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(BuildContext ctx, int? itemKey) async {
    // itemKey == null -> create new item
    // itemKey != null -> update an existing item

    if (itemKey != null) {
      final existingItem =
      _items.firstWhere((element) => element['key'] == itemKey);
      _nameController.text = existingItem['name'];
      _quantityController.text = existingItem['date'];
    }

    showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          content: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 15,
                left: 15,
                right: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'To do'),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  readOnly: true,
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'to be completed by',),

                  onTap: () async {
                      var date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100));
                      if (date != null) {
                        _quantityController.text = DateFormat('dd/MM/yyyy')
                            .format(date);
                      }
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Save new item
                    if (itemKey == null) {
                      _createItem({
                        "name": _nameController.text,
                        "date": _quantityController.text,
                        "isDone": false
                      });
                    }

                    // update an existing item
                    if (itemKey != null) {
                      _updateItem(itemKey, {
                        'name': _nameController.text.trim(),
                        'date': _quantityController.text.trim(),
                        'isDone': false
                      });
                    }

                    // Clear the text fields
                    _nameController.text = '';
                    _quantityController.text = '';

                    Navigator.of(context).pop(); // Close the bottom sheet
                  },
                  child: Text(itemKey == null ? 'Create New' : 'Update'),
                ),
                const SizedBox(
                  height: 15,
                )
              ],
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEEFF5),
      appBar: AppBar(
        title: Text(
              'TO DO',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
        elevation: 0,
        backgroundColor: Color(0xFFEEEFF5),
        centerTitle: true,
      ),
      body: _items.isEmpty
          ? const Center(
        child: Text(
          'No Data',
          style: TextStyle(fontSize: 30),
        ),
      )
          : ListView.builder(
        // the list of items
          itemCount: _items.length,
          itemBuilder: (_, index) {
            final currentItem = _items[index];
            return Card(
              margin: const EdgeInsets.all(10),
              elevation: 3,
              child: ListTile(
                  onTap: () => _showForm(context, currentItem['key']),
                  title: Text(
                    currentItem['name'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      decoration: currentItem['isDone'] ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(currentItem['date'].toString()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  tileColor: Colors.white,
                  leading: IconButton(
                    onPressed: () {
                      setState(() {
                        _updateItem(currentItem['key'], {
                          'name': currentItem['name'],
                          'date': currentItem['date'],
                          'isDone': !currentItem['isDone']
                        });
                      });
                    },
                    icon: Icon(
                      currentItem['isDone'] ? Icons.check_box : Icons.check_box_outline_blank,),
                    color: Colors.blue,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteItem(currentItem['key']),
                  )),
            );
          }),
      // Add new item button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}