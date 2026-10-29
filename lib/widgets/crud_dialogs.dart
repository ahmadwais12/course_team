import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';

/// Common form dialog helpers for CRUD operations
class CrudDialogs {
  /// Show Add/Edit dialog with dynamic fields
  static Future<Map<String, dynamic>?> showCrudDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required List<FormFieldData> fields,
    Map<String, dynamic>? existingData,
    IconData? icon,
    Color? iconColor,
  }) async {
    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{};

    // Initialize controllers
    for (var field in fields) {
      controllers[field.key] = TextEditingController(
        text: existingData?[field.key]?.toString() ?? field.initialValue ?? '',
      );
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: Colors.black26,
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor ?? Theme.of(context).primaryColor,
                        (iconColor ?? Theme.of(context).primaryColor)
                            .withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: fields.map((field) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildFormField(
                              context: context,
                              controller: controllers[field.key]!,
                              field: field,
                              formKey: formKey,
                              ref: ref,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        t(L.cancel, ref),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final data = <String, dynamic>{};
                          for (var entry in controllers.entries) {
                            data[entry.key] = entry.value.text.trim();
                          }
                          Navigator.pop(context, data);
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        existingData != null ? t(L.save, ref) : t(L.add, ref),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Dispose controllers
    for (var ctl in controllers.values) {
      ctl.dispose();
    }

    return result;
  }

  static Widget _buildFormField({
    required BuildContext context,
    required TextEditingController controller,
    required FormFieldData field,
    required GlobalKey<FormState> formKey,
    required WidgetRef ref,
  }) {
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      labelText: field.label,
      hintText: field.hint,
      labelStyle: TextStyle(fontSize: 15),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: field.prefixIcon,
      prefixIconColor: Colors.grey.shade600,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );

    return TextFormField(
      controller: controller,
      decoration: field.type == FormFieldType.multiline
          ? inputDecoration.copyWith(alignLabelWithHint: true)
          : field.type == FormFieldType.email
              ? inputDecoration.copyWith(
                  prefixIcon: field.prefixIcon ?? const Icon(Icons.email_outlined),
                )
              : inputDecoration,
      maxLines: field.type == FormFieldType.multiline
          ? field.maxLines ?? 3
          : field.maxLines ?? 1,
      minLines: field.type == FormFieldType.multiline ? 2 : null,
      validator: (value) {
        final customError = field.validator?.call(value);
        if (customError != null) return customError;
        switch (field.type) {
          case FormFieldType.email:
            return FormFieldData.email(value, ref);
          case FormFieldType.number:
            return FormFieldData.number(value, ref);
          case FormFieldType.phone:
            return FormFieldData.phone(value, ref);
          default:
            return null;
        }
      },
      keyboardType: field.keyboardType ?? _defaultKeyboardType(field.type),
      textInputAction: field.type == FormFieldType.multiline
          ? TextInputAction.done
          : TextInputAction.next,
      style: const TextStyle(fontSize: 15),
    );
  }

  static TextInputType _defaultKeyboardType(FormFieldType type) {
    switch (type) {
      case FormFieldType.number:
        return const TextInputType.numberWithOptions(decimal: true);
      case FormFieldType.email:
        return TextInputType.emailAddress;
      case FormFieldType.phone:
        return TextInputType.phone;
      case FormFieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  /// Show confirmation dialog
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required WidgetRef ref,
    String title = 'Delete Item',
    String message = 'Are you sure you want to delete this item?',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(LCrud.confirmDelete, ref)),
        content: Text(t(LCrud.confirmDeleteItem, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

enum FormFieldType {
  text,
  multiline,
  number,
  email,
  phone,
}

class FormFieldData {
  final String key;
  final String label;
  final String? hint;
  final FormFieldType type;
  final String? initialValue;
  final int? maxLines;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final FormFieldValidator<String>? validator;

  FormFieldData({
    required this.key,
    required this.label,
    this.hint,
    this.type = FormFieldType.text,
    this.initialValue,
    this.maxLines,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
  });

  /// Required field validator
  static String? required(String? value, [WidgetRef? ref]) {
    if (value == null || value.isEmpty) {
      return ref != null ? t(LGen.fieldRequired, ref) : 'This field is required';
    }
    return null;
  }

  /// Email validator
  static String? email(String? value, [WidgetRef? ref]) {
    if (value == null || value.isEmpty) {
      return null; // Use required validator separately
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return ref != null ? t(LGen.invalidEmailLong, ref) : 'Please enter a valid email';
    }
    return null;
  }

  /// Number validator
  static String? number(String? value, [WidgetRef? ref]) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (double.tryParse(value) == null) {
      return ref != null ? t(LGen.invalidNumber, ref) : 'Please enter a valid number';
    }
    return null;
  }

  /// Phone validator
  static String? phone(String? value, [WidgetRef? ref]) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value)) {
      return ref != null ? t(LGen.invalidPhone, ref) : 'Please enter a valid phone number';
    }
    return null;
  }
}
