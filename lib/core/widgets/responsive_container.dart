import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 800, // Ancho máximo sugerido para Web
  });

  @override
  Widget build(BuildContext context) {
    return Center( // 1. Centra el contenido en pantallas grandes
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth), // 2. Limita el ancho
        child: child,
      ),
    );
  }
}