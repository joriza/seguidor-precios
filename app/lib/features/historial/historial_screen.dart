import 'package:flutter/material.dart';

/// Pantalla placeholder del historial de precios (se implementa en Fase 1).
class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.history, size: 64),
          SizedBox(height: 16),
          Text('Historial — placeholder Fase 0'),
        ],
      ),
    );
  }
}
