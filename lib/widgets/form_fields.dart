import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/formatters.dart';

/// Labeled text field used across CRM form sheets.
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool multiline;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool enabled;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.multiline = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.onTap,
    this.readOnly = false,
    this.obscureText = false,
    this.onSubmitted,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        onTap: onTap,
        onFieldSubmitted: onSubmitted,
        maxLines: multiline ? 4 : maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          alignLabelWithHint: multiline,
        ),
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        validator: validator,
      ),
    );
  }
}

/// Live "Amount in words" hint shown under a money field.
class AmountInWordsHint extends StatelessWidget {
  final TextEditingController controller;

  const AmountInWordsHint({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final words = Formatters.amountInWords(value.text);
        if (words.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Amount in words: $words',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

/// Labeled dropdown styled like AppTextField.
class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.where((o) => o.$1 == value).firstOrNull;

    final allOptions = [
      if (!selectedExists(value)) (value, value?.toString() ?? label),
      ...options,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: [
          for (final o in allOptions)
            DropdownMenuItem<T>(value: o.$1, child: Text(o.$2)),
        ],
        onChanged: enabled ? (v) => onChanged(v) : null,
        hint: Text(selected?.$2 ?? label),
      ),
    );
  }

  bool selectedExists(T? v) => v == null || options.any((o) => o.$1 == v);
}

/// Section title inside a form sheet.
class FormSection extends StatelessWidget {
  final String title;
  const FormSection({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
