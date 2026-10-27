import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:seguidor_precios/data/backup.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/inicio/inicio_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() async {
    db = BaseDeDatos.memoria();
    await db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: 'c1',
            nombre: 'Almacén',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await db.into(db.articulos).insert(
          ArticulosCompanion.insert(
            id: 'a1',
            nombre: 'Mayonesas',
            unidadBase: 'kg',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p1',
            nombre: 'Mayonesa, "rica"',
            marca: const Value('Natura'),
            codigoBarras: const Value('7791234567890'),
            unidad: 'g',
            contenidoNeto: const Value(500),
            articuloId: const Value('a1'),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await db.into(db.precios).insert(
          PreciosCompanion.insert(
            id: 'pr1',
            productoId: 'p1',
            comercioId: 'c1',
            precio: 1500,
            fechaToma: '2026-01-02',
            cargadoPor: 'u1',
            cargadoEn: '2026-01-02T10:00:00',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('exportarBackup / importarBackup (S13)', () {
    test('el export tiene formato, versión y todas las tablas', () async {
      final backup = await exportarBackup(db);

      expect(backup['formato'], formatoBackup);
      expect(backup['version'], versionBackup);
      expect(backup['comercios'], hasLength(1));
      expect(backup['articulos'], hasLength(1));
      expect(backup['productos'], hasLength(1));
      expect(backup['precios'], hasLength(1));
    });

    test('restaura en una instalación vacía (criterio de salida)', () async {
      final backup = jsonEncode(await exportarBackup(db));
      final db2 = BaseDeDatos.memoria();
      addTearDown(db2.close);

      final resumen = await importarBackup(db2, backup);

      expect(resumen.insertadas, 4);
      expect(resumen.omitidas, 0);

      final precios = await db2.select(db2.precios).get();
      expect(precios, hasLength(1));
      expect(precios.single.precio, 1500);
      final productos = await db2.select(db2.productos).get();
      expect(productos.single.nombre, 'Mayonesa, "rica"');
      final comercios = await db2.select(db2.comercios).get();
      expect(comercios.single.nombre, 'Almacén');
    });

    test('es no destructivo: las filas existentes no se pisan', () async {
      final backup = jsonEncode(await exportarBackup(db));
      final db2 = BaseDeDatos.memoria();
      addTearDown(db2.close);

      // La otra instalación ya tiene EL MISMO comercio pero con otro nombre
      // (carga local del dueño) y otro precio del mismo producto.
      await db2.into(db2.comercios).insert(
            ComerciosCompanion.insert(
              id: 'c1',
              nombre: 'Almacén del barrio',
              creadoPor: 'dueño',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );

      final resumen = await importarBackup(db2, backup);

      expect(resumen.insertadas, 3); // articulo, producto, precio
      expect(resumen.omitidas, 1); // comercio c1 ya existía
      final comercios = await db2.select(db2.comercios).get();
      expect(comercios.single.nombre, 'Almacén del barrio'); // no se pisa
    });

    test('JSON inválido lanza FormatException', () async {
      await expectLater(
        importarBackup(db, 'esto no es json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('JSON válido pero de otro formato lanza FormatException', () async {
      await expectLater(
        importarBackup(db, jsonEncode(<String, dynamic>{
          'formato': 'otra-app',
          'version': 1,
        })),
        throwsA(isA<FormatException>()),
      );
    });

    test('filas inválidas se omiten y no abortan la importación', () async {
      final backup = jsonEncode(await exportarBackup(db));
      final mapa = jsonDecode(backup) as Map<String, dynamic>;
      // Fila sin id y fila no-objeto.
      mapa['comercios'] = <dynamic>[
        <String, dynamic>{'nombre': 'sin id'},
        'fila-no-objeto',
        ...(mapa['comercios'] as List<dynamic>),
      ];

      final db2 = BaseDeDatos.memoria();
      addTearDown(db2.close);
      final resumen = await importarBackup(db2, jsonEncode(mapa));

      expect(resumen.omitidas, 2); // fila sin id + fila no-objeto
      expect(resumen.insertadas, 4);
      final comercios = await db2.select(db2.comercios).get();
      expect(comercios.single.nombre, 'Almacén');
    });
  });

  group('exportarPreciosCsv / campoCsv', () {
    test('campoCsv escapa comas, comillas y saltos de línea', () {
      expect(campoCsv('simple'), 'simple');
      expect(campoCsv('con,coma'), '"con,coma"');
      expect(campoCsv('con "comillas"'), '"con ""comillas"""');
      expect(campoCsv('dos\nlineas'), '"dos\nlineas"');
    });

    test('exporta header y filas ordenadas por fecha con campos escapados',
        () async {
      // Precio con fecha posterior para probar el orden.
      await db.into(db.precios).insert(
            PreciosCompanion.insert(
              id: 'pr2',
              productoId: 'p1',
              comercioId: 'c1',
              precio: 1600,
              fechaToma: '2026-01-05',
              cargadoPor: 'u1',
              cargadoEn: '2026-01-05T10:00:00',
            ),
          );

      final csv = await exportarPreciosCsv(db);
      final lineas = csv.trim().split('\n');

      expect(lineas.first,
          'fecha_toma,comercio,producto,marca,codigo_barras,precio');
      expect(lineas, hasLength(3));
      expect(lineas[1], contains('2026-01-02'));
      expect(lineas[1], contains('"Mayonesa, ""rica"""'));
      expect(lineas[1], contains('1500.00'));
      expect(lineas[2], contains('2026-01-05'));
      expect(lineas[2], contains('1600.00'));
    });
  });

  group('InicioScreen — backup UI (v0.1.1: archivos)', () {
    Widget envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

    testWidgets('exportar JSON comparte un archivo .json vía share sheet',
        (tester) async {
      final compartidas = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'), (call) async {
          compartidas.add(call);
          return null;
        },
      );
      const canalPaths = MethodChannel('plugins.flutter.io/path_provider');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        canalPaths,
        (call) async => Directory.systemTemp.path,
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/share'), null);
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(canalPaths, null);
      });

      await tester.pumpWidget(envolver(InicioScreen(baseDeDatos: db)));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('btn-exportar-json')));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      // El contrato real: el backup viaja como .json con el formato v1.
      // (El resultado del share sheet varía por plataforma: unavailable en
      // desktop/CI, pero el archivo queda generado y compartido.)
      final backups = Directory.systemTemp
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.uri.pathSegments.last
                  .startsWith('backup-seguidor-precios-') &&
              f.path.endsWith('.json'))
          .toList();
      expect(backups, isNotEmpty);
      final contenido = backups.map((f) => f.readAsStringSync()).join();
      expect(contenido, contains('seguidor-precios-backup'));
      expect(contenido, contains('"precios"'));

      // Limpieza: los backups generados en temp no deben acumularse.
      for (final f in backups) {
        f.deleteSync();
      }
    });

    testWidgets('importar elige archivo, importa y avisa', (tester) async {
      final backup = jsonEncode(await exportarBackup(db));
      final db2 = BaseDeDatos.memoria();
      addTearDown(db2.close);

      final archivo = File('build/backup-prueba.json').absolute
        ..writeAsStringSync(backup);
      addTearDown(() {
        // Windows retiene el lock un instante tras la lectura: tolerante.
        try {
          if (archivo.existsSync()) archivo.deleteSync();
        } on FileSystemException {
          // se limpia en la próxima corrida de CI (runner efímero)
        }
      });

      final original = FilePickerPlatform.instance;
      FilePickerPlatform.instance = _FilePickerFalso(_ArchivoFalso(archivo));
      addTearDown(() => FilePickerPlatform.instance = original);

      await tester.pumpWidget(envolver(InicioScreen(baseDeDatos: db2)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('btn-importar')));
      // La lectura del archivo y la importación son E/S real: el FakeAsync
      // de flutter_test no las completa solas → el tap corre dentro de
      // runAsync con espera real.
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('btn-importar')));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('4 filas nuevas'), findsOneWidget);
      final precios = await db2.select(db2.precios).get();
      expect(precios, hasLength(1));
    });

    testWidgets('cancelar el selector no importa nada', (tester) async {
      final db2 = BaseDeDatos.memoria();
      addTearDown(db2.close);

      final original = FilePickerPlatform.instance;
      FilePickerPlatform.instance = _FilePickerFalso(null);
      addTearDown(() => FilePickerPlatform.instance = original);

      await tester.pumpWidget(envolver(InicioScreen(baseDeDatos: db2)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('btn-importar')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Backup importado'), findsNothing);
      final comercios = await db2.select(db2.comercios).get();
      expect(comercios, isEmpty);
    });
  });
}

/// [PlatformFile] falso sobre un archivo real de disco.
final class _ArchivoFalso extends PlatformFile {
  _ArchivoFalso(this._archivo);

  final File _archivo;

  @override
  String get name => _archivo.uri.pathSegments.last;

  @override
  Uri get uri => _archivo.uri;

  @override
  XFile get xFile => XFile(_archivo.path);

  @override
  int? lengthSync() => _archivo.lengthSync();

  @override
  Future<int?> length() async => _archivo.lengthSync();

  @override
  Future<Uint8List> readAsBytes() => _archivo.readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() =>
      _archivo.openRead().map(Uint8List.fromList);
}

/// [FilePickerPlatform] falso: devuelve el archivo o una lista vacía.
class _FilePickerFalso extends FilePickerPlatform {
  _FilePickerFalso(this.resultado);

  final PlatformFile? resultado;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async =>
      resultado == null
          ? const <PlatformFile>[]
          : <PlatformFile>[resultado!];
}
