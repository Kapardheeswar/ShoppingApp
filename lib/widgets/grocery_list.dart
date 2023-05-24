import 'dart:convert';

import 'package:fifth_app/data/categories.dart';
import 'package:fifth_app/models/grocery_item.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  bool isLoading = true;
  List<GroceryItem> newGroceryItems = [];
  late Widget bodyContent;
  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final url = Uri.https(
        'shop-prep-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      setState(() {
        error = "Failed to fetch data, Please try again later";
      });
    }
    if (response.body == 'null') {
      setState(() {
        isLoading = false;
      });
      return;
    }
    print(response.body);
    final loadedData = json.decode(response.body);
    print(loadedData);
    final List<GroceryItem> loadedItems = [];
    for (var item in loadedData.entries) {
      final category = categories.entries.firstWhere(
        (category) => category.value.title == item.value['category'],
      );
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category.value,
        ),
      );
    }
    setState(() {
      newGroceryItems = loadedItems;
      isLoading = false;
    });
  }

  void addNewItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      newGroceryItems.add(newItem);
    });
  }

  void removeItem(GroceryItem item) {
    final url = Uri.https('shop-prep-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    http.delete(url);
    setState(() {
      newGroceryItems.remove(item);
    });
  }

  @override
  Widget build(context) {
    if (newGroceryItems.isNotEmpty) {
      bodyContent = ListView.builder(
        itemCount: newGroceryItems.length,
        itemBuilder: (context, index) {
          return Dismissible(
            onDismissed: (direction) {
              removeItem(newGroceryItems[index]);
            },
            background: Container(
              decoration:
                  BoxDecoration(color: Theme.of(context).colorScheme.error),
            ),
            key: ValueKey(newGroceryItems[index]),
            child: ListTile(
              title: Text(newGroceryItems[index].name),
              leading: Container(
                height: 24,
                width: 24,
                color: newGroceryItems[index].category.color,
              ),
              trailing: Text(
                newGroceryItems[index].quantity.toString(),
              ),
            ),
          );
        },
      );
    } else {
      bodyContent = const Center(
        child: Text("There is Nothing here.. add Something delicious"),
      );
    }
    if (isLoading) {
      bodyContent = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (error != null) {
      bodyContent = Center(
        child: Text(error!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Groceries"),
        actions: [
          IconButton(
            onPressed: addNewItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}
