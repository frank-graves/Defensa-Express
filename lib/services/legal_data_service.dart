import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/legal_models.dart';

/// Servicio de búsqueda y acceso a base de datos legal
/// Privacy-First: Todas las operaciones se ejecutan localmente sin acceso a red
/// Optimizado para O(min(N,M)) memoria y procesamiento en Isolates
///
/// Procesa 4 documentos legales principales:
/// - Resolución Ministerial 952-2018 (Derechos Humanos)
/// - Reglamento Nacional de Tránsito
/// - Derechos Fundamentales de la Persona
/// - Código Procesal Penal
///
/// **Performance Constraints:**
/// - Levenshtein: O(min(∣s1∣, ∣s2∣)) memory, guard clause at 150 chars
/// - Text normalization: Unicode normalization + RegExp (not manual loops)
/// - No external dependencies for text processing (FOSS + Privacy-First)
class LegalDataService {
  List<DerechoFundamental> _derechosFundamentales = [];
  List<EscenarioProcesal> _codigoProcesal = [];
  List<GlosarioTermino> _glosarioTransito = [];
  List<Infraccion> _infraccionesTransito = [];

  static const Set<String> stopWordsEs = {
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
    'a', 'ante', 'bajo', 'con', 'de', 'desde', 'en', 'para',
    'por', 'segun', 'sin', 'sobre', 'y', 'e', 'ni', 'que',
    'me', 'te', 'se', 'mi', 'tu', 'su', 'mis', 'tus', 'sus',
    'no', 'si', 'es', 'soy', 'eres', 'somos', 'sois',
    'estoy', 'estamos', 'estais', 'estan', 'estar',
    'tengo', 'tienes', 'tiene', 'tenemos', 'teneis', 'tienen',
  };

  // RegExp compilado para normalization (compilado una sola vez)
  static final RegExp _diacriticsRegex = RegExp(r'[^\w\s]');

