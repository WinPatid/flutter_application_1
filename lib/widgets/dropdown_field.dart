// ไฟล์: lib/widgets/dropdown_field.dart
import 'package:flutter/material.dart';

class DropdownField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? currentValue;
  final Function(String?) onChanged;

  const DropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final validValue = items.contains(currentValue) ? currentValue : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: validValue,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true, fillColor: Colors.white,
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items.toSet().toList().map((e) =>
            DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 15)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}