/// **Isolate-Friendly Search Functions (Concurrency Layer)**
/// 
/// Las funciones en este archivo están diseñadas para ejecutarse
/// en un Isolate secundario sin acceso a estado mutable del Main Isolate.
/// 
/// **Restricciones de Portabilidad:**
/// - ✅ Solo parámetros primitivos (String, int, double, List, Map)
/// - ✅ Sin closures sobre variables mutables
/// - ✅ Sin acceso a state global (excepto constantes)
/// - ✅ Sin callbacks asincronos
/// 
/// **Por qué Isolates:**
/// - Main Isolate debe mantener 60/120 FPS (UI fluida)
/// - Búsqueda masiva en corpus es CPU-intensiva
/// - Isolate secundario ejecuta concurrentemente sin bloquear UI

import 'dart:convert';

/// Estructura serializable de resultados de búsqueda para Isolate
/// 
/// **Nota:** Usamos Map<String, dynamic> en lugar de clases custom
/// porque Isolate.run() solo puede serializar tipos primitivos de Dart.
/// 
/// **Estructura:**
/// ```dart
/// {
///   'documentoTipo': 'DERECHOS', // tipo de documento
///   'titulo': 'Derecho a la vida',
///   'relevancia': 95.5,
///   'fragmentos': ['...contenido relevante...'],
/// }
/// ```
typedef SearchResult = Map<String, dynamic>;

/// Parámetros de entrada para búsqueda en Isolate (serializable)
class SearchParams {
  final String query;
  final String corpusJson;  // Contenido JSON completo del corpus
  final String corpusType;  // 'DERECHOS', 'PENAL', 'TRANSITO'
  final double minRelevance;  // Umbral mínimo (0-100)

  SearchParams({
    required this.query,
    required this.corpusJson,
    required this.corpusType,
    this.minRelevance = 35.0,
  });

  /// Serializa parámetros para envío a Isolate
  Map<String, dynamic> toMap() => {
    'query': query,
    'corpusJson': corpusJson,
    'corpusType': corpusType,
    'minRelevance': minRelevance,
  };

  /// Deserializa desde Isolate
  factory SearchParams.fromMap(Map<String, dynamic> map) => SearchParams(
    query: map['query'] as String,
    corpusJson: map['corpusJson'] as String,
    corpusType: map['corpusType'] as String,
    minRelevance: map['minRelevance'] as double? ?? 35.0,
  );
}

/// **Función Top-Level para Isolate: Búsqueda Principal**
/// 
/// Esta función ejecuta la búsqueda pesada sin estado del Main Isolate.
/// 
/// **Entrada:** Map<String, dynamic> con parámetros serializados
/// **Salida:** List<SearchResult> ordenado por relevancia descendente
/// 
/// **Ejecución típica:**
/// ```dart
/// final results = await Isolate.run<List<SearchResult>>(
///   performSearchIsolate,
///   params.toMap(),
/// );
/// ```
Future<List<SearchResult>> performSearchIsolate(
  Map<String, dynamic> serializedParams,
) async {
  final params = SearchParams.fromMap(serializedParams);
  
  try {
    final corpusData = jsonDecode(params.corpusJson);
    
    // Parsear según tipo de corpus
    final items = _parseCorpusByType(corpusData, params.corpusType);
    
    // Ejecutar búsqueda contra cada item
    final resultados = <SearchResult>[];
    for (final item in items) {
      final relevancia = _calculateItemRelevance(params.query, item);
      
      if (relevancia >= params.minRelevance) {
        resultados.add({
          'documentoTipo': params.corpusType,
          'titulo': item['title'] ?? item['titulo'] ?? 'Sin título',
          'relevancia': relevancia,
          'fragmentos': _extractRelevantFragments(params.query, item),
          'id': item['id'] ?? '',
        });
      }
    }
    
    // Ordenar por relevancia descendente
    resultados.sort((a, b) => (b['relevancia'] as num).compareTo(a['relevancia'] as num));
    
    return resultados;
  } catch (e) {
    // Retornar lista vacía si hay error (graceful degradation)
    return [];
  }
}

/// **Función Auxiliar: Parsear Corpus por Tipo**
List<Map<String, dynamic>> _parseCorpusByType(
  dynamic corpusData,
  String corpusType,
) {
  if (corpusData is! Map<String, dynamic>) {
    return [];
  }

  switch (corpusType) {
    case 'DERECHOS':
      // Derechos fundamentales es un array directo
      if (corpusData.containsKey('derechos')) {
        return List<Map<String, dynamic>>.from(corpusData['derechos'] as List);
      }
      return [];
    
    case 'PENAL':
      // Código procesal es un array
      if (corpusData.containsKey('escenarios')) {
        return List<Map<String, dynamic>>.from(corpusData['escenarios'] as List);
      }
      return [];
    
    case 'TRANSITO':
      // Tránsito puede estar en 'infracciones' o 'glosario'
      final items = <Map<String, dynamic>>[];
      if (corpusData.containsKey('infracciones')) {
        items.addAll(List<Map<String, dynamic>>.from(corpusData['infracciones'] as List));
      }
      if (corpusData.containsKey('glosario')) {
        items.addAll(List<Map<String, dynamic>>.from(corpusData['glosario'] as List));
      }
      return items;
    
    default:
      return [];
  }
}

