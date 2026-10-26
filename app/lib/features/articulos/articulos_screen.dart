import 'package:flutter/material.dart';

/// Pantalla placeholder de artículos y comparador (se implementa en Fase 1).
class ArticulosScreen extends StatelessWidget {
  const ArticulosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.category, size: 64),
          SizedBox(height: 16),
          Text('Artículos — placeholder Fase 0'),
        ],
      ),
    );
  }
}
