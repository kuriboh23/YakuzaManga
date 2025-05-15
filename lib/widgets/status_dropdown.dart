import 'package:flutter/material.dart';
import 'package:yakuza/utils/constants.dart';

// LEARN: A reusable dropdown widget for selecting manga status.
class StatusDropdown extends StatelessWidget {
  final String? currentStatus;
  final ValueChanged<String?> onChanged;
  final String? hintText;

  const StatusDropdown({
    super.key,
    required this.currentStatus,
    required this.onChanged,
    this.hintText = 'Select Status',
  });

  @override
  Widget build(BuildContext context) {
    // LEARN: DropdownButtonFormField is a Material Design dropdown button that
    // integrates well with Forms.
    return DropdownButtonFormField<String>(
      // LEARN: `decoration` allows customizing the appearance, like adding a label.
      decoration: InputDecoration(
        labelText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      // LEARN: `value` is the currently selected item.
      value: currentStatus,
      // LEARN: `hint` is displayed when no item is selected.
      hint: Text(hintText ?? 'Select Status'),
      isExpanded: true, // Makes the dropdown take the full width available
      // LEARN: `items` is a list of DropdownMenuItem widgets representing the choices.
      items: AppConstants.userStatuses.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      // LEARN: `onChanged` is a callback that fires when the user selects an item.
      onChanged: onChanged,
      // LEARN: Optional: Add validation
      // validator: (value) => value == null ? 'Please select a status' : null,
    );
  }
}