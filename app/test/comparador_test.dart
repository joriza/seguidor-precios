import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/features/precios/comparador.dart';

FilaComparacion fila({
  required String nombre,
  required String comercio,
  required double precioUnitario,
  String? marca,
  double precio = 0,
}) {
  return FilaComparacion(
    productoNombre: nombre,
    marca: marca,
    comercioNombre: comercio,
    precio: precio,
    precioUnitario: precioUnitario,
  );
}

void main() {
  group('ordenarPorPrecioUnitario', () {
    test('ordena de menor a mayor precio por unidad', () {
      final filas = <FilaComparacion>[
        fila(nombre: 'B 250 g', comercio: 'Kiosco', precioUnitario: 3600),
        fila(nombre: 'A 1 kg', comercio: 'Almacén', precioUnitario: 2700),
        fila(nombre: 'A 500 g', comercio: 'Almacén', precioUnitario: 3000),
      ];

      final ordenadas = ordenarPorPrecioUnitario(filas);

      expect(ordenadas.map((f) => f.precioUnitario), <double>[2700, 3000, 3600]);
      // No muta la lista original.
      expect(filas.first.precioUnitario, 3600);
    });

    test('lista vacía → vacía', () {
      expect(ordenarPorPrecioUnitario(<FilaComparacion>[]), isEmpty);
    });
  });

  group('precioMinimo', () {
    test('devuelve el menor precio por unidad', () {
      final filas = <FilaComparacion>[
        fila(nombre: 'B', comercio: 'Kiosco', precioUnitario: 3600),
        fila(nombre: 'A', comercio: 'Almacén', precioUnitario: 2700),
      ];
      expect(precioMinimo(filas), 2700);
    });

    test('sin filas → null', () {
      expect(precioMinimo(<FilaComparacion>[]), isNull);
    });
  });

  group('etiquetaProducto', () {
    test('con marca incluye "· marca"', () {
      expect(
        fila(nombre: 'Mayonesa', marca: 'Marca A', comercio: 'x', precioUnitario: 1).etiquetaProducto,
        'Mayonesa · Marca A',
      );
    });
    test('sin marca muestra solo el nombre', () {
      expect(
        fila(nombre: 'Mayonesa', comercio: 'x', precioUnitario: 1).etiquetaProducto,
        'Mayonesa',
      );
    });
  });
}
