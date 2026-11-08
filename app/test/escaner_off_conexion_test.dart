import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seguidor_precios/data/enriquecimiento.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/escaner/escaner_screen.dart';
import 'package:seguidor_precios/features/sync/red.dart';

/// v0.3.14 (#13): la consulta OFF es honesta — distingue sin conexión
/// (S3), OFF caído (S4), «no está en OFF» (S5) y datos (S2). El escáner
/// muestra el mensaje que corresponde con «Reintentar» (S6) y el gate de
/// conectividad no bloquea por una excepción de detección (S7). Nada
/// guarda solo (S8): sin red real — fakes del puerto y MockClient.

/// Servicio falso que cuenta consultas y devuelve un resultado fijo.
class ServicioConResultado implements ServicioEnriquecimiento {
  ServicioConResultado(this.resultado);

  final ResultadoEnriquecimiento resultado;
  int consultas = 0;

  @override
  Future<ResultadoEnriquecimiento> consultarConResultado(String ean) async {
    consultas++;
    return resultado;
  }
}

/// Servicio falso que devuelve resultados en secuencia (para S6: la primera
/// búsqueda falla y el reintento trae datos).
class ServicioEnSecuencia implements ServicioEnriquecimiento {
  ServicioEnSecuencia(this.resultados);

  final List<ResultadoEnriquecimiento> resultados;
  int consultas = 0;

  @override
  Future<ResultadoEnriquecimiento> consultarConResultado(String ean) async {
    final int indice =
        consultas < resultados.length ? consultas : resultados.length - 1;
    consultas++;
    return resultados[indice];
  }
}

