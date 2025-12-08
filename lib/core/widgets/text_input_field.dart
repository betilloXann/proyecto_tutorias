import 'package:flutter/material.dart';

class TextInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final bool readOnly;

  // NUEVO: Propiedad para el icono del final (ojito)
  final Widget? suffixIcon;

  const TextInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.suffixIcon, // Lo recibimos en el constructor
  });

  @override
  Widget build(BuildContext context) {
    // Mantenemos el diseño Neumórfico original (Container con Sombras)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFDDE6F3),
            offset: Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        focusNode: focusNode,
        onFieldSubmitted: onFieldSubmitted,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: const Color(0xFF2F5A93)), // Color azul de tu tema

          // AQUI SE AGREGA EL ICONO DEL OJITO
          suffixIcon: suffixIcon,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none, // Sin borde porque usamos el Container para la sombra
          ),
          filled: true,
          fillColor: Colors.transparent, // Transparente para ver el color del Container
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      ),
    );
  }
}