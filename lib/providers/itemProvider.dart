import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/models/grocery_item.dart';
import 'package:http/http.dart' as http;

final groceryNotifierProvider =
    AsyncNotifierProvider<GroceryNotifier, List<GroceryItem>>(() {
      return GroceryNotifier();
    });

class GroceryNotifier extends AsyncNotifier<List<GroceryItem>> {
  @override
  Future<List<GroceryItem>> build() async {
    // Load item from database
    final url = Uri.https(
      'shopping-app-ce98a-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    final response = await http.get(url);
    if (response.statusCode >= 400) throw Exception('Failed to load');
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

  Future<void> addItem(GroceryItem item) async {
    final url = Uri.https(
      'shopping-app-ce98a-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': item.name,
        'quantity': item.quantity,
        'category': item.category.title,
      }),
    );
    final responseData = json.decode(response.body);
    final newItem = GroceryItem(
      id: responseData['name'],
      name: item.name,
      quantity: item.quantity,
      category: item.category,
    );
    if (response.statusCode <= 400) {
      state = AsyncData([...state.value!, newItem]);
    } else {
      throw Exception('Failed to add item');
    }
  }

  Future<void> removeItem(GroceryItem item) async {
    final prev = state.value;
    state = AsyncData(
      prev!.where((itemState) => itemState.id != item.id).toList(),
    );

    final url = Uri.https(
      'shopping-app-ce98a-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      state = AsyncData(prev); // rollback
      throw Exception('Failed to delete');
    }
  }
}
