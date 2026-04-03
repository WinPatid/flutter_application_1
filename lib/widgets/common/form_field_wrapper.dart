// ไฟล์: lib/widgets/common/form_field_wrapper.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class FormFieldWrapper extends StatelessWidget {
  final String label;
  final Widget field;

  const FormFieldWrapper({
    super.key,
    required this.label,
    required this.field,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      field,
    ]);
  }
}