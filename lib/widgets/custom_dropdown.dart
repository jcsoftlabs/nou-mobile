import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String? value;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(
        hintText,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Colors.grey,
      ),
    );
  }
}
