import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// A dropdown that opens a searchable list (dialog). Use when there are many items.
class SearchableDropdown<T> extends StatelessWidget {
  const SearchableDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemBuilder,
    required this.itemLabel,
    this.hint,
    this.labelText,
    this.searchHint = 'Search...',
    this.decoration,
  });

  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final Widget Function(T item) itemBuilder;
  /// Used for search filter and to find selected display.
  final String Function(T item) itemLabel;

  final String? hint;
  final String? labelText;
  final String searchHint;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = value != null
        ? itemBuilder(value as T)
        : (hint != null ? Text(hint!) : null);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: items.isEmpty ? null : () => _showSearchDialog(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: InputDecorator(
          decoration: decoration ??
              InputDecoration(
                labelText: labelText,
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: selectedLabel ?? const SizedBox.shrink(),
                ),
                const Icon(Icons.arrow_drop_down, color: AppConfig.subtitleColor),
              ],
            ),
        ),
      ),
    );
  }

  Future<void> _showSearchDialog(BuildContext context) async {
    String query = '';
    List<T> filtered = List.from(items);
    final searchController = TextEditingController();
    final searchFocus = FocusNode();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          void filter() {
            if (query.trim().isEmpty) {
              filtered = List.from(items);
            } else {
              final q = query.trim().toLowerCase();
              filtered = items.where((t) => itemLabel(t).toLowerCase().contains(q)).toList();
            }
          }

          return AlertDialog(
            backgroundColor: Theme.of(ctx).dialogBackgroundColor,
            title: Text(labelText ?? hint ?? 'Select'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: searchController,
                    focusNode: searchFocus,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                      ),
                    ),
                    onChanged: (v) {
                      query = v;
                      setState(filter);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        return ListTile(
                          title: itemBuilder(item),
                          onTap: () {
                            onChanged(item);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    searchController.dispose();
    searchFocus.dispose();
  }
}
