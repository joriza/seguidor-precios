import 'package:flutter/material.dart';

/// Pantalla placeholder del escáner (ML Kit y alta de precio en Fase 1).
class EscanerScreen extends StatelessWidget {
  const EscanerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.qr_code_scanner, size: 64),
          SizedBox(height: 16),
          Text('Escanear — placeholder Fase 0'),
        ],
      ),
    );
  }
}
