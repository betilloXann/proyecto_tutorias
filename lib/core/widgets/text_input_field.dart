import 'package:flutter/material.dart';

class TextInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscureText; // Cambié 'obscure' a 'obscureText' para estandarizar
  final Widget? suffixIcon;
  final TextInputType? keyboardType; // 🔹 AGREGADO: Para definir si es email, número, etc.

  const TextInputField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.obscureText = false, // Por defecto no oculta texto
    this.suffixIcon,
    this.keyboardType, // 🔹 AGREGADO al constructor
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText, // Conecta con la propiedad del TextField nativo
      keyboardType: keyboardType, // 🔹 Conecta con el teclado nativo

      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.grey)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}