import 'dart:async';

import 'package:flutter/material.dart';

import 'data/local/base_de_datos.dart';
import 'data/identidad.dart';
import 'data/semilla.dart';
import 'data/sync/servicio_sync.dart';
import 'features/articulos/articulos_screen.dart';
import 'features/busqueda/busqueda_screen.dart';
import 'features/comercios/comercios_screen.dart';
import 'features/escaner/escaner_screen.dart';
import 'features/historial/historial_screen.dart';
import 'features/inicio/inicio_screen.dart';
import 'features/sync/gestor_sync.dart';
import 'features/sync/indicador_sync.dart';

/// Raíz de la aplicación: tema Material 3, UI en español rioplatense (AD-007).
class SeguidorPreciosApp extends StatelessWidget {
  const SeguidorPreciosApp({
    super.key,
    required this.baseDeDatos,
    this.gestorSync,
  });

  final BaseDeDatos baseDeDatos;

  /// T4: gestor de sync inyectable (los tests usan fakes, sin red). Si no
  /// viene, se crea uno con la configuración real: mientras haya
  /// placeholders es un no-op silencioso — la app se usa igual sin nube
  /// (R3) y nada del arranque toca la red.
  final GestorSync? gestorSync;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seguidor de Precios',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: HomeShell(
        baseDeDatos: baseDeDatos,
        gestorSync: gestorSync ?? GestorSync(baseDeDatos: baseDeDatos),
      ),
    );
  }
}