/// **Función Auxiliar: Calcular Relevancia de un Item**
/// 
/// Implementa el mismo algoritmo que `calcularRelevancia()` en main,
/// pero como función pura sin estado.
double _calculateItemRelevance(String query, Map<String, dynamic> item) {
  final queryNorm = _normalizeText(query);
  
  // Campos a buscar según disponibilidad
  final searchFields = <String>[
    item['title'] ?? '',
    item['titulo'] ?? '',
    item['description'] ?? '',
    item['immediateAction'] ?? '',
    item['rightsSummary'] ?? '',
    item['definiton'] ?? '',  // Note: typo en algunos JSONs
  ];

  double maxRelevance = 0.0;
  for (final field in searchFields) {
    if (field.isEmpty) continue;
    
    final fieldNorm = _normalizeText(field);
    final relevance = _calculateFieldRelevance(queryNorm, fieldNorm);
    
    if (relevance > maxRelevance) {
      maxRelevance = relevance;
    }
  }

  return maxRelevance;
}

/// **Función Auxiliar: Calcular Relevancia de un Campo**
double _calculateFieldRelevance(String queryNorm, String targetNorm) {
  if (queryNorm.isEmpty || targetNorm.isEmpty) return 0.0;

  // Exacta
  if (queryNorm == targetNorm) return 100.0;

  // Starts-with
  if (targetNorm.startsWith(queryNorm)) return 90.0;

  // Levenshtein (simplificado para Isolate - sin matriz 2D)
  final similitud = _calculateLevenshteinSimilarity(queryNorm, targetNorm);
  if (similitud > 0.85) {
    return (similitud * 100).clamp(86.0, 99.0);
  }

  // Contains
  if (targetNorm.contains(queryNorm)) {
    final ratio = queryNorm.length / targetNorm.length;
    return (60.0 + (ratio * 25.0)).clamp(60.0, 85.0);
  }

  // Solo Levenshtein bajo
  if (similitud > 0.5) {
    return (similitud * 70).clamp(35.0, 70.0);
  }

  return 0.0;
}

/// **Función Auxiliar: Levenshtein Simplificado para Isolate**
double _calculateLevenshteinSimilarity(String s1, String s2) {
  if (s1 == s2) return 1.0;
  if (s1.isEmpty || s2.isEmpty) return 0.0;

  // Guard clause
  if (s1.length > 150) return 0.0;
  if (s2.length > 150) return 0.0;

  // Single-Row Levenshtein (igual que en main)
  String s = s1.length <= s2.length ? s1 : s2;
  String t = s1.length <= s2.length ? s2 : s1;

  final prevRow = List<int>.filled(t.length + 1, 0);
  final currRow = List<int>.filled(t.length + 1, 0);

  for (int j = 0; j <= t.length; j++) {
    prevRow[j] = j;
  }

  for (int i = 1; i <= s.length; i++) {
    currRow[0] = i;

    for (int j = 1; j <= t.length; j++) {
      final cost = s[i - 1] == t[j - 1] ? 0 : 1;
      currRow[j] = [
        prevRow[j] + 1,
        currRow[j - 1] + 1,
        prevRow[j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }

    final temp = prevRow;
    prevRow.setAll(0, currRow);
    currRow.setAll(0, temp);
  }

  final distancia = prevRow[t.length];
  final maxLen = s.length > t.length ? s.length : t.length;
  return (1 - (distancia / maxLen)).clamp(0.0, 1.0);
}

/// **Función Auxiliar: Normalizar Texto (Isolate-compatible)**
String _normalizeText(String text) {
  if (text.isEmpty) return '';

  // Mapa de diacríticos (igual que en main)
  const diacriticMap = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
  };

  String result = text.toLowerCase();
  diacriticMap.forEach((dia, sinDia) {
    result = result.replaceAll(dia, sinDia);
  });

  return result.replaceAll(RegExp(r'[^\w\s]'), '').trim();
}

/// **Función Auxiliar: Extraer Fragmentos Relevantes**
List<String> _extractRelevantFragments(String query, Map<String, dynamic> item) {
  final fragments = <String>[];
  final queryNorm = _normalizeText(query);

  // Campos a extraer fragmentos
  final fields = <String>[
    item['description'] ?? '',
    item['immediateAction'] ?? '',
    item['rightsSummary'] ?? '',
  ];

  for (final field in fields) {
    if (field.isEmpty) continue;
    
    final fieldNorm = _normalizeText(field);
    if (fieldNorm.contains(queryNorm)) {
      final idx = fieldNorm.indexOf(queryNorm);
      final start = (idx - 20).clamp(0, field.length);
      final end = (idx + queryNorm.length + 20).clamp(0, field.length);
      
      final fragment = field.substring(start, end).trim();
      if (fragment.isNotEmpty && !fragments.contains(fragment)) {
        fragments.add('...$fragment...');
      }
    }
  }

  return fragments;
}
