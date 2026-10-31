import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/productos.dart';
import 'package:seguidor_precios/data/sync/servicio_sync.dart';

import 'cliente_remoto_falso.dart';

/// S6 (v0.3.8): la sync viaja con `pack` como columna normal — el push
/// incluye el valor y el pull tolera filas del servidor sin la clave
/// (instalación vieja) entrando con el default 1. El SQL 0006 debe
/// aplicarse ANTES de instalar la release (orden de despliegue).
void main() {
  late BaseDeDatos db;
  late ClienteRemotoFalso cliente;

  const t1 = '2026-01-01T10:00:00.000Z';

  setUp(() async {
    db = BaseDeDatos.memoria();
    cliente = ClienteRemotoFalso();
    // El usuario actual lo necesitan los hooks de encolado de altaProducto.
    await crearUsuarioConEtiqueta(db, 'Nadia');
  });

  tearDown(() async {
    await db.close();
  });

  test('el push incluye pack con el valor del producto', () async {
    await altaProducto(
      db,
      nombre: 'Fideos Marca',
      unidad: 'g',
      contenidoNeto: 500,
      pack: 10,
      ahora: DateTime.parse(t1),
    );

    await sincronizarAhora(db, cliente);

    final producto = cliente.remoto['producto']!.single;
    expect(producto['nombre'], 'Fideos Marca');
    expect(producto['pack'], 10);
  });

  test('el pull acepta filas del servidor sin pack (entra en 1) y con pack',
      () async {
    cliente.sembrar('producto', <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'p-viejo-servidor',
        'codigo_barras': null,
        'articulo_id': null,
        'nombre': 'Vieja instalación',
        'marca': null,
        'categoria': null,
        'unidad': 'g',
        'contenido_neto': 500,
        'notas': null,
        'creado_por': 'u2',
        'creado_en': t1,
        'actualizado_en': t1,
        'borrado_en': null,
        // Sin clave pack: servidor aún sin el SQL 0006 aplicado.
      },
      <String, dynamic>{
        'id': 'p-pack-servidor',
        'codigo_barras': null,
        'articulo_id': null,
        'nombre': 'Con pack',
        'marca': null,
        'categoria': null,
        'unidad': 'g',
        'contenido_neto': 500,
        'notas': null,
        'creado_por': 'u2',
        'creado_en': t1,
        'actualizado_en': t1,
        'borrado_en': null,
        'pack': 5,
      },
    ]);

    await sincronizarAhora(db, cliente);

    final viejo = await (db.select(db.productos)
          ..where((p) => p.id.equals('p-viejo-servidor')))
        .getSingle();
    expect(viejo.pack, 1);
    final conPack = await (db.select(db.productos)
          ..where((p) => p.id.equals('p-pack-servidor')))
        .getSingle();
    expect(conPack.pack, 5);
  });
}