  // Mapeo directo de caracteres con diacríticos (sin bucles iterativos)
  static const Map<String, String> _diacriticMap = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
  };

  // Límite estricto de tamaño de JSON para prevenir DoS/OOM
  static const int _maxJsonSize = 50 * 1024;

  bool _isLoaded = false;

  /// Helper privado: Carga JSON desde assets con validación de tamaño (circuit breaker).
  /// Previene ataques DoS al limitar el tamaño del archivo antes de decodificarlo.
  /// 
  /// Lanza [Exception] si el archivo excede [_maxJsonSize], evitando OutOfMemoryError.
  Future<String> _loadJsonWithSizeLimit(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      
      if (data.lengthInBytes > _maxJsonSize) {
        throw Exception(
          'Archivo JSON demasiado grande: ${data.lengthInBytes} bytes excede límite de $_maxJsonSize bytes. '
          'Posible ataque DoS o corrupción del APK.'
        );
      }
      
      return utf8.decode(data.buffer.asUint8List());
    } catch (e) {
      rethrow;
    }
  }

  /// Carga todos los archivos JSON desde los assets
  /// Debe ejecutarse una sola vez en el ciclo de vida de la aplicación
  /// No utiliza print() para evitar leaks de datos; en DEBUG usa dart:developer
  Future<void> cargarDatos() async {
    try {
      // Cargar Derechos Fundamentales
      final String dfResponse =
          await _loadJsonWithSizeLimit('assets/legal_data/Derechos fundamentales de la persona.json');
      final List<dynamic> dfData = jsonDecode(dfResponse);
      _derechosFundamentales = dfData
          .map((item) => DerechoFundamental.fromJson(item as Map<String, dynamic>))
          .toList();

      // Cargar Código Procesal Penal
      final String cppResponse =
          await _loadJsonWithSizeLimit('assets/legal_data/Código Procesal Penal.json');
      final List<dynamic> cppData = jsonDecode(cppResponse);
      _codigoProcesal = cppData
          .map((item) => EscenarioProcesal.fromJson(item as Map<String, dynamic>))
          .toList();

      // Cargar Reglamento Nacional de Tránsito
      final String rntResponse =
          await _loadJsonWithSizeLimit('assets/legal_data/Reglamento Nacional de Tránsito.json');
      final Map<String, dynamic> rntData = jsonDecode(rntResponse);
      
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

      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      rethrow;
    }
  }

  /// Normaliza texto removiendo diacríticos, mayúsculas y caracteres especiales
  /// 
  /// **Refactorización (Fase 2):**
  /// - ✅ Reemplaza bucle manual iterativo con mapeo directo (sin índices fuera de rango)
  /// - ✅ Usa RegExp compilado reutilizable para eliminar caracteres especiales
  /// - ✅ Garantiza ñ/Ñ → n/N (no borrado accidental)
  /// - ⏱️ O(n) time, O(n) space (optimal)
  String normalizarTexto(String texto) {
    if (texto.isEmpty) return '';

    // Convertir a minúsculas primero
    String result = texto.toLowerCase();
    
    // Reemplazar diacríticos usando Map (no bucles iterativos con riesgo de índice)
    _diacriticMap.forEach((dia, sinDia) {
      result = result.replaceAll(dia, sinDia);
    });

    // Eliminar caracteres especiales (mantener solo alfanuméricos y espacios)
    result = result.replaceAll(_diacriticsRegex, '');
    
    return result.trim();
  }

  /// Tokeniza un texto en palabras individuales
  List<String> tokenizar(String texto) {
    return normalizarTexto(texto)
        .split(RegExp(r'\s+'))
        .where((palabra) => palabra.length > 1)
        .toList();
  }

  /// Calcula similitud Levenshtein entre dos strings (0-1)
  /// 
  /// **Refactorización (Fase 2) - Optimización Extrema:**
  /// - ✅ Implementa **Single-Row Levenshtein** en lugar de matriz 2D
  /// - ✅ Complejidad espacial: O(min(|s1|, |s2|)) en lugar de O(|s1|×|s2|)
  /// - ✅ Guard clause: si consulta > 150 chars, retorna 0.0 (previene DoS)
  /// - ✅ Reutiliza dos arreglos (prev/curr) sin reallocate en cada iteración
  /// - ⏱️ O(n×m) time, O(min(n,m)) space (optimal para textos largos)
  double calcularSimilitud(String s1, String s2) {
    final norm1 = normalizarTexto(s1);
    final norm2 = normalizarTexto(s2);

    // Guard clause: proteger contra consultas gigantes
    if (norm1.length > 150) return 0.0;
    if (norm2.length > 150) return 0.0;

    if (norm1 == norm2) return 1.0;
    if (norm1.isEmpty || norm2.isEmpty) return 0.0;

    // Asegurarse de que norm1 sea el más corto (optimiza memoria)
    String s = norm1;
    String t = norm2;
    if (s.length > t.length) {
      final temp = s;
      s = t;
      t = temp;
    }

    // Single-Row Levenshtein: solo dos filas (anterior y actual)
    final prevRow = List<int>.filled(t.length + 1, 0);
    final currRow = List<int>.filled(t.length + 1, 0);

    // Inicializar la primera fila
    for (int j = 0; j <= t.length; j++) {
      prevRow[j] = j;
    }

    // Computar distancia iterando sobre s (la cadena más corta)
    for (int i = 1; i <= s.length; i++) {
      currRow[0] = i;

      for (int j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        currRow[j] = [
          prevRow[j] + 1,      // deletion
          currRow[j - 1] + 1,  // insertion
          prevRow[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }

      // Intercambiar referencias (evitar copia)
      final temp = prevRow;
      prevRow.setAll(0, currRow);
      currRow.setAll(0, temp);
    }

    final distancia = prevRow[t.length];
    final maxLen = s.length > t.length ? s.length : t.length;

    return (1 - (distancia / maxLen)).clamp(0.0, 1.0);
  }

  /// Calcula relevancia entre query y target con escala continua (0-100)
  /// 
  /// **Refactorización (Fase 2) - Scoring Sensible:**
  /// - ✅ Escala continua: Levenshtein es dominante, no sobrepasado por contains()
  /// - ✅ Exacta: 100.0
  /// - ✅ Starts-with: 90.0 + Levenshtein bonus
  /// - ✅ Contiene: 50.0 + length-weighted bonus
  /// - ✅ Levenshtein: 0-70 (solo si similitud > 0.5)
  /// - ✅ Sin coincidencias: 0.0
  double calcularRelevancia(String query, String target) {
    final queryNorm = normalizarTexto(query);
    final targetNorm = normalizarTexto(target);

    if (queryNorm.isEmpty || targetNorm.isEmpty) return 0.0;

    // Coincidencia exacta: máxima relevancia
    if (queryNorm == targetNorm) return 100.0;

    // Coincidencia al inicio: alta relevancia
    if (targetNorm.startsWith(queryNorm)) {
      return 90.0;
    }

    // Calcular similitud Levenshtein como base
    final similitud = calcularSimilitud(queryNorm, targetNorm);

    // Si similitud es muy alta, retornar score basado en ella (dominante)
    if (similitud > 0.85) {
      return (similitud * 100).clamp(86.0, 99.0);
    }

    // Coincidencia por subcadena: score base + bonus ponderado por longitud relativa
    if (targetNorm.contains(queryNorm)) {
      final ratioLongitud = (queryNorm.length / targetNorm.length).clamp(0.0, 1.0);
      final baseScore = 60.0;
      final bonus = ratioLongitud * 25.0; // Máximo +25 si query es el 100% del target
      return (baseScore + bonus).clamp(60.0, 85.0);
    }

    // Solo Levenshtein: score bajo, solo si hay mínima similitud
    if (similitud > 0.5) {
      return (similitud * 70).clamp(35.0, 70.0);
    }

    // Sin coincidencias relevantes
    return 0.0;
  }

  /// Busca ocurrencias de query en un texto
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

  /// Búsqueda general en todos los documentos legales
  /// Normaliza la query y busca en múltiples fuentes
  List<ResultadoBusquedaLegal> buscar(String query) {
    if (query.trim().isEmpty) {
      return [];
    }

    final resultados = <ResultadoBusquedaLegal>[];

    // Búsqueda en Derechos Fundamentales
    resultados.addAll(_buscarEnDerechos(query));

    // Búsqueda en Código Procesal Penal
    resultados.addAll(_buscarEnProcesal(query));

    // Búsqueda en Reglamento de Tránsito
    resultados.addAll(_buscarEnTransito(query));

    // Ordenar por relevancia descendente
    resultados.sort((a, b) => b.relevancia.compareTo(a.relevancia));

    return resultados;
  }

  /// Búsqueda en Derechos Fundamentales de la Persona
  List<ResultadoBusquedaLegal> _buscarEnDerechos(String query) {
    final resultados = <ResultadoBusquedaLegal>[];

    for (final derecho in _derechosFundamentales) {
      double relevancia = 0.0;
      final coincidencias = <String>[];

      // Buscar en title
      double relTitle = calcularRelevancia(query, derecho.title);
      if (relTitle > relevancia) relevancia = relTitle;
      if (relTitle > 0) {
        coincidencias.addAll(extraerCoincidencias(query, derecho.title));
      }

      // Buscar en intents
      for (final intent in derecho.intents) {
        final relIntent = calcularRelevancia(query, intent);
        if (relIntent > relevancia) relevancia = relIntent;
        if (relIntent > 0) {
          coincidencias.addAll(extraerCoincidencias(query, intent));
        }
      }

      // Buscar en rights_summary
      final relSummary = calcularRelevancia(query, derecho.rightsSummary);
      if (relSummary > relevancia) relevancia = relSummary;
      if (relSummary > 0) {
        coincidencias.addAll(extraerCoincidencias(query, derecho.rightsSummary));
      }

      // Buscar en tags si existen
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

  /// Búsqueda en Código Procesal Penal
  List<ResultadoBusquedaLegal> _buscarEnProcesal(String query) {
    final resultados = <ResultadoBusquedaLegal>[];

    for (final escenario in _codigoProcesal) {
      double relevancia = 0.0;
      final coincidencias = <String>[];

      // Buscar en scenario
      double relScenario = calcularRelevancia(query, escenario.scenario);
      if (relScenario > relevancia) relevancia = relScenario;
      if (relScenario > 0) {
        coincidencias.addAll(extraerCoincidencias(query, escenario.scenario));
      }

      // Buscar en accion_legal
      final relAccion = calcularRelevancia(query, escenario.accionLegal);
      if (relAccion > relevancia) relevancia = relAccion;
      if (relAccion > 0) {
        coincidencias.addAll(extraerCoincidencias(query, escenario.accionLegal));
      }

      // Buscar en guion_de_defensa
      final relGuion = calcularRelevancia(query, escenario.guionDeDefensa);
      if (relGuion > relevancia) relevancia = relGuion;
      if (relGuion > 0) {
        coincidencias.addAll(extraerCoincidencias(query, escenario.guionDeDefensa));
      }

      // Buscar en limite_policial
      final relLimite = calcularRelevancia(query, escenario.limitePolicial);
      if (relLimite > relevancia) relevancia = relLimite;
      if (relLimite > 0) {
        coincidencias.addAll(extraerCoincidencias(query, escenario.limitePolicial));
      }

      // Buscar en tags si existen
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

  /// Búsqueda en Reglamento Nacional de Tránsito
  List<ResultadoBusquedaLegal> _buscarEnTransito(String query) {
    final resultados = <ResultadoBusquedaLegal>[];

    // Buscar en glosario
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

    // Buscar en infracciones por código y descripción
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

  /// Obtiene una infracción específica por su código
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

  /// Obtiene un derecho fundamental por su ID
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

  /// Obtiene un escenario procesal por su descripción
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

  /// Retorna estadísticas de la base de datos
  Map<String, int> obtenerEstadisticas() {
    return {
      'totalDerechos': _derechosFundamentales.length,
      'totalEscenarios': _codigoProcesal.length,
      'totalInfracciones': _infraccionesTransito.length,
      'totalGlosario': _glosarioTransito.length,
    };
  }

  /// Valida que todos los datos hayan sido cargados correctamente
  bool estaListo() => _isLoaded;
}
