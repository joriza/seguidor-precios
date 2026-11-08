/// T5 (S3): enriquecimiento del EAN desconocido con Open Food Facts.
///
/// Puerto [ServicioEnriquecimiento] + cliente [ServicioEnriquecimientoOFF]
/// (API v2, endpoint `product/{ean}.json`). Con conectividad, la consulta
/// precarga nombre, marca y contenido neto para el formulario del producto:
/// el usuario SIEMPRE confirma antes de guardar (nunca se guarda solo).
/// v0.3.14 (#13): el resultado es honesto ([ResultadoEnriquecimiento]) —
/// distingue sin conexión ([ResultadoErrorConectividad]), OFF caído
/// ([ResultadoErrorServidor]) y producto inexistente
/// ([ResultadoNoEncontrado]); el flujo manual sigue como hoy. La forma
/// plana `consultar` (null = sin datos, sin causa) queda como
/// compatibilidad. Única dependencia nueva: `http`.
/// La atribución ODbL de OFF ya está cubierta en docs (R10).
/// v0.3.15 (#13): el parser vivo acepta 'cl' (→ mL, S4) y multipack
/// «N x M unidad» / «N unidades de M unidad» → pack N + contenido M
/// canónica (S3), con precarga fill-only-empty en el formulario (S7).
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'categorias.dart';
import 'local/normalizacion.dart';

/// Datos precargados para el formulario de producto (confirmables).
class DatosEnriquecidos {
  const DatosEnriquecidos({
    required this.nombre,
    this.marca,
    this.contenidoNeto,
    this.unidad,
    this.categorias,
    this.pack,
  });

  final String nombre;
  final String? marca;
  final double? contenidoNeto;

  /// Unidad de venta reconocida (de [unidadesDeVenta]) o null si `quantity`
  /// no declara una unidad utilizable.
  final String? unidad;

  /// v0.3.9 (S1): string crudo de categorías de OFF (ej.: «Snacks, Sweet
  /// snacks, Biscuits, Cookies»), precargado en producto.categoria; es la
  /// materia prima del motor de sugerencia (data/clasificacion.dart).
  final String? categorias;

  /// v0.3.15 (S3): unidades por pack declaradas por OFF en un multipack
  /// («2 x 475 ml» → 2; «6 unidades de 500 ml» → 6). Null si `quantity`
  /// no declara multipack: el formulario sólo precarga el campo pack si
  /// está en su default 1 (fill-only-empty, S7).
  final int? pack;
}

/// v0.3.14 (S2-S5): resultado honesto de la consulta OFF. La causa viaja
/// en el resultado y nunca se traga: el escáner puede mostrar «sin
/// conexión», «OFF no respondió» o «no está en OFF» en vez de un mismo
/// silencio (S3/S4/S5).
sealed class ResultadoEnriquecimiento {
  const ResultadoEnriquecimiento();
}

/// Se consultó y OFF trajo datos precargables (el usuario SIEMPRE
/// confirma antes de guardar, regla v0.3.11).
class ResultadoDatos extends ResultadoEnriquecimiento {
  const ResultadoDatos(this.datos);

  final DatosEnriquecidos datos;
}

/// Se consultó y el producto no está en OFF (status != 1, sin `product`
/// o sin nombre utilizable). Flujo manual intacto (S5).
class ResultadoNoEncontrado extends ResultadoEnriquecimiento {
  const ResultadoNoEncontrado();
}

/// La consulta se OMITIÓ: el gate de conectividad no detectó interfaces
/// (S3).
class ResultadoErrorConectividad extends ResultadoEnriquecimiento {
  const ResultadoErrorConectividad();
}

/// Se consultó y OFF falló: HTTP != 200, timeout o respuesta inválida
/// (S4).
class ResultadoErrorServidor extends ResultadoEnriquecimiento {
  const ResultadoErrorServidor();
}

/// Multipack OFF (v0.3.15 S3): «N x M unidad» o «N unidades de M
/// unidad». La unidad métrica se captura aparte (group 3).
final RegExp _patronMultipack = RegExp(
  r'(\d+)\s*(?:x|unidades?\s+de)\s*(\d+(?:[.,]\d+)?)\s*(kg|cl|ml|l|g)?',
);

