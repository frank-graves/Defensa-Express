import 'dart:convert';
import 'package:flutter/services.dart';

/// **Motor Secundario Mejorado (Fase 3)**
/// 
/// **Cambios:**
/// - ✅ Threshold base aumentado a 0.40 (antes: 0.15) - reduce falsos positivos
/// - ✅ Filtro de stop-words mejorado - elimina ruido gramatical
/// - ✅ Jaccard similarity con tokenización robusta
/// - ✅ Privacy-First: sin telemetría, datos locales

class LegalScenario {
  final String id;
  final String title;
  final List<String> intents;
  final String immediateAction;
  final String rightsSummary;
  final String legalBasis;

  LegalScenario({
    required this.id,
    required this.title,
    required this.intents,
    required this.immediateAction,
    required this.rightsSummary,
    required this.legalBasis,
  });

  factory LegalScenario.fromJson(Map<String, dynamic> json) {
    return LegalScenario(
      id: json['id'],
      title: json['title'],
      intents: List<String>.from(json['intents']),
      immediateAction: json['immediate_action'],
      rightsSummary: json['rights_summary'],
      legalBasis: json['legal_basis'],
    );
  }
}

class LocalEngine {
  List<LegalScenario> _scenarios = [];
  
  /// **Stop Words Expandidos (Fase 3)**
  /// 
  /// Se expandieron stop-words con conectores y palabras de relleno
  /// que no aportan semántica. Esto previene falsos positivos donde
  /// dos textos coinciden solo por preposiciones.
  /// 
  /// **Ejemplos de Falsos Positivos sin este filtro:**
  /// - Query: "de" → Match: "el proceso de detención" (Jaccard = 0.15, MATCH!)
  /// - Query: "con un" → Match: "con una orden" (Jaccard = 0.20, MATCH!)
  /// 
  /// **Solución:** Excluir estas palabras antes de calcular Jaccard
  final Set<String> _stopWords = {
    // Artículos
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
    
    // Preposiciones comunes
    'a', 'ante', 'bajo', 'con', 'de', 'desde', 'en', 'para',
    'por', 'segun', 'sin', 'sobre', 'entre', 'hacia', 'hasta', 'tras',
    
    // Conjunciones
    'y', 'e', 'ni', 'que', 'o', 'u', 'pues', 'sino', 'pero', 'mas',
    
    // Pronombres débiles
    'me', 'te', 'se', 'mi', 'tu', 'su', 'mis', 'tus', 'sus',
    'mio', 'tuyo', 'suyo', 'mia', 'tuya', 'suya',
    
    // Verbos auxiliares y copulativos
    'no', 'si', 'es', 'soy', 'eres', 'somos', 'sois',
    'estoy', 'estamos', 'estais', 'estan', 'estar',
    'tengo', 'tienes', 'tiene', 'tenemos', 'teneis', 'tienen',
    'ser', 'tener', 'haber', 'he', 'has', 'ha', 'hemos', 'habeis', 'han',
    'estar',
    
    // Adverbios muy comunes
    'no', 'si', 'no', 'muy', 'mas', 'menos', 'solo', 'tambien', 'solo',
    'aqui', 'alli', 'aca', 'alla', 'donde', 'cuando', 'como', 'cuanto',
    'entonces', 'ahora', 'ya', 'aun', 'todavia', 'siempre', 'nunca', 'jamas',
    
    // Palabras conectoras y de relleno
    'tal', 'cual', 'cuales', 'quien', 'quienes', 'este', 'ese', 'aquel',
    'esto', 'eso', 'aquello', 'esa', 'esas', 'ese', 'esos', 'aquella',
    'aquellas', 'aquello', 'aquellos', 'aquella',
  };

  Future<void> loadDataset() async {
    try {
      final String response = await rootBundle.loadString('assets/dataset/legal_scenarios.json');
      final data = await json.decode(response);
      _scenarios = (data['scenarios'] as List)
          .map((item) => LegalScenario.fromJson(item))
          .toList();
    } catch (e) {
      _scenarios = [];
    }
  }

  /// **Normalización de Texto (igual que main service)**
  String _normalize(String input) {
    const diacriticMap = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
      'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
    };
    
    String result = input.toLowerCase();
    
    diacriticMap.forEach((dia, sinDia) {
      result = result.replaceAll(dia, sinDia);
    });
    
