import 'dart:async';

import 'package:flutter/material.dart';

import 'data/local/base_de_datos.dart';
import 'data/identidad.dart';
import 'data/semilla.dart';
import 'features/articulos/articulos_screen.dart';
import 'features/busqueda/busqueda_screen.dart';
import 'features/comercios/comercios_screen.dart';
import 'features/escaner/escaner_screen.dart';
import 'features/historial/historial_screen.dart';
import 'features/inicio/inicio_screen.dart';

/// Raíz de la aplicación: tema Material 3, UI en español rioplatense (AD-007).
class SeguidorPreciosApp extends StatelessWidget {
  const SeguidorPreciosApp({super.key, required this.baseDeDatos});

  final BaseDeDatos baseDeDatos;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seguidor de Precios',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: HomeShell(baseDeDatos: baseDeDatos),
    );
  }
}

/// Shell de navegación: seis secciones; el escáner y la búsqueda consultan
/// la base (Fase 0: cinco; T12 agrega Buscar).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.baseDeDatos});

  final BaseDeDatos baseDeDatos;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// S1 (v0.1.2): contador de visitas a pestañas. Las pantallas de datos se
  /// recrean al volver a su pestaña (key cambia → initState recarga la base):
  /// sin esto, mostraban la instantánea del arranque y el historial o los
  /// comercios parecían vacíos tras registrar.
  int _visita = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pedirEtiquetaSiFalta());
  }

  /// S14 (R17): en el primer inicio pide el nombre o apodo del aportante y
  /// lo guarda en el dispositivo. Sin email ni conexión.
  /// S2 (v0.1.1): al terminar, importa el semillero si falta (segundo plano).
  Future<void> _pedirEtiquetaSiFalta() async {
    if (!await hayUsuario(widget.baseDeDatos)) {
      if (!mounted) return;

      final TextEditingController controlador = TextEditingController();
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Bienvenida/o'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                '¿Cómo te llamamos? Tu etiqueta de aportante queda guardada '
                'en el dispositivo y viaja con cada precio que cargás.',
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('campo-etiqueta'),
                controller: controlador,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre o apodo',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            FilledButton(
              key: const ValueKey('btn-guardar-etiqueta'),
              onPressed: () async {
                final String etiqueta = controlador.text.trim();
                await crearUsuarioConEtiqueta(
                  widget.baseDeDatos,
                  etiqueta.isEmpty ? 'Anónimo' : etiqueta,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    }

    // Con el usuario resuelto, el semillero entra en segundo plano: no
    // bloquea la UI y la dedup por EAN lo hace idempotente.
    unawaited(_importarSemillaSiFalta());
  }

  Future<void> _importarSemillaSiFalta() async {
    try {
      await importarSemillaDelAsset(widget.baseDeDatos);
    } catch (_) {
      // El semillero es una conveniencia: si el asset faltara o estuviera
      // corrupto, la app funciona igual con altas manuales.
    }
  }

  static const List<String> _titles = <String>[
    'Inicio',
    'Escanear',
    'Buscar',
    'Artículos',
    'Historial',
    'Comercios',
  ];

  List<Widget> _pantallas() => <Widget>[
        // Datos: recrear al volver (refresco). Escáner/Buscar: sin key —
        // no recrear la cámara ni perder la búsqueda en curso.
        InicioScreen(
          key: ValueKey('inicio-$_visita'),
          baseDeDatos: widget.baseDeDatos,
        ),
        EscanerScreen(baseDeDatos: widget.baseDeDatos),
        BusquedaScreen(baseDeDatos: widget.baseDeDatos),
        ArticulosScreen(
          key: ValueKey('articulos-$_visita'),
          baseDeDatos: widget.baseDeDatos,
        ),
        HistorialScreen(
          key: ValueKey('historial-$_visita'),
          baseDeDatos: widget.baseDeDatos,
        ),
        ComerciosScreen(
          key: ValueKey('comercios-$_visita'),
          baseDeDatos: widget.baseDeDatos,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _pantallas()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() {
          if (i != _index) {
            _index = i;
            _visita++; // refresca las pantallas de datos (S1, v0.1.2)
          }
        }),

        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Escanear',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Artículos',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Comercios',
          ),
        ],
      ),
    );
  }
}
