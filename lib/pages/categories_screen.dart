import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shopping_app/pages/add_new_item.dart';

import 'package:shopping_app/providers/itemProvider.dart';
import 'package:shopping_app/widgets/custom_list_tile_skeleton.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemGrocery = ref.watch(groceryNotifierProvider);
    void goToAddNewItemScreen() async {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const AddNewItem()),
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
      body: itemGrocery.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No item yet'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (ctx, index) {
              return Dismissible(
                key: ValueKey(items[index].id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  try {
                    await ref
                        .read(groceryNotifierProvider.notifier)
                        .removeItem(items[index]);
                  } catch (e) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 15),
                  child: const Icon(Icons.delete, size: 34),
                ),
                child: ListTile(
                  title: Text(items[index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: items[index].category.color,
                  ),
                  trailing: Text('${items[index].quantity}'),
                ),
              );
            },
          );
        },
        error:
            (error, stackTrace) =>
                const Center(child: Text('Something went wrong!')),
        loading:
            () => ListView.builder(
              itemCount: 15,
              itemBuilder: (ctx, index) => const CustomListTileShimmer(),
            ),
      ),
    );
  }
}
