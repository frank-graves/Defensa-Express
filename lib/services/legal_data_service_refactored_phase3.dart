import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../data/datasources/legal_data_source.dart';
import '../data/datasources/local_asset_data_source.dart';
import '../models/legal_models.dart';
import 'isolate_search_worker.dart';

/// **Servicio de Búsqueda Legal Refactorizado (Fase 3)**
/// 
/// **Arquitectura Limpia (Clean Architecture):**
/// - ✅ Inyección de dependencias: `LegalDataSource` inyectable
/// - ✅ Desacoplado de Framework: no depende de `rootBundle` directamente
/// - ✅ Búsqueda concurrente: usa Isolates para CPU-heavy workloads
/// - ✅ Privacy-First: sin telemetría, datos locales
/// 
/// **Componentes:**
/// 1. Inyección: `LegalDataSource dataSource` en constructor
/// 2. Aislamiento: Usa `Isolate.run()` para búsquedas pesadas
/// 3. Escala continua: scoring sensible (0-100)
/// 4. Guard clauses: protección contra DoS y buffering
/// 
/// **Uso Típico:**
/// ```dart
/// final dataSource = LocalAssetDataSource();
/// final service = LegalDataService(dataSource: dataSource);
/// await service.cargarDatos();
/// final resultados = await service.buscar('detención policial');
/// ```
class LegalDataService {
  // ========================================================================
  // STATE
  // ========================================================================
  
  List<DerechoFundamental> _derechosFundamentales = [];
  List<EscenarioProcesal> _codigoProcesal = [];
  List<GlosarioTermino> _glosarioTransito = [];
  List<Infraccion> _infraccionesTransito = [];

  // JSON raw strings (cacheados para Isolates)
  String? _derechosJsonCache;
  String? _penalJsonCache;
  String? _transitoJsonCache;

  // Control de estado
  bool _isLoaded = false;
  bool _isLoading = false;

  // ========================================================================
  // DEPENDENCIES (Inyectadas)
  // ========================================================================

  final LegalDataSource _dataSource;

  // ========================================================================
  // STATICS
  // ========================================================================

  static const Set<String> stopWordsEs = {
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
    'a', 'ante', 'bajo', 'con', 'de', 'desde', 'en', 'para',
    'por', 'segun', 'sin', 'sobre', 'y', 'e', 'ni', 'que',
    'me', 'te', 'se', 'mi', 'tu', 'su', 'mis', 'tus', 'sus',
    'no', 'si', 'es', 'soy', 'eres', 'somos', 'sois',
    'estoy', 'estamos', 'estais', 'estan', 'estar',
    'tengo', 'tienes', 'tiene', 'tenemos', 'teneis', 'tienen',
  };

