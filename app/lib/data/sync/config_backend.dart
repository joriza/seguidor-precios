/// Punto único de configuración del backend colaborativo (AD-002, AD-011).
///
/// La app apunta a cualquier backend Supabase cambiando solo estos dos
/// valores — nunca hay URL ni clave hardcodeadas en otro archivo.
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

/// Valores de producción: proyecto Supabase del dueño (creado 2026-10-28,
/// región us-west-2, anonymous sign-ins activado, esquema T1 aplicado).
const ConfigBackend configBackend = ConfigBackend(
  url: 'https://pipoladhxwuhcfjsuzkx.supabase.co',
  claveAnonima:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBpcG9sYWRoeHd1aGNmanN1emt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxOTEwOTgsImV4cCI6MjEwODc2NzA5OH0.ytVoH37sRhq6lguh2K_wegp9zk3xSEYHtTY9jyaUrc0',
);
