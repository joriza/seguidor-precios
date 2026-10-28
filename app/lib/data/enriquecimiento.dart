/// T5 (S3): enriquecimiento del EAN desconocido con Open Food Facts.
///
/// Puerto [ServicioEnriquecimiento] + cliente [ServicioEnriquecimientoOFF]
/// (API v2, endpoint `product/{ean}.json`). Con conectividad, la consulta
/// precarga nombre, marca y contenido neto para el formulario del producto:
/// el usuario SIEMPRE confirma antes de guardar (nunca se guarda solo).
/// Sin conexión, sin resultado, timeout u OFF caído devuelve null y el
/// flujo manual sigue como hoy. Única dependencia nueva: `http`.
/// La atribución ODbL de OFF ya está cubierta en docs (R10).
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local/normalizacion.dart';

/// Datos precargados para el formulario de producto (confirmables).
class DatosEnriquecidos {
  const DatosEnriquecidos({
    required this.nombre,
    this.marca,
    this.contenidoNeto,
    this.unidad,
  });

  final String nombre;
  final String? marca;
  final double? contenidoNeto;

  /// Unidad de venta reconocida (de [unidadesDeVenta]) o null si `quantity`
  /// no declara una unidad utilizable.
  final String? unidad;
}

/// Puerto: consulta datos de un producto por código EAN. Null = sin datos
/// (sin conexión, sin resultado, timeout u OFF caído).
abstract interface class ServicioEnriquecimiento {
  Future<DatosEnriquecidos?> consultar(String ean);
}

/// Servicio que no consulta nada: lo usa el escáner cuando la cámara está
/// apagada (pruebas de widget, sin hardware) para que las pruebas nunca
/// toquen la red real; las que prueban enriquecimiento inyectan fakes.
class ServicioEnriquecimientoNulo implements ServicioEnriquecimiento {
  const ServicioEnriquecimientoNulo();

  @override
  Future<DatosEnriquecidos?> consultar(String ean) async => null;
}

/// Cliente de Open Food Facts (API v2). La consulta nunca lanza: cualquier
/// error se traduce en null (flujo manual intacto).
class ServicioEnriquecimientoOFF implements ServicioEnriquecimiento {
  ServicioEnriquecimientoOFF({
    http.Client? cliente,
    Future<bool> Function()? hayConexion,
    this.timeout = const Duration(seconds: 6),
    this.urlBase = 'https://world.openfoodfacts.org/api/v2/product',
  })  : _cliente = cliente,
        _hayConexion = hayConexion;

  final http.Client? _cliente;

  /// Gate de conectividad inyectable. El escáner le pasa la heurística de
  /// `red.dart` (detectarConexion); null = consultar sin gate (pruebas).
  final Future<bool> Function()? _hayConexion;

  /// Timeout corto (T5: 5-8 s) para no trabar el flujo del escáner.
  final Duration timeout;
  final String urlBase;

  @override
  Future<DatosEnriquecidos?> consultar(String ean) async {
    if (!RegExp(r'^\d{8,13}$').hasMatch(ean)) return null;
    if (_hayConexion != null && !await _hayConexion()) return null;
    final http.Client cliente = _cliente ?? http.Client();
    try {
      final http.Response respuesta = await cliente
          .get(
            Uri.parse('$urlBase/$ean.json'),
            headers: const <String, String>{
              'User-Agent': 'seguidor-precios - Android',
            },
          )
          .timeout(timeout);
      if (respuesta.statusCode != 200) return null; // 404 = no encontrado
      final Object? cuerpo = jsonDecode(respuesta.body);
      if (cuerpo is! Map<String, dynamic>) return null;
      if (cuerpo['status'] != 1) return null; // 0 = producto inexistente
      final Object? producto = cuerpo['product'];
      if (producto is! Map<String, dynamic>) return null;
      return _mapear(producto);
    } catch (_) {
      // Timeout, OFF caído, JSON inválido: null y flujo manual como hoy.
      return null;
    } finally {
      // El cliente propio (no inyectado) se cierra tras cada consulta.
      if (_cliente == null) cliente.close();
    }
  }

  /// Mapea el objeto `product` de OFF a los campos del formulario. Null si
  /// no hay nombre utilizable. Para el contenido neto se usa `quantity`
  /// (contenido del paquete); `serving_size` no mapea: es la porción, no
  /// el envase (T5).
  DatosEnriquecidos? _mapear(Map<String, dynamic> producto) {
    final String nombre = (producto['product_name_es'] ??
            producto['product_name'] ??
            '')
        .toString()
        .trim();
    if (nombre.isEmpty) return null;
    final String marcasBrutas = (producto['brands'] ?? '').toString();
    final String marca = marcasBrutas.split(',').first.trim();
    final (double? neto, String? unidad) = _cantidad(producto['quantity']);
    return DatosEnriquecidos(
      nombre: nombre,
      marca: marca.isEmpty ? null : marca,
      contenidoNeto: neto,
      unidad: unidad,
    );
  }

  /// Mejor esfuerzo sobre `quantity` ('500 g', '1,5 L', '500 mL', '10
  /// unidades'): prefiere el primer número con unidad reconocida; si no
  /// hay, toma el primer número sin unidad (el usuario confirma).
  (double?, String?) _cantidad(Object? quantity) {
    final String texto = (quantity ?? '').toString().toLowerCase();
    if (texto.isEmpty) return (null, null);
    final RegExp patron =
        RegExp(r'(\d+(?:[.,]\d+)?)\s*(kg|ml|l|g|unidades|unidad|u|m)?');
    (double, String?)? conUnidad;
    (double, String?)? sinUnidad;
    for (final RegExpMatch coincidencia in patron.allMatches(texto)) {
      final double? valor =
          double.tryParse(coincidencia.group(1)!.replaceAll(',', '.'));
      if (valor == null || valor <= 0) continue;
      final String unidad = switch (coincidencia.group(2)) {
        'kg' => 'kg',
        'ml' => 'mL',
        'l' => 'L',
        'g' => 'g',
        'm' => 'm',
        'unidades' || 'unidad' || 'u' => 'unidad',
        _ => '',
      };
      if (unidad.isNotEmpty) {
        conUnidad ??= (valor, unidad);
        break; // primer número con unidad reconocida gana
      }
      sinUnidad ??= (valor, null);
    }
    return conUnidad ?? sinUnidad ?? (null, null);
  }
}