  static final RegExp _diacriticsRegex = RegExp(r'[^\w\s]');
  static const Map<String, String> _diacriticMap = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
  };

  // ========================================================================
  // CONSTRUCTOR - Inyección de Dependencias
  // ========================================================================

  /// Constructor con inyección de `LegalDataSource`
  /// 
  /// **Parámetros:**
  /// - `dataSource`: Implementación de `LegalDataSource` (ej: `LocalAssetDataSource`)
  /// - Si no se proporciona, usa `LocalAssetDataSource()` por defecto
  /// 
  /// **Ventajas de Inyección:**
  /// - ✅ Testeable: puedes inyectar un mock para tests
  /// - ✅ Flexible: puedes cambiar la fuente de datos sin modificar el servicio
  /// - ✅ Desacoplado: el servicio no conoce la implementación concreta
  /// 
  /// **Ejemplo (Test):**
  /// ```dart
  /// final mockDataSource = MockLegalDataSource();
  /// when(mockDataSource.fetchCorpus(...)).thenAnswer((_) async => '{"key": "value"}');
  /// final service = LegalDataService(dataSource: mockDataSource);
  /// ```
  LegalDataService({LegalDataSource? dataSource})
      : _dataSource = dataSource ?? LocalAssetDataSource();

  // ========================================================================
  // LIFECYCLE
  // ========================================================================

  /// Carga todos los corpus legales desde la fuente de datos
  /// 
  /// **Operación:**
  /// - Utiliza `_dataSource.fetchMultipleCorpus()` para cargar en paralelo
  /// - Cachea los JSON strings para uso posterior en Isolates
  /// - Parsea y almacena los modelos tipados
  /// 
  /// **Concurrencia:**
  /// - Main thread: Parsea JSON
  /// - Isolate secundario (futuro): búsqueda pesada
  /// 
  /// **Estado:**
  /// - Marca `_isLoading = true` mientras carga
  /// - Marca `_isLoaded = true` si tiene éxito
  Future<void> cargarDatos() async {
    if (_isLoading || _isLoaded) {
      return;  // Prevenir recargas múltiples
    }

    _isLoading = true;

    try {
      // Cargar todos los corpus en paralelo usando el data source inyectado
      final corpusMap = await _dataSource.fetchMultipleCorpus([
        'assets/legal_data/Derechos fundamentales de la persona.json',
        'assets/legal_data/Código Procesal Penal.json',
        'assets/legal_data/Reglamento Nacional de Tránsito.json',
      ]);

      // Cachear JSON strings para Isolates
      _derechosJsonCache = corpusMap['assets/legal_data/Derechos fundamentales de la persona.json'];
      _penalJsonCache = corpusMap['assets/legal_data/Código Procesal Penal.json'];
      _transitoJsonCache = corpusMap['assets/legal_data/Reglamento Nacional de Tránsito.json'];

      // Parsear Derechos Fundamentales
      if (_derechosJsonCache != null) {
        final List<dynamic> dfData = jsonDecode(_derechosJsonCache!);
        _derechosFundamentales = dfData
            .map((item) => DerechoFundamental.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Parsear Código Procesal Penal
      if (_penalJsonCache != null) {
        final List<dynamic> cppData = jsonDecode(_penalJsonCache!);
        _codigoProcesal = cppData
            .map((item) => EscenarioProcesal.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Parsear Reglamento Nacional de Tránsito
      if (_transitoJsonCache != null) {
        final Map<String, dynamic> rntData = jsonDecode(_transitoJsonCache!);
        if (rntData['glosario'] != null) {
          _glosarioTransito = (rntData['glosario'] as List)
              .map((item) => GlosarioTermino.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        if (rntData['infracciones'] != null) {
          _infraccionesTransito = (rntData['infracciones'] as List)
              .map((item) => Infraccion.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  // ========================================================================
  // TEXT NORMALIZATION
  // ========================================================================

  /// Normaliza texto (sin cambios respecto a Fase 2)
  String normalizarTexto(String texto) {
    if (texto.isEmpty) return '';
    String result = texto.toLowerCase();
    _diacriticMap.forEach((dia, sinDia) {
      result = result.replaceAll(dia, sinDia);
    });
    result = result.replaceAll(_diacriticsRegex, '');
    return result.trim();
  }

  /// Tokeniza un texto en palabras
  List<String> tokenizar(String texto) {
    return normalizarTexto(texto)
        .split(RegExp(r'\s+'))
        .where((palabra) => palabra.length > 1)
        .toList();
  }

  // ========================================================================
  // SIMILARITY ALGORITHMS
  // ========================================================================

  /// Calcula similitud Levenshtein (sin cambios respecto a Fase 2)
  double calcularSimilitud(String s1, String s2) {
    final norm1 = normalizarTexto(s1);
    final norm2 = normalizarTexto(s2);

    if (norm1.length > 150) return 0.0;
    if (norm2.length > 150) return 0.0;
    if (norm1 == norm2) return 1.0;
    if (norm1.isEmpty || norm2.isEmpty) return 0.0;

    String s = norm1;
    String t = norm2;
    if (s.length > t.length) {
      final temp = s;
      s = t;
      t = temp;
    }

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

  /// Calcula relevancia (sin cambios respecto a Fase 2)
  double calcularRelevancia(String query, String target) {
    final queryNorm = normalizarTexto(query);
    final targetNorm = normalizarTexto(target);

    if (queryNorm.isEmpty || targetNorm.isEmpty) return 0.0;
    if (queryNorm == targetNorm) return 100.0;
    if (targetNorm.startsWith(queryNorm)) return 90.0;

    final similitud = calcularSimilitud(queryNorm, targetNorm);
    if (similitud > 0.85) {
      return (similitud * 100).clamp(86.0, 99.0);
    }

    if (targetNorm.contains(queryNorm)) {
      final ratioLongitud = (queryNorm.length / targetNorm.length).clamp(0.0, 1.0);
      final baseScore = 60.0;
      final bonus = ratioLongitud * 25.0;
      return (baseScore + bonus).clamp(60.0, 85.0);
    }

    if (similitud > 0.5) {
      return (similitud * 70).clamp(35.0, 70.0);
    }

    return 0.0;
  }

  /// Extrae fragmentos relevantes
  List<String> extraerCoincidencias(String query, String target) {
    final queryNorm = normalizarTexto(query);
    final targetNorm = normalizarTexto(target);
    final targetOriginal = target;
    final coincidencias = <String>[];

    if (targetNorm.contains(queryNorm)) {
      final indice = targetNorm.indexOf(queryNorm);
      final inicio = (indice - 30).clamp(0, targetOriginal.length);
      final fin = (indice + queryNorm.length + 30).clamp(0, targetOriginal.length);
      
      final fragmento = targetOriginal.substring(inicio, fin).trim();
      if (fragmento.isNotEmpty) {
        coincidencias.add('...${fragmento}...');
      }
    }

    return coincidencias;
  }

  // ========================================================================
  // SEARCH - MAIN (Con Isolates)
  // ========================================================================

  /// Búsqueda Principal - Ejecuta en Isolate Secundario
  /// 
  /// **Refactorización (Fase 3):**
  /// - ✅ Utiliza `Isolate.run()` para delegar trabajo pesado
  /// - ✅ Main Isolate permanece libre (mantiene 60/120 FPS)
  /// - ✅ Parámetros serializables para portabilidad
  /// - ✅ Timeout: 5 segundos (previene hangs)
  /// 
  /// **Concurrencia:**
  /// - Búsqueda ocurre en segundo plano
  /// - UI permanece responsiva
  /// - Múltiples búsquedas pueden ejecutarse en paralelo
  /// 
  /// **Excepciones:**
  /// - Retorna lista vacía si hay timeout o error
  /// - No lanza (graceful degradation)
  Future<List<ResultadoBusquedaLegal>> buscar(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    if (!_isLoaded) {
      return [];
    }

    final resultados = <ResultadoBusquedaLegal>[];

    try {
      // Ejecutar búsqueda en Isolate (concurrente)
      // Esto libera el Main Isolate para la UI
      if (_derechosJsonCache != null) {
        final derechosResults = await _searchInIsolate(
          query,
          _derechosJsonCache!,
          'DERECHOS',
        );
        resultados.addAll(derechosResults);
      }

      if (_penalJsonCache != null) {
        final penalResults = await _searchInIsolate(
          query,
          _penalJsonCache!,
          'PENAL',
        );
        resultados.addAll(penalResults);
      }

      if (_transitoJsonCache != null) {
        final transitoResults = await _searchInIsolate(
          query,
          _transitoJsonCache!,
          'TRANSITO',
        );
        resultados.addAll(transitoResults);
      }

      // Ordenar por relevancia descendente
      resultados.sort((a, b) => b.relevancia.compareTo(a.relevancia));

      return resultados;
    } catch (e) {
      // Fallback: búsqueda sincrónica (lenta pero mejor que nada)
      return _buscarSincronico(query);
    }
  }

  /// Ejecuta búsqueda en Isolate Secundario
  /// 
  /// **Parámetros:**
  /// - `query`: Query de usuario
  /// - `corpusJson`: Contenido JSON del corpus (string serializable)
  /// - `corpusType`: Tipo de documento ('DERECHOS', 'PENAL', 'TRANSITO')
  /// 
  /// **Timeout:** 5 segundos (previene hangs)
  /// 
  /// **Retorna:** Lista de resultados ordenados por relevancia
  Future<List<ResultadoBusquedaLegal>> _searchInIsolate(
    String query,
    String corpusJson,
    String corpusType,
  ) async {
    try {
      final params = SearchParams(
        query: query,
        corpusJson: corpusJson,
        corpusType: corpusType,
        minRelevance: 35.0,
      );

      // Ejecutar en Isolate con timeout
      final rawResults = await Isolate.run<List<SearchResult>>(
        performSearchIsolate,
        params.toMap(),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => <SearchResult>[],
      );

      // Convertir SearchResult a ResultadoBusquedaLegal
      return rawResults
          .map((result) => ResultadoBusquedaLegal(
            documentoTipo: result['documentoTipo'] as String,
            resultado: result,  // Aquí podría deserializarse a tipo específico
            coincidencias: List<String>.from(result['fragmentos'] as List),
            relevancia: result['relevancia'] as double,
          ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Búsqueda Sincrónica (Fallback si Isolate falla)
  /// 
  /// Esta es la búsqueda antigua (síncrona) que se ejecuta
  /// en el Main Isolate si hay problemas con la concurrencia.
  /// 
  /// **Performance:**
  /// - Lenta para corpus grandes (sin Isolate)
  /// - Pero funciona como fallback
  List<ResultadoBusquedaLegal> _buscarSincronico(String query) {
    final resultados = <ResultadoBusquedaLegal>[];

    resultados.addAll(_buscarEnDerechos(query));
    resultados.addAll(_buscarEnProcesal(query));
    resultados.addAll(_buscarEnTransito(query));

    resultados.sort((a, b) => b.relevancia.compareTo(a.relevancia));

    return resultados;
  }

  // ========================================================================
  // SEARCH - INTERNAL (Busca en Arrays cacheados)
  // ========================================================================

  List<ResultadoBusquedaLegal> _buscarEnDerechos(String query) {
    final resultados = <ResultadoBusquedaLegal>[];

    for (final derecho in _derechosFundamentales) {
      double relevancia = 0.0;
      final coincidencias = <String>[];

      double relTitle = calcularRelevancia(query, derecho.title);
      if (relTitle > relevancia) relevancia = relTitle;
      if (relTitle > 0) {
        coincidencias.addAll(extraerCoincidencias(query, derecho.title));
      }

      for (final intent in derecho.intents) {
        final relIntent = calcularRelevancia(query, intent);
        if (relIntent > relevancia) relevancia = relIntent;
        if (relIntent > 0) {
          coincidencias.addAll(extraerCoincidencias(query, intent));
        }
      }

      final relSummary = calcularRelevancia(query, derecho.rightsSummary);
      if (relSummary > relevancia) relevancia = relSummary;
      if (relSummary > 0) {
        coincidencias.addAll(extraerCoincidencias(query, derecho.rightsSummary));
      }

      if (derecho.tags != null) {
        for (final tag in derecho.tags!) {
          final relTag = calcularRelevancia(query, tag);
          if (relTag > relevancia) relevancia = relTag;
          if (relTag > 0) {
            coincidencias.add(tag);
          }
        }
      }

      if (relevancia > 0) {
        resultados.add(ResultadoBusquedaLegal(
          documentoTipo: 'DERECHOS',
          resultado: derecho,
          coincidencias: coincidencias.toSet().toList(),
          relevancia: relevancia,
        ));
      }
    }

    return resultados;
  }

  List<ResultadoBusquedaLegal> _buscarEnProcesal(String query) {
    final resultados = <ResultadoBusquedaLegal>[];

    for (final escenario in _codigoProcesal) {
      double relevancia = 0.0;
      final coincidencias = <String>[];

      double relScenario = calcularRelevancia(query, escenario.scenario);
      if (relScenario > relevancia) relevancia = relScenario;
      if (relScenario > 0) {
        coincidencias.addAll(extraerCoincidencias(query, escenario.scenario));
      }

      final relAccion = calcularRelevancia(query, escenario.accionLegal);
      if (relAccion > relevancia) relevancia = relAccion;
      if (relAccion > 0) {
        coincidencias.addAll(extraerCoincidencias(query, escenario.accionLegal));
      }

      final relGuion = calcularRelevancia(query, escenario.guionDeDefensa);
      if (relGuion > relevancia) relevancia = relGuion;
      if (relGuion > 0) {
        coincidencias.addAll(extraerCoincidencias(query, escenario.guionDeDefensa));
      }

      final relLimite = calcularRelevancia(query, escenario.limitePolicial);
      if (relLimite > relevancia) relevancia = relLimite;
      if (relLimite > 0) {
        coincidencias.addAll(extraerCoincidencias(query, escenario.limitePolicial));
      }

      if (escenario.tags != null) {
        for (final tag in escenario.tags!) {
          final relTag = calcularRelevancia(query, tag);
          if (relTag > relevancia) relevancia = relTag;
          if (relTag > 0) {
            coincidencias.add(tag);
          }
        }
      }

      if (relevancia > 0) {
        resultados.add(ResultadoBusquedaLegal(
          documentoTipo: 'PENAL',
          resultado: escenario,
          coincidencias: coincidencias.toSet().toList(),
          relevancia: relevancia,
        ));
      }
    }

    return resultados;
  }

  List<ResultadoBusquedaLegal> _buscarEnTransito(String query) {
    final resultados = <ResultadoBusquedaLegal>[];

    for (final termino in _glosarioTransito) {
      final relevancia = [
        calcularRelevancia(query, termino.termino),
        calcularRelevancia(query, termino.definicion),
      ].reduce((a, b) => a > b ? a : b);

      if (relevancia > 0) {
        resultados.add(ResultadoBusquedaLegal(
          documentoTipo: 'TRANSITO',
          resultado: termino,
          coincidencias: [
            ...extraerCoincidencias(query, termino.termino),
            ...extraerCoincidencias(query, termino.definicion),
          ],
          relevancia: relevancia,
        ));
      }
    }

    for (final infraccion in _infraccionesTransito) {
      final relevancia = [
        calcularRelevancia(query, infraccion.codigo),
        calcularRelevancia(query, infraccion.descripcion),
      ].reduce((a, b) => a > b ? a : b);

      if (relevancia > 0) {
        resultados.add(ResultadoBusquedaLegal(
          documentoTipo: 'TRANSITO',
          resultado: infraccion,
          coincidencias: [
            ...extraerCoincidencias(query, infraccion.codigo),
            ...extraerCoincidencias(query, infraccion.descripcion),
          ],
          relevancia: relevancia,
        ));
      }
    }

    return resultados;
  }

  // ========================================================================
  // GETTERS
  // ========================================================================

  Infraccion? obtenerInfraccionPorCodigo(String codigo) {
    final codigoNorm = normalizarTexto(codigo);
    try {
      return _infraccionesTransito.firstWhere(
        (inf) => normalizarTexto(inf.codigo) == codigoNorm,
      );
    } catch (e) {
      return null;
    }
  }

  DerechoFundamental? obtenerDerechoPorId(String id) {
    final idNorm = normalizarTexto(id);
    try {
      return _derechosFundamentales.firstWhere(
        (d) => normalizarTexto(d.id) == idNorm,
      );
    } catch (e) {
      return null;
    }
  }

  EscenarioProcesal? obtenerEscenarioPorNombre(String scenario) {
    final scenarioNorm = normalizarTexto(scenario);
    try {
      return _codigoProcesal.firstWhere(
        (e) => normalizarTexto(e.scenario) == scenarioNorm,
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, int> obtenerEstadisticas() {
    return {
      'totalDerechos': _derechosFundamentales.length,
      'totalEscenarios': _codigoProcesal.length,
      'totalInfracciones': _infraccionesTransito.length,
      'totalGlosario': _glosarioTransito.length,
    };
  }

  bool estaListo() => _isLoaded;
}
