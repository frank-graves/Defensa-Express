// ============================================================================
// MÓDULO 1: Resolución Ministerial N° 952-2018-IN
// Manual de Derechos Humanos Aplicados a la Función Policial
// ============================================================================

// ============================================================================
// MÓDULO 2: Reglamento Nacional de Tránsito
// D.S. N° 016-2009-MTC y modificatorias
// ============================================================================

class GlosarioTermino {
  final String termino;
  final String definicion;

  const GlosarioTermino({
    required this.termino,
    required this.definicion,
  });

  factory GlosarioTermino.fromJson(Map<String, dynamic> json) {
    return GlosarioTermino(
      termino: json['termino'] ?? '',
      definicion: json['definicion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'termino': termino,
    'definicion': definicion,
  };
}

enum GravedadInfraccion {
  grave('Grave'),
  muyGrave('Muy Grave'),
  leve('Leve');

  final String valor;
  const GravedadInfraccion(this.valor);

  factory GravedadInfraccion.fromString(String val) {
    return GravedadInfraccion.values.firstWhere(
      (e) => e.valor == val,
      orElse: () => GravedadInfraccion.leve,
    );
  }
}

class Infraccion {
  final String codigo;
  final String descripcion;
  final GravedadInfraccion gravedad;
  final String sancionMonto;
  final int puntos;
  final String medidaPreventiva;

  const Infraccion({
    required this.codigo,
    required this.descripcion,
    required this.gravedad,
    required this.sancionMonto,
    required this.puntos,
    required this.medidaPreventiva,
  });

  factory Infraccion.fromJson(Map<String, dynamic> json) {
    return Infraccion(
      codigo: json['codigo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      gravedad: GravedadInfraccion.fromString(json['gravedad'] ?? 'Leve'),
      sancionMonto: json['sancion_monto'] ?? '',
      puntos: json['puntos'] ?? 0,
      medidaPreventiva: json['medida_preventiva'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'descripcion': descripcion,
    'gravedad': gravedad.valor,
    'sancion_monto': sancionMonto,
    'puntos': puntos,
    'medida_preventiva': medidaPreventiva,
  };
}

// ============================================================================
// MÓDULO 3: Derechos Fundamentales de la Persona
// Escenarios de intervención policial y derechos constitucionales
// ============================================================================

/// Interfaz para cada derecho fundamental con base legal y asesoramiento
/// Mapea derechos constitucionales peruanos a escenarios cotidianos
class DerechoFundamental {
  final String id;
  final String title;
  final List<String> intents;
  final String immediateAction;
  final String rightsSummary;
  final String legalBasis;
  final List<String>? tags;

  const DerechoFundamental({
    required this.id,
    required this.title,
    required this.intents,
    required this.immediateAction,
    required this.rightsSummary,
    required this.legalBasis,
    this.tags,
  });

  factory DerechoFundamental.fromJson(Map<String, dynamic> json) {
    return DerechoFundamental(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      intents: List<String>.from(json['intents'] ?? []),
      immediateAction: json['immediate_action'] ?? '',
      rightsSummary: json['rights_summary'] ?? '',
      legalBasis: json['legal_basis'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'intents': intents,
    'immediate_action': immediateAction,
    'rights_summary': rightsSummary,
    'legal_basis': legalBasis,
    if (tags != null) 'tags': tags,
  };
}

// ============================================================================
// MÓDULO 4: Código Procesal Penal
// Artículos y procedimientos de defensa en contexto policial
// ============================================================================

/// Interfaz para escenarios de detención y procedimientos legales
/// Contiene referencias a artículos específicos del CPP y estrategias de defensa
class EscenarioProcesal {
  final String scenario;
  final String accionLegal;
  final String guionDeDefensa;
  final String limitePolicial;
  final List<String>? tags;

  const EscenarioProcesal({
    required this.scenario,
    required this.accionLegal,
    required this.guionDeDefensa,
    required this.limitePolicial,
    this.tags,
  });

  factory EscenarioProcesal.fromJson(Map<String, dynamic> json) {
    return EscenarioProcesal(
      scenario: json['scenario'] ?? '',
      accionLegal: json['accion_legal'] ?? '',
      guionDeDefensa: json['guion_de_defensa'] ?? '',
      limitePolicial: json['limite_policial'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'scenario': scenario,
    'accion_legal': accionLegal,
    'guion_de_defensa': guionDeDefensa,
    'limite_policial': limitePolicial,
    if (tags != null) 'tags': tags,
  };
}

// ============================================================================
// MÓDULO 5: Resultado de Búsqueda
// ============================================================================

/// Respuesta genérica de búsqueda en la base de datos legal
class ResultadoBusquedaLegal {
  final String documentoTipo;
  final dynamic resultado;
  final List<String> coincidencias;
  final double relevancia;

  const ResultadoBusquedaLegal({
    required this.documentoTipo,
    required this.resultado,
    required this.coincidencias,
    required this.relevancia,
  });

  factory ResultadoBusquedaLegal.fromJson(Map<String, dynamic> json) {
    return ResultadoBusquedaLegal(
      documentoTipo: json['documento_tipo'] ?? '',
      resultado: json['resultado'],
      coincidencias: List<String>.from(json['coincidencias'] ?? []),
      relevancia: (json['relevancia'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'documento_tipo': documentoTipo,
    'resultado': resultado,
    'coincidencias': coincidencias,
    'relevancia': relevancia,
  };
}
