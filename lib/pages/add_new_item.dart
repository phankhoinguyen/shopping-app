import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/models/category.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_app/models/grocery_item.dart';

class AddNewItem extends StatefulWidget {
  const AddNewItem({super.key});

  @override
  State<AddNewItem> createState() => _AddNewItemState();
}

class _AddNewItemState extends State<AddNewItem> {
  bool _isSending = false;
  final _formKey = GlobalKey<FormState>();
  var enterName = '';
  var enterQuantity = '';
  var choosenCategory = categories[Categories.vegetables]!;
  void addItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final url = Uri.https(
        'shopping-app-ce98a-default-rtdb.firebaseio.com',
        'shopping-list.json',
      );
      setState(() {
        _isSending = true;
      });
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': enterName,
          'quantity': int.tryParse(enterQuantity)!,
          'category': choosenCategory.title,
        }),
      );
      final responseData = json.decode(response.body);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        GroceryItem(
          id: responseData['name'],
          name: enterName,
          quantity: int.tryParse(enterQuantity)!,
          category: choosenCategory,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add your new item')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(label: Text('Name')),
                validator: (value) {
                  if (value!.isEmpty || value.trim().length <= 2) {
                    return 'Enter at least 3 characters';
                  }
                },
                onSaved: (newValue) {
                  enterName = newValue!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      initialValue: '1',
                      validator: (value) {
                        if (value!.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Enter valid numbers';
                        }
                      },
                      onSaved: (newValue) {
                        enterQuantity = newValue!;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: choosenCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          choosenCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSending
                            ? null
                            : () {
                              _formKey.currentState!.reset();
                            },
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: _isSending ? null : addItem,
                    child:
                        _isSending
                            ? const CircularProgressIndicator()
                            : const Text('Add item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