/// Unidad cruda de OFF → (unidad de venta, factor de conversión del
/// valor). v0.3.15 (S4): 'cl' se acepta y pasa a mL (×10); kg, L, m y
/// unidad quedan como unidad de venta (las acepta el formulario).
const Map<String, (String, double)> _unidadesDeVenta =
    <String, (String, double)>{
  'kg': ('kg', 1),
  'ml': ('mL', 1),
  'cl': ('mL', 10),
  'l': ('L', 1),
  'g': ('g', 1),
  'm': ('m', 1),
  'unidades': ('unidad', 1),
  'unidad': ('unidad', 1),
  'u': ('unidad', 1),
};

/// Contenido por unidad del multipack → canónica {g, mL} (v0.3.15 S3).
/// Null si el valor o la unidad no son métrica reconocida.
(double, String)? _aCanonica(double? valor, String? unidad) =>
    switch (unidad) {
      'kg' => valor == null ? null : (valor * 1000, 'g'),
      'cl' => valor == null ? null : (valor * 10, 'mL'),
      'ml' => valor == null ? null : (valor, 'mL'),
      'l' => valor == null ? null : (valor * 1000, 'mL'),
      'g' => valor == null ? null : (valor, 'g'),
      _ => null,
    };

/// Puerto: consulta datos de un producto por código EAN con resultado
/// honesto (v0.3.14, S2). Nunca lanza: la causa viaja en el resultado.
abstract interface class ServicioEnriquecimiento {
  Future<ResultadoEnriquecimiento> consultarConResultado(String ean);
}

/// Servicio que no consulta nada: lo usa el escáner cuando la cámara está
/// apagada (pruebas de widget, sin hardware) para que las pruebas nunca
/// toquen la red real; las que prueban enriquecimiento inyectan fakes.
class ServicioEnriquecimientoNulo implements ServicioEnriquecimiento {
  const ServicioEnriquecimientoNulo();

  @override
  Future<ResultadoEnriquecimiento> consultarConResultado(String ean) async =>
      const ResultadoNoEncontrado();

  /// Compatibilidad (v0.3.14): forma plana histórica del puerto.
  Future<DatosEnriquecidos?> consultar(String ean) async => null;
}

/// Cliente de Open Food Facts (API v2). La consulta nunca lanza: la causa
/// viaja en [ResultadoEnriquecimiento] (v0.3.14), flujo manual intacto.
class ServicioEnriquecimientoOFF implements ServicioEnriquecimiento {
  ServicioEnriquecimientoOFF({
    http.Client? cliente,
    Future<bool> Function()? hayConexion,
    this.timeout = const Duration(seconds: 6),
    this.urlBase = 'https://world.openfoodfacts.org/api/v2/product',
  })  :
        // ignore: prefer_initializing_formals
        _cliente = cliente,
        // ignore: prefer_initializing_formals
        _hayConexion = hayConexion;

  final http.Client? _cliente;

  /// Gate de conectividad inyectable. El escáner le pasa la heurística de
  /// `red.dart` (detectarConexion); null = consultar sin gate (pruebas).
  final Future<bool> Function()? _hayConexion;

  /// Timeout corto (T5: 5-8 s) para no trabar el flujo del escáner.
  final Duration timeout;
  final String urlBase;

