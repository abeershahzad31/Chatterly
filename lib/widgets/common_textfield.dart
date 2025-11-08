import 'package:flutter/material.dart';

class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final TextStyle? style; // ✅ allow custom text style

  const CommonTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
    this.style, // ✅ optional
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: style ?? const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: hintText, // ✅ use hint as top label (like screenshot)
        labelStyle: const TextStyle(
          color: Colors.teal,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: suffixIcon,

        // 👇 Underline style instead of outline
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black38, width: 1.2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),

        // Error text styling
        errorStyle: const TextStyle(
          fontSize: 12,
          color: Colors.red,
        ),

        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}




