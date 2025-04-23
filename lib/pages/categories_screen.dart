import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/models/category.dart';
import 'package:shopping_app/models/grocery_item.dart';

import 'package:shopping_app/pages/add_new_item.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_app/widgets/custom_list_tile_skeleton.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<GroceryItem> _groceryItem = [];
  String? _error;

  bool isLoading = true;
  @override
  void initState() {
    _loadItems();
    super.initState();
  }

  // Load item from database
  void _loadItems() async {
    final url = Uri.https(
      'shopping-app-ce98a-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    try {
      final response = await http.get(url);
      if (response.body == 'null') {
        setState(() {
          isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> dataList = json.decode(response.body);
      final List<GroceryItem> itemList = [];
      for (final item in dataList.entries) {
        final category =
            categories.entries
                .firstWhere(
                  (catItem) => catItem.value.title == item.value['category'],
                )
                .value;
        itemList.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        isLoading = false;
        _groceryItem = itemList;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        _error = 'Something went wrong, Please try again later';
      });
    }
  }

  //Delete from db
  void removeItem(GroceryItem item) async {
    final index = _groceryItem.indexOf(item);
    setState(() {
      _groceryItem.remove(item);
    });
    final url = Uri.https(
      'shopping-app-ce98a-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );
    final response = await http.delete(url);
    if (!mounted) {
      return;
    }
    if (response.statusCode >= 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete the item. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() {
        _groceryItem.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void goToAddNewItemScreen() async {
      final newItem = await Navigator.push<GroceryItem>(
        context,
        MaterialPageRoute(builder: (ctx) => const AddNewItem()),
      );

      if (newItem != null) {
        setState(() {
          _groceryItem.add(newItem);
        });
      }
    }

    Widget content = const Center(child: const Text('No item yet'));
    if (_error != null) {
      content = Center(child: Text(_error!));
    }
    if (isLoading) {
      content = ListView.builder(
        itemCount: 15,
        itemBuilder: (ctx, index) => const CustomListTileShimmer(),
      );
    }

    if (_groceryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder: (ctx, index) {
          return Dismissible(
            key: ValueKey(_groceryItem[index].id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              removeItem(_groceryItem[index]);
            },
            background: Container(
              color: Theme.of(context).colorScheme.error,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 15),
              child: const Icon(Icons.delete, size: 34),
            ),
            child: ListTile(
              title: Text(_groceryItem[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryItem[index].category.color,
              ),
              trailing: Text('${_groceryItem[index].quantity}'),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: goToAddNewItemScreen,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