  @override
  Future<ResultadoEnriquecimiento> consultarConResultado(String ean) async {
    if (!RegExp(r'^\d{8,13}$').hasMatch(ean)) {
      return const ResultadoNoEncontrado(); // EAN inválido: nada que consultar
    }
    if (_hayConexion != null && !await _hayConexion()) {
      // S3 (v0.3.14): la consulta se omitió por conectividad — causa
      // explícita, no un null que confunde con «no está en OFF».
      return const ResultadoErrorConectividad();
    }
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
      // S4 (v0.3.14): cualquier HTTP != 200 es OFF que no respondió bien
      // (la API v2 responde 200 con status 0 si el producto no existe).
      if (respuesta.statusCode != 200) return const ResultadoErrorServidor();
      final Object? cuerpo = jsonDecode(respuesta.body);
      if (cuerpo is! Map<String, dynamic>) {
        return const ResultadoErrorServidor(); // respondió basura
      }
      if (cuerpo['status'] != 1) return const ResultadoNoEncontrado();
      final Object? producto = cuerpo['product'];
      if (producto is! Map<String, dynamic>) {
        return const ResultadoNoEncontrado();
      }
      final DatosEnriquecidos? datos = _mapear(producto);
      if (datos == null) return const ResultadoNoEncontrado();
      return ResultadoDatos(datos);
    } catch (_) {
      // Timeout, OFF caído, JSON inválido: errorServidor (S4), nunca lanza.
      return const ResultadoErrorServidor();
    } finally {
      // El cliente propio (no inyectado) se cierra tras cada consulta.
      if (_cliente == null) cliente.close();
    }
  }

  /// Compatibilidad (v0.3.14): forma plana histórica del puerto — null =
  /// sin datos, sin distinción de causa. El escáner y el formulario ya
  /// usan [consultarConResultado]; el método queda para el contrato
  /// anterior (pruebas unitarias existentes).
  Future<DatosEnriquecidos?> consultar(String ean) async {
    final ResultadoEnriquecimiento resultado =
        await consultarConResultado(ean);
    return switch (resultado) {
      ResultadoDatos(:final datos) => datos,
      _ => null,
    };
  }

  /// Mapea el objeto `product` de OFF a los campos del formulario. Null si
  /// no hay nombre utilizable. Para el contenido neto se usa `quantity`
  /// (contenido del paquete; en multipack, contenido por unidad con su
  /// pack, v0.3.15 S3); `serving_size` no mapea: es la porción, no
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
    final (double? neto, String? unidad, int? pack) =
        _cantidad(producto['quantity']);
    // v0.3.9 (S1): la categoría cruda de OFF ya no se descarta: precarga
    // producto.categoria y alimenta la sugerencia de artículo.
    // v0.3.17 (S2-a): entra canónica (diccionario del dueño en
    // data/categorias.dart); lo desconocido queda tal cual (S6).
    final String categoriasBrutas =
        (producto['categories'] ?? '').toString().trim();
    return DatosEnriquecidos(
      nombre: nombre,
      marca: marca.isEmpty ? null : marca,
      contenidoNeto: neto,
      unidad: unidad,
      pack: pack,
      categorias: categoriasBrutas.isEmpty
          ? null
          : categoriaCanonica(categoriasBrutas),
    );
  }

  /// Mejor esfuerzo sobre `quantity` ('500 g', '1,5 L', '35 cl', '2 x 475
  /// ml', '6 unidades de 500 ml', '10 unidades'): v0.3.15 (S3) prefiere
  /// el multipack — pack = N y contenido por unidad = M en canónica
  /// {g, mL} (el precio normalizado ya multiplica pack × contenido);
  /// si no, el primer número con unidad reconocida — 'cl' se acepta y
  /// pasa a mL (×10, S4); kg, L, m y unidad quedan como unidad de venta;
  /// si no hay, toma el primer número sin unidad (el usuario confirma).
  /// Devuelve (contenido, unidad, pack) — pack null salvo multipack.
  (double?, String?, int?) _cantidad(Object? quantity) {
    final String texto = (quantity ?? '').toString().toLowerCase();
    if (texto.isEmpty) return (null, null, null);

    // Multipack (S3): «N x M unidad» o «N unidades de M unidad» métrica
    // → modelo pack v0.3.8: pack = N, contenido por unidad = M.
    final RegExpMatch? multipack = _patronMultipack.firstMatch(texto);
    if (multipack != null) {
      final int? pack = int.tryParse(multipack.group(1)!);
      final double? contenido =
          double.tryParse(multipack.group(2)!.replaceAll(',', '.'));
      final (double, String)? canonica = _aCanonica(contenido,
          multipack.group(3));
      if (pack != null && pack > 0 && canonica != null) {
        return (canonica.$1, canonica.$2, pack);
      }
    }

    final RegExp patron =
        RegExp(r'(\d+(?:[.,]\d+)?)\s*(kg|ml|cl|l|g|unidades|unidad|u|m)?');
    (double, String?, int?)? conUnidad;
    (double, String?, int?)? sinUnidad;
    for (final RegExpMatch coincidencia in patron.allMatches(texto)) {
      final double? valor =
          double.tryParse(coincidencia.group(1)!.replaceAll(',', '.'));
      if (valor == null || valor <= 0) continue;
      final (String, double)? venta =
          _unidadesDeVenta[coincidencia.group(2)];
      if (venta != null) {
        conUnidad ??= (valor * venta.$2, venta.$1, null);
        break; // primer número con unidad reconocida gana
      }
      sinUnidad ??= (valor, null, null);
    }
    return conUnidad ?? sinUnidad ?? (null, null, null);
  }
}
