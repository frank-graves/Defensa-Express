/**
 * MÓDULO 1: Resolución Ministerial N° 952-2018-IN
 * Manual de Derechos Humanos Aplicados a la Función Policial
 */

export interface DocumentoMetadata {
  titulo: string;
  base_legal: string;
  fecha_aprobacion: string;
  entidad: string;
  objetivo: string;
}

export interface PilarFundamental {
  concepto: string;
  descripcion: string;
}

export enum NivelFuerzaPreventiva {
  PRESENCIA_POLICIAL = "Presencia policial",
  VERBALIZACION = "Verbalización",
  CONTROL_CONTACTO = "Control de contacto",
}

export enum NivelFuerzaReactiva {
  CONTROL_FISICO = "Control físico",
  TACTICAS_DEFENSIVAS = "Tácticas defensivas no letales",
  FUERZA_LETAL = "Fuerza letal (último recurso)",
}

export enum EnfoqueAtencion {
  GENERO = "Género",
  INTERCULTURALIDAD = "Interculturalidad",
  DERECHOS_NINOS = "Derechos de Niños, Niñas y Adolescentes",
  POBLACIONES_VULNERABLES = "Poblaciones vulnerables",
}

export interface NivelesResistenciaCiudadana {
  pasiva: string[];
  activa: string[];
}

export interface ProcedimientoOperativo {
  control_identidad: string;
  detencion: {
    causas: string[];
    obligaciones: string[];
  };
  registro_personas: string;
}

export interface PoblacionEspecifica {
  grupo: string;
  protocolo: string;
}

export interface ManejoDeMasas {
  objetivo: string;
  restriccion: string;
}

export interface EticaResponsabilidad {
  prohibicion_tortura: string;
  ordenes_ilicitas: string;
}

export interface ContenidoEstructurado {
  marco_normativo: {
    internacional: string[];
    nacional: string[];
  };
  principios_uso_fuerza: {
    legalidad: string;
    necesidad: string;
    proporcionalidad: string;
  };
  niveles_resistencia_ciudadana: NivelesResistenciaCiudadana;
  procedimientos_operativos: ProcedimientoOperativo;
  poblaciones_especificas: PoblacionEspecifica[];
  manejo_de_masas: ManejoDeMasas;
}

/**
 * Interfaz principal para Resolución Ministerial N° 952-2018-IN
 * Estructura del manual completo de derechos humanos aplicados a función policial
 */
export interface ResolucionMinisterial952 {
  documento: DocumentoMetadata;
  pilares_fundamentales: PilarFundamental[];
  enfoques_de_atencion: EnfoqueAtencion[];
  niveles_de_fuerza: {
    preventivos: NivelFuerzaPreventiva[];
    reactivos: NivelFuerzaReactiva[];
  };
  medios_de_policia: string[];
  manual_id: string;
  titulo: string;
  vigencia: string;
  contenido_estructurado: ContenidoEstructurado;
  etica_y_responsabilidad: EticaResponsabilidad;
}

/**
 * MÓDULO 2: Reglamento Nacional de Tránsito
 * D.S. N° 016-2009-MTC y modificatorias
 */

export interface ReglamentoMetadata {
  nombre: string;
  base_legal: string;
  ultima_actualizacion_referenciada: string;
}

export interface GlosarioTermino {
  termino: string;
  definicion: string;
}

export enum GravedadInfraccion {
  GRAVE = "Grave",
  MUY_GRAVE = "Muy Grave",
  LEVE = "Leve",
}

export interface Infraccion {
  codigo: string;
  descripcion: string;
  gravedad: GravedadInfraccion;
  sancion_monto: string;
  puntos: number;
  medida_preventiva: string;
}

export interface ReglaPrioridad {
  vía: string;
  usuario: string;
  regla: string;
}

export interface LimiteVelocidadZona {
  limite_maximo: string;
  rango_extension: string;
}

export interface LimitesVelocidad {
  descripcion: string;
  zona_escolar: LimiteVelocidadZona;
  zona_hospital: LimiteVelocidadZona;
}

export interface SancionPorReincidencia {
  ocurrencia: string;
  acumulacion: string;
  sancion: string;
}

export interface SistemaPuntos {
  reglas_acumulacion: {
    limite_puntos_maximo: number;
    vigencia_puntos: string;
  };
  sanciones_por_reincidencia: SancionPorReincidencia[];
  requisitos_adicionales: string;
}

export interface SenalReguladora {
  senal: string;
  forma: string;
}

export interface ClasificacionVertical {
  tipo: string;
  finalidad: string;
  cumplimiento: string;
  formas: {
    general: string;
    excepciones: SenalReguladora[];
  };
}

export interface Senalizacion {
  clasificacion_vertical: ClasificacionVertical[];
  marcas_pavimento_clasificacion: string[];
}

/**
 * Interfaz principal para Reglamento Nacional de Tránsito
 * Estructura completa del reglamento peruano de circulación vial
 */
export interface ReglamentoNacionalTransito {
  reglamento_metadata: ReglamentoMetadata;
  glosario: GlosarioTermino[];
  infracciones: Infraccion[];
  reglas_prioridad: ReglaPrioridad[];
  limites_velocidad: LimitesVelocidad;
  sistema_puntos: SistemaPuntos;
  senalizacion: Senalizacion;
}

/**
 * MÓDULO 3: Derechos Fundamentales de la Persona
 * Escenarios de intervención policial y derechos constitucionales
 */

/**
 * Interfaz para cada derecho fundamental con base legal y asesoramiento
 * Mapea derechos constitucionales peruanos a escenarios cotidianos
 */
export interface DerechoFundamental {
  id: string;
  title: string;
  intents: string[];
  immediate_action: string;
  rights_summary: string;
  legal_basis: string;
  tags?: string[];
}

export type DerechosFundamentalesArray = DerechoFundamental[];

/**
 * MÓDULO 4: Código Procesal Penal
 * Artículos y procedimientos de defensa en contexto policial
 */

/**
 * Interfaz para escenarios de detención y procedimientos legales
 * Contiene referencias a artículos específicos del CPP y estrategias de defensa
 */
export interface EscenarioProcesal {
  scenario: string;
  accion_legal: string;
  guion_de_defensa: string;
  limite_policial: string;
  tags?: string[];
}

export type CodigoPenalArray = EscenarioProcesal[];

/**
 * MÓDULO 5: Tipos Utilitarios de Integración
 * Tipos para facilitar operaciones cross-módulo
 */

export type GravedadInfraccionType = keyof typeof GravedadInfraccion;
export type NivelFuerzaType = NivelFuerzaPreventiva | NivelFuerzaReactiva;

export interface DocumentoLegalGenerico {
  id: string;
  titulo: string;
  base_legal: string;
}

/**
 * Union type para todos los documentos legales
 */
export type DocumentoLegal =
  | ResolucionMinisterial952
  | ReglamentoNacionalTransito
  | DerechoFundamental
  | EscenarioProcesal;

/**
 * Respuesta genérica de búsqueda en la base de datos legal
 */
export interface ResultadoBusquedaLegal {
  documento_tipo: "DERECHOS" | "TRANSITO" | "PENAL" | "DERECHOS_HUMANOS";
  resultado: DocumentoLegal;
  coincidencias: string[];
  relevancia: number;
}