    return result.replaceAll(RegExp(r'[^\w\s]'), '');
  }

  /// **Tokenización con Filtro de Stop-Words (Mejorado en Fase 3)**
  /// 
  /// **Cambios:**
  /// - ✅ Normaliza el texto primero
  /// - ✅ Divide en tokens
  /// - ✅ FILTRA stop-words: solo tokens relevantes
  /// - ✅ Retorna Set (para Jaccard)
  /// 
  /// **Ejemplo:**
  /// ```
  /// Input:  "La detención de una persona"
  /// Tokens: ["la", "detencion", "de", "una", "persona"]
  /// Filtrado: ["detencion", "persona"]  ← solo palabras significativas
  /// ```
  Set<String> _tokenize(String text) {
    final normalized = _normalize(text);
    final tokens = normalized.split(RegExp(r'\s+'));
    
    return tokens
        .where((token) => token.isNotEmpty && !_stopWords.contains(token))
        .toSet();
  }

  /// **Similitud de Jaccard Mejorada (Fase 3)**
  /// 
  /// **Fórmula:**
  /// ```
  /// Jaccard = |A ∩ B| / |A ∪ B|
  /// ```
  /// 
  /// **Propiedades:**
  /// - Rango: [0, 1] donde 1 = sets idénticos
  /// - Insensible al orden de tokens
  /// - Perfecto para búsqueda semántica ligera
  /// 
  /// **Ejemplo:**
  /// ```
  /// setA = {"persona", "detenida"}
  /// setB = {"persona", "arrestada", "detenida"}
  /// 
  /// Intersección = {"persona", "detenida"} = 2
  /// Unión = {"persona", "detenida", "arrestada"} = 3
  /// Jaccard = 2/3 = 0.67
  /// ```
  double _calculateJaccardSimilarity(Set<String> setA, Set<String> setB) {
    if (setA.isEmpty && setB.isEmpty) return 0.0;
    if (setA.isEmpty || setB.isEmpty) return 0.0;  // Guard: sin overlap
    
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    
    return union == 0 ? 0.0 : intersection / union;
  }

  /// **Búsqueda Mejorada (Fase 3)**
  /// 
  /// **Cambios principales:**
  /// - ✅ Threshold aumentado a 0.40 (antes: 0.15) - reduce false positives
  /// - ✅ Usa Jaccard solo para tokens significativos (sin stop-words)
  /// - ✅ Busca en múltiples intents y retorna mejor score
  /// 
  /// **Algoritmo:**
  /// 1. Tokeniza query (sin stop-words)
  /// 2. Para cada scenario:
  ///    - Tokeniza cada intent (sin stop-words)
  ///    - Calcula Jaccard(queryTokens, intentTokens)
  ///    - Usa el mejor score encontrado
  /// 3. Si score >= threshold (0.40), retorna el scenario
  /// 
  /// **Valores Recomendados de Threshold:**
  /// - 0.35-0.40: Búsqueda general (equilibrio)
  /// - 0.50+: Búsqueda estricta (pocos false positives)
  /// - <0.35: Búsqueda permisiva (muchos false positives)
  /// 
  /// **Ejemplo:**
  /// ```
  /// Query: "persona detenida"
  /// queryTokens = {"persona", "detenida"}
  /// 
  /// Scenario 1 Intent: "detención de una persona"
  /// intentTokens = {"detencion", "persona"}
  /// Jaccard = 1/3 = 0.33 ✗ (< 0.40)
  /// 
  /// Scenario 2 Intent: "persona detenida por policía"
  /// intentTokens = {"persona", "detenida", "policia"}
  /// Jaccard = 2/3 = 0.67 ✓ (>= 0.40)
  /// ```
  LegalScenario? search(String query, {double threshold = 0.40}) {
    if (query.trim().isEmpty) return null;
    
    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return null;

    LegalScenario? bestMatch;
    double highestScore = 0.0;

    for (var scenario in _scenarios) {
      for (var intent in scenario.intents) {
        final intentTokens = _tokenize(intent);
        final score = _calculateJaccardSimilarity(queryTokens, intentTokens);
        
        if (score > highestScore) {
          highestScore = score;
          bestMatch = scenario;
        }
      }
    }

    return highestScore >= threshold ? bestMatch : null;
  }
}