void main() {
  const String ean = '7790001001999';

  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  DatosEnriquecidos datosDulce() => const DatosEnriquecidos(
        nombre: 'Dulce de leche',
        marca: 'La Salteña',
        contenidoNeto: 500,
        unidad: 'g',
      );

  String cuerpoDulce() =>
      '{"status": 1, "code": "$ean", "product": {'
      '"product_name": "Dulce de leche", "brands": "La Salteña", '
      '"quantity": "500 g"}}';

  /// Mock que graba la URI consultada y responde con el cuerpo dado.
  (http.Client, List<Uri>) clienteQueResponde(
    int statusCode,
    String cuerpo,
  ) {
    final List<Uri> consultas = <Uri>[];
    final http.Client cliente = MockClient((http.Request request) async {
      consultas.add(request.url);
      return http.Response(cuerpo, statusCode);
    });
    return (cliente, consultas);
  }

  /// Detección de interfaces que falla (S7: el sistema no coopera).
  Future<List<NetworkInterface>> listarQueLanza({
    bool includeLoopback = false,
    bool includeLinkLocal = false,
  }) async =>
      throw Exception('interfaces no disponibles');

  /// Detección que no ve ninguna interfaz (modo avión real).
  Future<List<NetworkInterface>> listarVacio({
    bool includeLoopback = false,
    bool includeLinkLocal = false,
  }) async =>
      const <NetworkInterface>[];

  Future<int> cantidadProductos() async =>
      (await db.select(db.productos).get()).length;

  Widget envolver(EscanerScreen pantalla) => MaterialApp(
        home: Scaffold(body: pantalla),
      );

  Future<void> buscarEan(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), ean);
    await tester.tap(find.text('Buscar producto'));
    await tester.pumpAndSettle();
  }

  group('ServicioEnriquecimientoOFF.consultarConResultado — mapa honesto (T1/S2)', () {
    test('gate en false devuelve errorConectividad y no consulta', () async {
      final (http.Client cliente, List<Uri> consultas) =
          clienteQueResponde(200, cuerpoDulce());

      final ResultadoEnriquecimiento resultado = await ServicioEnriquecimientoOFF(
        cliente: cliente,
        hayConexion: () async => false,
      ).consultarConResultado(ean);

      expect(resultado, isA<ResultadoErrorConectividad>());
      expect(consultas, isEmpty); // ningún request salió del dispositivo
    });

    test('HTTP != 200 (OFF caído) devuelve errorServidor', () async {
      final (http.Client cliente, _) = clienteQueResponde(500, 'boom');

      final ResultadoEnriquecimiento resultado = await ServicioEnriquecimientoOFF(
        cliente: cliente,
      ).consultarConResultado(ean);

      expect(resultado, isA<ResultadoErrorServidor>());
    });

    test('timeout devuelve errorServidor', () async {
      final http.Client cliente = MockClient((http.Request request) async {
        throw TimeoutException('OFF no responde');
      });

      final ResultadoEnriquecimiento resultado = await ServicioEnriquecimientoOFF(
        cliente: cliente,
      ).consultarConResultado(ean);

      expect(resultado, isA<ResultadoErrorServidor>());
    });

    test('status != 1 devuelve noEncontrado', () async {
      final (http.Client cliente, List<Uri> consultas) =
          clienteQueResponde(200, '{"status": 0, "code": "$ean"}');

      final ResultadoEnriquecimiento resultado = await ServicioEnriquecimientoOFF(
        cliente: cliente,
      ).consultarConResultado(ean);

      expect(resultado, isA<ResultadoNoEncontrado>());
      expect(consultas, hasLength(1)); // SÍ se consultó
    });

    test('producto sin nombre utilizable devuelve noEncontrado', () async {
      final (http.Client cliente, _) = clienteQueResponde(
          200,
          '{"status": 1, "product": {"brands": "Marca sin nombre"}}');

      final ResultadoEnriquecimiento resultado = await ServicioEnriquecimientoOFF(
        cliente: cliente,
      ).consultarConResultado(ean);

      expect(resultado, isA<ResultadoNoEncontrado>());
    });

    test('éxito devuelve datos con el producto mapeado', () async {
      final (http.Client cliente, List<Uri> consultas) =
          clienteQueResponde(200, cuerpoDulce());

      final ResultadoEnriquecimiento resultado = await ServicioEnriquecimientoOFF(
        cliente: cliente,
      ).consultarConResultado(ean);

      expect(resultado, isA<ResultadoDatos>());
      expect((resultado as ResultadoDatos).datos.nombre, 'Dulce de leche');
      expect(resultado.datos.marca, 'La Salteña');
      expect(resultado.datos.contenidoNeto, 500);
      expect(resultado.datos.unidad, 'g');
      expect(consultas, hasLength(1));
    });

    test(
        'compatibilidad: la forma plana consultar() sigue devolviendo '
        'datos o null (sin causa)', () async {
      final (http.Client conDatos, _) = clienteQueResponde(200, cuerpoDulce());
      final (http.Client sinProducto, _) =
          clienteQueResponde(200, '{"status": 0}');

      expect(
        await ServicioEnriquecimientoOFF(cliente: conDatos).consultar(ean),
        isA<DatosEnriquecidos>(),
      );
      expect(
        await ServicioEnriquecimientoOFF(cliente: sinProducto).consultar(ean),
        isNull,
      );
    });
  });

  group('Gate de conectividad con detección fallida (T2/S7)', () {
    test('excepción de detección se clasifica como desconocida, no ninguna',
        () async {
      final TipoConexion conexion = await detectarConexion(
        listarInterfaces: listarQueLanza,
      );
      expect(conexion, TipoConexion.desconocida);
      expect(conexion, isNot(TipoConexion.ninguna));
    });

    test('excepción de detección NO bloquea la consulta (se consulta igual)',
        () async {
      final bool hayConexion = await hayConexionParaConsulta(
        listarInterfaces: listarQueLanza,
      );
      expect(hayConexion, isTrue);
    });

    test('sin interfaces (modo avión real) sigue siendo ninguna y bloquea',
        () async {
      final TipoConexion conexion = await detectarConexion(
        listarInterfaces: listarVacio,
      );
      expect(conexion, TipoConexion.ninguna);

      final bool hayConexion = await hayConexionParaConsulta(
        listarInterfaces: listarVacio,
      );
      expect(hayConexion, isFalse);
    });
  });

  group('Escaner — mensajes honestos S3/S4, Reintentar S6, S5 intacto', () {
    testWidgets(
        'S3: sin conexión muestra el mensaje exacto con Reintentar y no guarda solo',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(envolver(
        EscanerScreen(
          baseDeDatos: db,
          mostrarCamara: false,
          enriquecimiento:
              ServicioConResultado(const ResultadoErrorConectividad()),
        ),
      ));

      await buscarEan(tester);

      expect(
        find.text(
            'Sin conexión: no se pudo consultar Open Food. Conectate y volvé a buscar.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
      // El flujo manual queda intacto: el dueño puede crear el producto.
      expect(find.text('Crear producto'), findsOneWidget);
      // S8: nada se guarda solo.
      expect(await cantidadProductos(), 0);
    });

    testWidgets(
        'S4: OFF no respondió muestra el mensaje exacto con Reintentar',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(envolver(
        EscanerScreen(
          baseDeDatos: db,
          mostrarCamara: false,
          enriquecimiento:
              ServicioConResultado(const ResultadoErrorServidor()),
        ),
      ));

      await buscarEan(tester);

      expect(
        find.text('Open Food no respondió. Reintentá la búsqueda.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Crear producto'), findsOneWidget);
      expect(await cantidadProductos(), 0);
    });

    testWidgets(
        'S5: noEncontrado mantiene el comportamiento actual (sin mensaje OFF ni Reintentar)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(envolver(
        EscanerScreen(
          baseDeDatos: db,
          mostrarCamara: false,
          enriquecimiento:
              ServicioConResultado(const ResultadoNoEncontrado()),
        ),
      ));

      await buscarEan(tester);

      expect(
        find.textContaining('No existe un producto con ese código'),
        findsOneWidget,
      );
      expect(
        find.text(
            'Sin conexión: no se pudo consultar Open Food. Conectate y volvé a buscar.'),
        findsNothing,
      );
      expect(
        find.text('Open Food no respondió. Reintentá la búsqueda.'),
        findsNothing,
      );
      expect(find.text('Reintentar'), findsNothing);
      expect(await cantidadProductos(), 0);
    });

    testWidgets(
        'S6: Reintentar repite la búsqueda completa (local + OFF) sin reescribir el código',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final ServicioEnSecuencia servicio = ServicioEnSecuencia(<ResultadoEnriquecimiento>[
        const ResultadoErrorServidor(), // primera búsqueda: OFF caído
        ResultadoDatos(datosDulce()), // reintento: trae datos
      ]);
      await tester.pumpWidget(envolver(
        EscanerScreen(
          baseDeDatos: db,
          mostrarCamara: false,
          enriquecimiento: servicio,
        ),
      ));

      await buscarEan(tester);
      expect(servicio.consultas, 1);
      expect(
        find.text('Open Food no respondió. Reintentá la búsqueda.'),
        findsOneWidget,
      );

      // El código sigue en el campo: el usuario no reescribe nada.
      final TextField campo = tester.widget(find.byType(TextField));
      expect(campo.controller!.text, ean);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      // La búsqueda completa se repitió: segunda consulta OFF…
      expect(servicio.consultas, 2);
      // …el error desapareció y la precarga quedó disponible.
      expect(
        find.text('Open Food no respondió. Reintentá la búsqueda.'),
        findsNothing,
      );
      expect(find.textContaining('Open Food Facts'), findsOneWidget);
      // S8: el reintento tampoco guarda solo.
      expect(await cantidadProductos(), 0);
    });

    testWidgets(
        'S7 extremo a extremo: una detección que lanza no bloquea la precarga',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (http.Client cliente, List<Uri> consultas) =
          clienteQueResponde(200, cuerpoDulce());
      await tester.pumpWidget(envolver(
        EscanerScreen(
          baseDeDatos: db,
          mostrarCamara: false,
          enriquecimiento: ServicioEnriquecimientoOFF(
            cliente: cliente,
            // El gate real de red.dart, con interfaces que fallan.
            hayConexion: () => hayConexionParaConsulta(
              listarInterfaces: listarQueLanza,
            ),
          ),
        ),
      ));

      await buscarEan(tester);

      // Se consultó igual y la precarga quedó disponible.
      expect(find.textContaining('Open Food Facts'), findsOneWidget);
      expect(consultas, hasLength(1));
      expect(await cantidadProductos(), 0);
    });
  });
}
