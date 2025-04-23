import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
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
  late Future<List<GroceryItem>> _loadedItem;
  @override
  void initState() {
    _loadedItem = _loadItems();
    super.initState();
  }

  // Load item from database
  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
      'shopping-app-ce98a-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    final response = await http.get(url);
    if (response.statusCode >= 400) {
      throw Exception('Something went wrong!');
    }
    if (response.body == 'null') {
      return [];
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
    return itemList;
  }

  //Delete from db
  void removeItem(GroceryItem item) async {
    final loadedItems = await _loadedItem;
    final index = loadedItems.indexOf(item);
    setState(() {
      loadedItems.remove(item);
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
        loadedItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void goToAddNewItemScreen() async {
      final loadedItems = await _loadedItem;

      final newItem = await Navigator.push<GroceryItem>(
        context,
        MaterialPageRoute(builder: (ctx) => const AddNewItem()),
      );

      if (newItem != null) {
        setState(() {
          loadedItems.add(newItem);
        });
      }
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
      body: FutureBuilder(
        future: _loadedItem,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 15,
              itemBuilder: (ctx, index) => const CustomListTileShimmer(),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (snapshot.data!.isEmpty) {
            return const Center(child: const Text('No item yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) {
              return Dismissible(
                key: ValueKey(snapshot.data![index].id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  removeItem(snapshot.data![index]);
                },
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 15),
                  child: const Icon(Icons.delete, size: 34),
                ),
                child: ListTile(
                  title: Text(snapshot.data![index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: snapshot.data![index].category.color,
                  ),
                  trailing: Text('${snapshot.data![index].quantity}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
