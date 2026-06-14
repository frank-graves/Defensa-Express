// ============================================================================
// MÓDULO 1: Resolución Ministerial N° 952-2018-IN
// Manual de Derechos Humanos Aplicados a la Función Policial
// ============================================================================

class DocumentoMetadata {
  final String titulo;
  final String baseLegal;
  final String fechaAprobacion;
  final String entidad;
  final String objetivo;

  const DocumentoMetadata({
    required this.titulo,
    required this.baseLegal,
    required this.fechaAprobacion,
    required this.entidad,
    required this.objetivo,
  });

  factory DocumentoMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentoMetadata(
      titulo: json['titulo'] ?? '',
      baseLegal: json['base_legal'] ?? '',
      fechaAprobacion: json['fecha_aprobacion'] ?? '',
      entidad: json['entidad'] ?? '',
      objetivo: json['objetivo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'base_legal': baseLegal,
    'fecha_aprobacion': fechaAprobacion,
    'entidad': entidad,
    'objetivo': objetivo,
  };
}

class PilarFundamental {
  final String concepto;
  final String descripcion;

  const PilarFundamental({
    required this.concepto,
    required this.descripcion,
  });

  factory PilarFundamental.fromJson(Map<String, dynamic> json) {
    return PilarFundamental(
      concepto: json['concepto'] ?? '',
      descripcion: json['descripcion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'concepto': concepto,
    'descripcion': descripcion,
  };
}

enum NivelFuerzaPreventiva {
  presenciaPolicial('Presencia policial'),
  verbalizacion('Verbalización'),
  controlContacto('Control de contacto');

  final String valor;
  const NivelFuerzaPreventiva(this.valor);

  factory NivelFuerzaPreventiva.fromString(String val) {
    return NivelFuerzaPreventiva.values.firstWhere(
      (e) => e.valor == val,
      orElse: () => NivelFuerzaPreventiva.presenciaPolicial,
    );
  }
}

enum NivelFuerzaReactiva {
  controlFisico('Control físico'),
  tacticasDefensivas('Tácticas defensivas no letales'),
  fuerzaLetal('Fuerza letal (último recurso)');

  final String valor;
  const NivelFuerzaReactiva(this.valor);

  factory NivelFuerzaReactiva.fromString(String val) {
    return NivelFuerzaReactiva.values.firstWhere(
      (e) => e.valor == val,
      orElse: () => NivelFuerzaReactiva.controlFisico,
    );
  }
}

enum EnfoqueAtencion {
  genero('Género'),
  interculturalidad('Interculturalidad'),
  derechosNinos('Derechos de Niños, Niñas y Adolescentes'),
  poblacionesVulnerables('Poblaciones vulnerables');

  final String valor;
  const EnfoqueAtencion(this.valor);

  factory EnfoqueAtencion.fromString(String val) {
    return EnfoqueAtencion.values.firstWhere(
      (e) => e.valor == val,
      orElse: () => EnfoqueAtencion.genero,
    );
  }
}

class PoblacionEspecifica {
  final String grupo;
  final String protocolo;

  const PoblacionEspecifica({
    required this.grupo,
    required this.protocolo,
  });

  factory PoblacionEspecifica.fromJson(Map<String, dynamic> json) {
    return PoblacionEspecifica(
      grupo: json['grupo'] ?? '',
      protocolo: json['protocolo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'grupo': grupo,
    'protocolo': protocolo,
  };
}

// ============================================================================
// MÓDULO 2: Reglamento Nacional de Tránsito
// D.S. N° 016-2009-MTC y modificatorias
// ============================================================================

class ReglamentoMetadata {
  final String nombre;
  final String baseLegal;
  final String ultimaActualizacionReferenciada;

  const ReglamentoMetadata({
    required this.nombre,
    required this.baseLegal,
    required this.ultimaActualizacionReferenciada,
  });

  factory ReglamentoMetadata.fromJson(Map<String, dynamic> json) {
    return ReglamentoMetadata(
      nombre: json['nombre'] ?? '',
      baseLegal: json['base_legal'] ?? '',
      ultimaActualizacionReferenciada:
          json['ultima_actualizacion_referenciada'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'base_legal': baseLegal,
    'ultima_actualizacion_referenciada': ultimaActualizacionReferenciada,
  };
}

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

class ReglaPrioridad {
  final String via;
  final String usuario;
  final String regla;

  const ReglaPrioridad({
    required this.via,
    required this.usuario,
    required this.regla,
  });

  factory ReglaPrioridad.fromJson(Map<String, dynamic> json) {
    return ReglaPrioridad(
      via: json['vía'] ?? '',
      usuario: json['usuario'] ?? '',
      regla: json['regla'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'vía': via,
    'usuario': usuario,
    'regla': regla,
  };
}

class LimiteVelocidadZona {
  final String limiteMaximo;
  final String rangoExtension;

  const LimiteVelocidadZona({
    required this.limiteMaximo,
    required this.rangoExtension,
  });

  factory LimiteVelocidadZona.fromJson(Map<String, dynamic> json) {
    return LimiteVelocidadZona(
      limiteMaximo: json['limite_maximo'] ?? '',
      rangoExtension: json['rango_extension'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'limite_maximo': limiteMaximo,
    'rango_extension': rangoExtension,
  };
}

class LimitesVelocidad {
  final String descripcion;
  final LimiteVelocidadZona zonaEscolar;
  final LimiteVelocidadZona zonaHospital;

  const LimitesVelocidad({
    required this.descripcion,
    required this.zonaEscolar,
    required this.zonaHospital,
  });

  factory LimitesVelocidad.fromJson(Map<String, dynamic> json) {
    return LimitesVelocidad(
      descripcion: json['descripcion'] ?? '',
      zonaEscolar: LimiteVelocidadZona.fromJson(
          json['zona_escolar'] ?? {'limite_maximo': '30 km/h'}),
      zonaHospital: LimiteVelocidadZona.fromJson(
          json['zona_hospital'] ?? {'limite_maximo': '30 km/h'}),
    );
  }

  Map<String, dynamic> toJson() => {
    'descripcion': descripcion,
    'zona_escolar': zonaEscolar.toJson(),
    'zona_hospital': zonaHospital.toJson(),
  };
}

class SancionPorReincidencia {
  final String ocurrencia;
  final String acumulacion;
  final String sancion;

  const SancionPorReincidencia({
    required this.ocurrencia,
    required this.acumulacion,
    required this.sancion,
  });

  factory SancionPorReincidencia.fromJson(Map<String, dynamic> json) {
    return SancionPorReincidencia(
      ocurrencia: json['ocurrencia'] ?? '',
      acumulacion: json['acumulacion'] ?? '',
      sancion: json['sancion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'ocurrencia': ocurrencia,
    'acumulacion': acumulacion,
    'sancion': sancion,
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
