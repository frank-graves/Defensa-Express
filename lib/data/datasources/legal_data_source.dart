/// **Clean Architecture - Data Source Layer (Abstraction)**
/// 
/// Esta interfaz abstrae el origen de datos legal, desacoplando la lógica
/// de búsqueda (Domain/Service Layer) del framework (Flutter/rootBundle).
/// 
/// **Principios:**
/// - ✅ Separación de responsabilidades (SOLID)
/// - ✅ Inyectable (Dependency Injection)
/// - ✅ Testeable (mockeable para tests unitarios)
/// - ✅ Privacy-First: abstrae detalles de implementación
abstract class LegalDataSource {
  /// Carga el corpus legal desde una ruta específica
  /// 
  /// **Parámetros:**
  /// - [path]: Ruta relativa al asset (ej: 'assets/legal_data/Derechos fundamentales de la persona.json')
  /// 
  /// **Retorna:**
  /// - `Future<String>`: Contenido JSON del archivo
  /// 
  /// **Excepciones:**
  /// - Lanza si el archivo no existe o es inválido
  Future<String> fetchCorpus(String path);

  /// Carga múltiples corpus en paralelo
  /// 
  /// **Parámetros:**
  /// - [paths]: Lista de rutas de assets
  /// 
  /// **Retorna:**
  /// - `Future<Map<String, String>>`: Mapa {ruta → contenido JSON}
  /// 
  /// **Nota técnica:**
  /// - Implementación debe usar `Future.wait()` para paralelismo
  /// - Todos los datos deben estar disponibles en memoria antes de retornar
  Future<Map<String, String>> fetchMultipleCorpus(List<String> paths);
}
