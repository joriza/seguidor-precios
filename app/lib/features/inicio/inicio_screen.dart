import 'package:flutter/material.dart';

/// Pantalla placeholder de Inicio (se implementa en Fase 1).
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.home, size: 64),
          SizedBox(height: 16),
          Text('Inicio — placeholder Fase 0'),
        ],
      ),
    );
  }
}
