import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:seed_builder/src/transformar.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'entrada',
      abbr: 'e',
      help: 'CSV de entrada (formato estándar OFF/OPF; .gz soportado)',
    )
    ..addOption('salida', abbr: 's', defaultsTo: 'catalogo.json')
    ..addOption('version-pack', defaultsTo: '0.0.0')
    ..addOption('limite', help: 'Cantidad máxima de productos (para pruebas)');
  final opciones = parser.parse(arguments);

  final entrada = opciones['entrada'] as String?;
  if (entrada == null) {
    stdout.writeln('Falta --entrada. Uso:');
    stdout.writeln(parser.usage);
    exitCode = 2;
    return;
  }

  final bytes = File(entrada).readAsBytesSync();
  final contenido = entrada.toLowerCase().endsWith('.gz')
      ? utf8.decode(gzip.decode(bytes), allowMalformed: true)
      : utf8.decode(bytes, allowMalformed: true);

  final limite = int.tryParse(opciones['limite'] as String? ?? '');
  final productos = transformarCsv(contenido, limite: limite);
  final pack = armarPack(
    productos: productos,
    version: opciones['version-pack'] as String,
  );

  final salida = opciones['salida'] as String;
  File(salida)
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(pack));
  stdout.writeln('Pack generado: ${pack['cantidad']} productos → $salida');
  stdout.writeln(
    'Atribución requerida: ${pack['fuente']} (${pack['licencia']}).',
  );
}
