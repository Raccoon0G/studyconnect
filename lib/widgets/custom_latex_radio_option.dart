import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class CustomLatexRadioOption extends StatelessWidget {
  final String label;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const CustomLatexRadioOption({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Math.tex(
        "$value) $label",
        textStyle: const TextStyle(fontSize: 15),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }
}
