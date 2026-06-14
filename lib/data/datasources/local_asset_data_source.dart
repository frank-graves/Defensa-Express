import 'package:flutter/services.dart';
import 'legal_data_source.dart';

/// **Clean Architecture - Local Asset Implementation**
/// 
/// Implementación concreta de `LegalDataSource` que carga datos
/// desde los assets de Flutter. Esta clase encapsula la dependencia
/// de `rootBundle`, permitiendo que la lógica de búsqueda sea
/// completamente independiente del framework.
/// 
/// **Propiedades:**
/// - ✅ No tiene estado mutable (stateless data source)
/// - ✅ Cachea automáticamente (rootBundle lo hace internamente)
/// - ✅ Thread-safe para lectura
/// - ✅ Eficiente: carga una sola vez por ruta
class LocalAssetDataSource implements LegalDataSource {
  /// Constructor sin parámetros (singleton pattern opcional)
  const LocalAssetDataSource();

  /// Carga un corpus legal desde los assets
  /// 
  /// **Implementación:**
  /// - Delega a `rootBundle.loadString()` (parte del framework Flutter)
  /// - `rootBundle` está disponible solo después de que Flutter se inicializa
  /// - Los datos se cachean automáticamente en memoria
  /// 
  /// **Complejidad:**
  /// - Time: O(n) donde n = tamaño del archivo
  /// - Space: O(n) (el contenido se almacena en memoria)
  /// 
  /// **Excepciones:**
  /// - `PlatformException` si el archivo no existe o hay error de lectura
  /// - `FormatException` si el contenido no es válido UTF-8
  @override
  Future<String> fetchCorpus(String path) async {
    try {
      return await rootBundle.loadString(path);
    } on PlatformException catch (e) {
      throw DataSourceException(
        'Error al cargar corpus desde assets: $path',
        originalError: e,
      );
    } catch (e) {
      throw DataSourceException(
        'Error inesperado cargando corpus: $path',
        originalError: e,
      );
    }
  }

  /// Carga múltiples corpus en paralelo (sin bloqueo)
  /// 
  /// **Implementación:**
  /// - Utiliza `Future.wait()` para paralelismo
  /// - Todas las cargas se inician simultáneamente
  /// - Retorna cuando TODOS los corpus están cargados
  /// 
  /// **Comportamiento de Error:**
  /// - Si ALGUNO falla, toda la operación falla (fail-fast)
  /// - Para fallback parcial, usar `Future.wait(..., eagerError: false)`
  /// 
  /// **Retorna:**
  /// - Mapa donde las claves son las rutas y los valores son los contenidos
  /// 
  /// **Ejemplo:**
  /// ```dart
  /// final sources = await dataSource.fetchMultipleCorpus([
  ///   'assets/legal_data/Derechos fundamentales de la persona.json',
  ///   'assets/legal_data/Código Procesal Penal.json',
  /// ]);
  /// final derechosJson = sources['assets/legal_data/Derechos fundamentales de la persona.json'];
  /// ```
  @override
  Future<Map<String, String>> fetchMultipleCorpus(List<String> paths) async {
    try {
      final futures = <Future<String>>[
        for (final path in paths) fetchCorpus(path),
      ];

      final results = await Future.wait(futures);
      
      final corpusMap = <String, String>{};
      for (int i = 0; i < paths.length; i++) {
        corpusMap[paths[i]] = results[i];
      }
      
      return corpusMap;
    } catch (e) {
      throw DataSourceException(
        'Error al cargar múltiples corpus',
        originalError: e,
      );
    }
  }
}

/// **Excepción Personalizada para Data Source**
/// 
/// Encapsula errores de la capa de datos, permitiendo
/// que la capa superior (Service) maneje errores de forma
/// uniforme sin conocer detalles de `rootBundle`.
class DataSourceException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  DataSourceException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'DataSourceException: $message';
}
