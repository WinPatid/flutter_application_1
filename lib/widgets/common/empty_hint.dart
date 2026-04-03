// ไฟล์: lib/widgets/common/empty_hint.dart
import 'package:flutter/material.dart';

class EmptyHint extends StatelessWidget {
  final String text;
  final IconData icon;

  const EmptyHint({
    super.key,
    required this.text,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ],
    ));
  }
}