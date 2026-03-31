// ไฟล์: lib/widgets/search_field.dart
import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> items;
  final String? initialValue;
  final Function(String) onSelected;
  final bool isDisabled;
  final Key? fieldKey;
  final bool showAllOnEmpty;

  const SearchField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.onSelected,
    this.initialValue,
    this.isDisabled = false,
    this.fieldKey,
    this.showAllOnEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13,
          color: isDisabled ? Colors.grey : const Color(0xFF495057))),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          return Autocomplete<String>(
            key: fieldKey,
            initialValue: TextEditingValue(text: initialValue ?? ''),
            displayStringForOption: (option) => option,
            optionsBuilder: (TextEditingValue tv) {
              if (isDisabled) return const Iterable<String>.empty();
              if (tv.text.isEmpty) {
                return showAllOnEmpty ? items : const Iterable<String>.empty();
              }
              return items.where((item) =>
                item.toLowerCase().contains(tv.text.toLowerCase()));
            },
            onSelected: onSelected,
            fieldViewBuilder: (context, controller, focusNode, _) {
              if (showAllOnEmpty) {
                focusNode.addListener(() {
                  if (focusNode.hasFocus) {
                    final text = controller.text;
                    controller.value = controller.value.copyWith(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  }
                });
              }
              return TextField(
                controller: controller,
                focusNode: focusNode,
                readOnly: isDisabled,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: isDisabled ? Colors.grey.shade100 : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                  suffixIcon: isDisabled ? null : const Icon(Icons.search, color: Colors.grey, size: 20),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          hoverColor: const Color(0xFFE8F0FE),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(option, style: const TextStyle(fontSize: 14)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}