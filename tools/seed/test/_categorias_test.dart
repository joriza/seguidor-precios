import 'package:seed_builder/src/transformar.dart';
import 'package:test/test.dart';

/// v0.3.17 (S2, punto c): la generación de semilla emite la categoría
/// canónica. El diccionario vive espejado en transformar.dart (paquete
/// separado que no importa código de la app); el original es
/// app/lib/data/categorias.dart — mantener en sync.
void main() {
  group('categoriaCanonica (espejo del diccionario del dueño)', () {
    test('guisantes → arvejas (case-insensitive)', () {
      expect(categoriaCanonica('guisantes'), 'arvejas');
      expect(categoriaCanonica('GUISANTES'), 'arvejas');
    });

    test('chícharos → arvejas (case/acento-insensitive)', () {
      expect(categoriaCanonica('chícharos'), 'arvejas');
      expect(categoriaCanonica('Chicharos'), 'arvejas');
    });

    test('desconocida pasa tal cual; null pasa', () {
      expect(categoriaCanonica('mayonnaises'), 'mayonnaises');
      expect(categoriaCanonica(null), isNull);
    });

    test('matchea el término completo o cada segmento por coma', () {
      expect(categoriaCanonica('Guisantes, Legumbres'), 'arvejas, Legumbres');
    });
  });

  group('extraerCategoria canoniza (S2, punto c)', () {
    test('tag en: + sinónimo → canónica', () {
      expect(extraerCategoria('en:guisantes,en:spreads'), 'arvejas');
    });

    test('desconocida sigue saliendo sin el prefijo de idioma', () {
      expect(extraerCategoria('en:mayonnaises,en:spreads'), 'mayonnaises');
      expect(extraerCategoria('Mayonesas, Untables'), 'Mayonesas');
    });

    test('vacío → null', () => expect(extraerCategoria(''), isNull));
  });

  test('transformarCsv emite la categoría canónica', () {
    const cabecera =
        'code,product_name,brands,quantity,categories_tags,countries_tags\n';
    final contenido = '$cabecera'
        '7790001001001,Arvejas Marca A,Marca A,500 g,en:guisantes,en:argentina\n'
        '7790001001002,Mayonesa Marca B,Marca B,200 g,en:mayonnaises,en:argentina\n';

    final productos = transformarCsv(contenido);

    expect(productos, hasLength(2));
    expect(productos[0]['categoria'], 'arvejas');
    expect(productos[1]['categoria'], 'mayonnaises');
  });
}
