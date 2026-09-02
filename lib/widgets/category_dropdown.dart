import 'package:flutter/material.dart';
import '../core/constants.dart';

class CategoryDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String labelText;
  final String hintText;
  final String? Function(String?)? validator;
  final bool includeAllOption;
  final String allOptionLabel;

  const CategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = 'Category',
    this.hintText = 'Select trade category',
    this.validator,
    this.includeAllOption = false,
    this.allOptionLabel = 'All Categories',
  });

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<String>> items = [];

    if (includeAllOption) {
      items.add(
        DropdownMenuItem<String>(
          value: '',
          child: Text(allOptionLabel),
        ),
      );
    }

    items.addAll(
      AppConstants.categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }),
    );

    final effectiveValue = (value != null &&
            (value!.isEmpty ? includeAllOption : AppConstants.categories.contains(value)))
        ? value
        : null;

    return DropdownButtonFormField<String>(
      initialValue: effectiveValue,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: const Icon(Icons.handyman_outlined, size: 20),
      ),
    );
  }
}