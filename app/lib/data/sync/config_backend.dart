/// Punto único de configuración del backend colaborativo (AD-002, AD-011).
///
/// La app apunta a cualquier backend Supabase cambiando solo estos dos
/// valores — nunca hay URL ni clave hardcodeadas en otro archivo. Los
/// placeholders se reemplazan cuando el dueño cree el proyecto (T7 de la
/// fase; región sugerida sa-east-1 con anonymous sign-ins activado).
///
/// La clave anónima va embebida en la app por diseño (AD-002): está
/// pensada para eso y la protección real son las reglas RLS del servidor.
class ConfigBackend {
  const ConfigBackend({required this.url, required this.claveAnonima});

  /// URL del proyecto (ej.: https://xyzcompany.supabase.co).
  final String url;

  /// Clave anónima (anon key) del proyecto.
  final String claveAnonima;

  /// false mientras quede algún placeholder sin reemplazar: el arranque de
  /// la sync puede rechazar temprano una configuración incompleta.
  bool get estaConfigurada =>
      url.isNotEmpty &&
      claveAnonima.isNotEmpty &&
      !url.contains('<<') &&
      !claveAnonima.contains('<<');
}

/// Valores de producción: los completa el dueño al crear el proyecto
/// Supabase (placeholder seguido en Studio, formato `<<NOMBRE>>`).
const ConfigBackend configBackend = ConfigBackend(
  url: '<<URL_DEL_PROYECTO_SUPABASE>>',
  claveAnonima: '<<CLAVE_ANONIMA_SUPABASE>>',
);
