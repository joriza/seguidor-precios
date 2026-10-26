import 'package:seed_builder/src/transformar.dart';
import 'package:test/test.dart';

void main() {
  group('esEan13', () {
    test('acepta 13 dígitos', () => expect(esEan13('7790001001001'), isTrue));
    test('rechaza cortos, largos y con letras', () {
      expect(esEan13('12345'), isFalse);
      expect(esEan13('77900010010011'), isFalse);
      expect(esEan13('7790ABC100100'), isFalse);
      expect(esEan13(''), isFalse);
    });
  });

  group('parsearCantidad', () {
    test('500 g queda en gramos', () => expect(parsearCantidad('500 g'), (500.0, 'g')));
    test('1,5 L se convierte a 1500 mL', () => expect(parsearCantidad('1,5 L'), (1500.0, 'mL')));
    test('750ml sin espacio se acepta', () => expect(parsearCantidad('750ml'), (750.0, 'mL')));
    test('1kg se convierte a 1000 g', () => expect(parsearCantidad('1kg'), (1000.0, 'g')));
    test('10 unidades → unidad', () => expect(parsearCantidad('10 unidades'), (10.0, 'unidad')));
    test('cl se convierte a mL', () => expect(parsearCantidad('25 CL'), (250.0, 'mL')));
    test('texto no interpretable → null', () => expect(parsearCantidad('pote grande'), isNull));
    test('null → null', () => expect(parsearCantidad(null), isNull));
  });

  group('extraerMarca y extraerCategoria', () {
    test('toma la primera marca', () => expect(extraerMarca('Marca A, S.A., Otra'), 'Marca A'));
    test('marcas vacías → null', () => expect(extraerMarca(''), isNull));
    test('categories_tags quita el prefijo de idioma', () {
      expect(extraerCategoria('en:mayonnaises,en:spreads'), 'mayonnaises');
    });
    test('categories plano toma la primera', () => expect(extraerCategoria('Mayonesas, Untables'), 'Mayonesas'));
    test('vacío → null', () => expect(extraerCategoria(''), isNull));
  });

  group('transformarCsv', () {
    const cabecera =
        'code,product_name,brands,quantity,categories_tags,countries_tags\n';
    final contenido = StringBuffer(cabecera)
      ..write('7790001001001,Mayonesa Marca A,"Marca A, S.A.",500 g,en:mayonnaises,en:argentina\n')
      ..write('7790001001002,Mayonesa Marca B,Marca B,"1,5 L",en:mayonnaises,en:argentina\n')
      ..write('8410001001003,Jamón de otro país,Marca X,200 g,en:meat,en:spain\n')
      ..write(',Sin código,Marca,100 g,,en:argentina\n')
      ..write('7790001001004,Sin cantidad,Marca,,en:argentina\n')
      ..write('7790001001001,Duplicado,Marca,300 g,,en:argentina\n')
      ..write('12345,Código corto,Marca,100 g,,en:argentina\n')
      ..write('7790001001099,Del export sin país declarado,Marca,250 g,,\n');

    test('filtra y normaliza según las reglas del pack', () {
      final productos = transformarCsv(contenido.toString());

      // Aceptados: los dos primeros + el que no declara país. Rechazados:
      // otro país, sin código, sin cantidad, duplicado y EAN corto.
      expect(productos, hasLength(3));

      expect(productos[0]['codigo_barras'], '7790001001001');
      expect(productos[0]['nombre'], 'Mayonesa Marca A');
      expect(productos[0]['marca'], 'Marca A');
      expect(productos[0]['unidad'], 'g');
      expect(productos[0]['contenido_neto'], 500.0);
      expect(productos[0]['categoria'], 'mayonnaises');

      expect(productos[1]['unidad'], 'mL');
      expect(productos[1]['contenido_neto'], 1500.0);

      expect(productos[2]['codigo_barras'], '7790001001099');
      expect(productos[2]['categoria'], isNull);
    });

    test('respeta el límite', () {
      expect(transformarCsv(contenido.toString(), limite: 1), hasLength(1));
    });

    test('falla si faltan columnas mínimas', () {
      expect(() => transformarCsv('marca,otro\na,b\n'), throwsArgumentError);
    });
  });

  group('armarPack', () {
    test('incluye metadatos de atribución (R10/AD-008)', () {
      final pack = armarPack(
        productos: const [],
        version: '1.0.0',
        ahora: DateTime.utc(2026, 1, 1),
      );
      expect(pack['fuente'], contains('Open Food Facts'));
      expect(pack['licencia'], 'ODbL');
      expect(pack['version'], '1.0.0');
      expect(pack['generado'], '2026-01-01T00:00:00.000Z');
      expect(pack['cantidad'], 0);
      expect(pack['productos'], isEmpty);
    });
  });
}
