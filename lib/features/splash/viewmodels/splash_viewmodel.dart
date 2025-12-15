import 'package:flutter/material.dart';

class SplashViewModel extends ChangeNotifier {
  
  /// Lista de assets críticos que queremos tener listos en memoria
  /// para evitar parpadeos o carga lenta al navegar.
  final List<String> _criticalAssets = [
    'assets/images/bienvenida.webp',
    'assets/images/consulta.webp',
    'assets/images/recuperar.webp',
    'assets/images/registro.webp',
    'assets/images/sesion.webp',
    'assets/images/app_icon.png', 
  ];

  Future<void> preloadResources(BuildContext context) async {
    final List<Future> futures = [];

    // Iniciamos la precarga de todas las imágenes en paralelo
    for (final assetPath in _criticalAssets) {
      futures.add(
        precacheImage(AssetImage(assetPath), context),
      );
    }

    // Esperamos a que TODAS terminen + un pequeño delay para que se vea el logo
    await Future.wait([
      ...futures,
      Future.delayed(const Duration(milliseconds: 1500)), // 1.5 seg de logo
    ]);
  }
}