import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType    = TextInputType.text,
    this.obscureText     = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines        = 1,
    this.maxLength,
    this.readOnly        = false,
    this.onTap,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.enabled         = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:      widget.controller,
      validator:       widget.validator,
      keyboardType:    widget.keyboardType,
      obscureText:     _obscure,
      maxLines:        widget.obscureText ? 1 : widget.maxLines,
      maxLength:       widget.maxLength,
      readOnly:        widget.readOnly,
      onTap:           widget.onTap,
      onChanged:       widget.onChanged,
      textInputAction: widget.textInputAction,
      focusNode:       widget.focusNode,
      enabled:         widget.enabled,
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
      decoration: InputDecoration(
        labelText:  widget.label,
        hintText:   widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixIcon,
        counterText: '',
      ),
    );
  }
}

/// Simple date picker field
class DatePickerField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const DatePickerField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label:       label,
      hint:        'YYYY-MM-DD',
      controller:  controller,
      validator:   validator,
      readOnly:    true,
      prefixIcon:  const Icon(Icons.calendar_today_rounded, size: 20),
      onTap: () async {
        final picked = await showDatePicker(
          context:      context,
          initialDate:  DateTime.now(),
          firstDate:    DateTime(2000),
          lastDate:     DateTime.now(),
          builder:      (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          controller.text = '${picked.year}-'
              '${picked.month.toString().padLeft(2, '0')}-'
              '${picked.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }
}

/// Time picker field
class TimePickerField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const TimePickerField({super.key, required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label:      label,
      hint:       'HH:MM (optional)',
      controller: controller,
      readOnly:   true,
      prefixIcon: const Icon(Icons.access_time_rounded, size: 20),
      onTap: () async {
        final picked = await showTimePicker(
          context:     context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          controller.text = '${picked.hour.toString().padLeft(2, '0')}:'
              '${picked.minute.toString().padLeft(2, '0')}';
        }
      },
    );
  }
}
