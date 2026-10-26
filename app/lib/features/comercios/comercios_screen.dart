import 'package:flutter/material.dart';

/// Pantalla placeholder de comercios (se implementa en Fase 1).
class ComerciosScreen extends StatelessWidget {
  const ComerciosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.storefront, size: 64),
          SizedBox(height: 16),
          Text('Comercios — placeholder Fase 0'),
        ],
      ),
    );
  }
}