/// Shell de navegación: seis secciones; el escáner y la búsqueda consultan
/// la base (Fase 0: cinco; T12 agrega Buscar).
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.baseDeDatos,
    required this.gestorSync,
  });

  final BaseDeDatos baseDeDatos;

  /// T4: ping (R14), aviso de sync (R15), indicador y sync manual.
  final GestorSync gestorSync;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // S5 (v0.3.5): el uso principal es escanear para consultar/agregar — la
  // app abre en el escáner; Inicio queda a un toque en la barra.
  int _index = 1;

  /// S1 (v0.1.2): contador de visitas a pestañas. Las pantallas de datos se
  /// recrean al volver a su pestaña (key cambia → initState recarga la base):
  /// sin esto, mostraban la instantánea del arranque y el historial o los
  /// comercios parecían vacíos tras registrar.
  int _visita = 0;

  /// T4: estado de sync del indicador; se carga al arrancar y se refresca
  /// al cambiar de pestaña y tras cada sincronización.
  EstadoSync _estadoSync = const EstadoSync(habilitado: false);
  bool _sincronizando = false;

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
    // T4: ping R14 y aviso condicionado R15. Sin backend configurado es un
    // no-op silencioso: la app se usa igual (R3).
    unawaited(_arranqueRed());
  }

  Future<void> _importarSemillaSiFalta() async {
    try {
      await importarSemillaDelAsset(widget.baseDeDatos);
    } catch (_) {
      // El semillero es una conveniencia: si el asset faltara o estuviera
      // corrupto, la app funciona igual con altas manuales.
    }
  }

  // ---------------------------------------------------------------------
  // T4 — UX de red (R14/R15): ping al iniciar, aviso con confirmación,
  // indicador de estado y sync manual. La sync nunca es automática.
  // ---------------------------------------------------------------------

  /// Arranque de red: ping R14 con cualquier conectividad y, solo con WiFi
  /// + (outbox pendiente o >7 días sin sync), aviso R15 con confirmación.
  Future<void> _arranqueRed() async {
    final ArranqueRed arranque = await widget.gestorSync.alIniciar();
    await _refrescarEstadoSync();
    if (!arranque.avisoPendiente || !mounted) return;
    await _mostrarAvisoSync();
  }

  Future<void> _refrescarEstadoSync() async {
    final EstadoSync estado = await widget.gestorSync.estado();
    if (!mounted) return;
    setState(() => _estadoSync = estado);
  }

  /// Aviso R15: nunca sincroniza sin confirmación explícita del usuario.
  Future<void> _mostrarAvisoSync() async {
    final EstadoSync estado = await widget.gestorSync.estado();
    if (!mounted) return;
    final bool hayPendientes = (estado.pendientes ?? 0) > 0;
    final bool? sincronizar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogo) => AlertDialog(
        key: const ValueKey('dialogo-aviso-sync'),
        title: const Text('¿Sincronizar con la nube?'),
        content: Text(
          hayPendientes
              ? 'Tenés ${estado.pendientes} cambio(s) sin sincronizar. ¿Los '
                  'compartís con el grupo ahora? Puedes hacerlo después '
                  'desde el ícono de nube.'
              : 'Hace más de $diasParaAvisarSync días que no sincronizás. '
                  '¿Querés traer las novedades del grupo ahora? También '
                  'podés hacerlo después desde el ícono de nube.',
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey('btn-sync-mas-tarde'),
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Más tarde'),
          ),
          FilledButton(
            key: const ValueKey('btn-sync-ahora'),
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Sincronizar'),
          ),
        ],
      ),
    );
    if (sincronizar == true && mounted) {
      await _sincronizar(mostrarResultado: true);
    }
  }

  /// Sync manual o confirmada: la única vía por la que viajan datos
  /// (R15). Al terminar refresca el indicador y las listas de datos.
  Future<void> _sincronizar({bool mostrarResultado = false}) async {
    if (_sincronizando || !widget.gestorSync.habilitado) return;
    setState(() => _sincronizando = true);
    final ResultadoSync? resultado = await widget.gestorSync.sincronizar();
    if (!mounted) return;
    setState(() {
      _sincronizando = false;
      _visita++; // las pantallas de datos se recrean con lo recién bajado
    });
    unawaited(_refrescarEstadoSync());
    if (mostrarResultado) {
      final Object? detalle =
          resultado == null ? widget.gestorSync.ultimoError : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado == null
                ? 'No se pudo sincronizar; tus datos están a salvo en el '
                    'dispositivo.\n$detalle'
                : 'Sincronización completa: ${resultado.filasSubidas} '
                    'subida(s), ${resultado.filasDescargadas} '
                    'descargada(s).',
          ),
        ),
      );
    }
  }

  /// Diálogo del indicador: estado de sync y, si hay backend, sync manual.
  Future<void> _dialogoEstadoSync() async {
    final EstadoSync estado = await widget.gestorSync.estado();
    if (!mounted) return;
    final bool? sincronizar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogo) => AlertDialog(
        key: const ValueKey('dialogo-estado-sync'),
        title: const Text('Sincronización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              estado.habilitado
                  ? 'Nube colaborativa configurada.'
                  : 'Sin nube configurada: la app funciona 100% en este '
                      'dispositivo.',
            ),
            const SizedBox(height: 8),
            Text('Cambios pendientes de subir: ${estado.pendientes ?? 0}'),
            Text(
              'Última sync exitosa: ${estado.ultimoSyncExitoso == null ? 'nunca' : textoFechaSync(estado.ultimoSyncExitoso!)}',
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cerrar'),
          ),
          if (estado.habilitado)
            FilledButton(
              key: const ValueKey('btn-sync-dialogo'),
              onPressed: () => Navigator.pop(dialogo, true),
              child: const Text('Sincronizar ahora'),
            ),
        ],
      ),
    );
    if (sincronizar == true && mounted) {
      await _sincronizar(mostrarResultado: true);
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
          gestorSync: widget.gestorSync,
        ),
        EscanerScreen(baseDeDatos: widget.baseDeDatos),
        BusquedaScreen(baseDeDatos: widget.baseDeDatos),
        ArticulosScreen(
          key: ValueKey('articulos-$_visita'),
          baseDeDatos: widget.baseDeDatos,
          gestorSync: widget.gestorSync,
        ),
        HistorialScreen(
          key: ValueKey('historial-$_visita'),
          baseDeDatos: widget.baseDeDatos,
          gestorSync: widget.gestorSync,
        ),
        ComerciosScreen(
          key: ValueKey('comercios-$_visita'),
          baseDeDatos: widget.baseDeDatos,
          gestorSync: widget.gestorSync,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          // T4: indicador de sync + sync manual desde su diálogo.
          IconButton(
            key: const ValueKey('indicador-sync'),
            tooltip: textoTooltipSync(_estadoSync),
            onPressed: _sincronizando ? null : _dialogoEstadoSync,
            icon: _sincronizando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(iconoSync(_estadoSync)),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pantallas()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() {
          if (i != _index) {
            _index = i;
            _visita++; // refresca las pantallas de datos (S1, v0.1.2)
          }
          unawaited(_refrescarEstadoSync()); // T4: indicador al día
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
