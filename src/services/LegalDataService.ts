import * as path from "path";
import * as fs from "fs";
import {
  ResolucionMinisterial952,
  ReglamentoNacionalTransito,
  DerechosFundamentalesArray,
  CodigoPenalArray,
  Infraccion,
  ResultadoBusquedaLegal,
  DerechoFundamental,
  EscenarioProcesal,
  GlosarioTermino,
} from "../types/index";
import {
  normalizarTexto,
  tokenizar,
  calcularRelevancia,
  extraerCoincidencias,
  filtrarStopWords,
} from "../utils/normalizacion";

/**
 * Servicio de búsqueda y acceso a base de datos legal
 * Privacy-First: Todas las operaciones se ejecutan localmente sin acceso a red
 *
 * Procesa 4 documentos legales principales:
 * - Resolución Ministerial 952-2018 (Derechos Humanos)
 * - Reglamento Nacional de Tránsito
 * - Derechos Fundamentales de la Persona
 * - Código Procesal Penal
 */
export class LegalDataService {
  private resolucionMinisterial952: ResolucionMinisterial952 | null = null;
  private reglamentoTransito: ReglamentoNacionalTransito | null = null;
  private derechosFundamentales: DerechosFundamentalesArray = [];
  private codigoProcesal: CodigoPenalArray = [];
  private dataPath: string;

  constructor(dataPath: string = "Json Shit") {
    this.dataPath = dataPath;
  }

  /**
   * Carga todos los archivos JSON desde el sistema de archivos
   * Debe ejecutarse una sola vez en el ciclo de vida de la aplicación
   */
  public async cargarDatos(): Promise<void> {
    try {
      // Cargar Resolución Ministerial 952-2018
      const rmPath = path.join(
        this.dataPath,
        "Resolución Ministerial N° 952-2018-IN (952-2018-in-20-aproba...).json"
      );
      this.resolucionMinisterial952 = JSON.parse(fs.readFileSync(rmPath, "utf-8"));

      // Cargar Reglamento Nacional de Tránsito
      const rntPath = path.join(this.dataPath, "Reglamento Nacional de Tránsito.json");
      this.reglamentoTransito = JSON.parse(fs.readFileSync(rntPath, "utf-8"));

      // Cargar Derechos Fundamentales
      const dfPath = path.join(
        this.dataPath,
        "Derechos fundamentales de la persona.json"
      );
      this.derechosFundamentales = JSON.parse(fs.readFileSync(dfPath, "utf-8"));

      // Cargar Código Procesal Penal
      const cppPath = path.join(this.dataPath, "Código Procesal Penal.json");
      this.codigoProcesal = JSON.parse(fs.readFileSync(cppPath, "utf-8"));

      console.log("✓ Base de datos legal cargada exitosamente");
    } catch (error) {
      console.error("Error al cargar datos legales:", error);
      throw new Error(`Fallo al cargar base de datos legal: ${error}`);
    }
  }

  /**
   * Búsqueda general en todos los documentos legales
   * Normaliza la query y busca en múltiples fuentes
   *
   * @param query - Texto de búsqueda (se normaliza automáticamente)
   * @returns Array de resultados ordenados por relevancia (DESC)
   */
  public buscar(query: string): ResultadoBusquedaLegal[] {
    if (!query || query.trim().length === 0) {
      return [];
    }

    const resultados: ResultadoBusquedaLegal[] = [];

    // Búsqueda en Reglamento Nacional de Tránsito
    resultados.push(...this.buscarEnTransito(query));

    // Búsqueda en Derechos Fundamentales
    resultados.push(...this.buscarEnDerechos(query));

    // Búsqueda en Código Procesal Penal
    resultados.push(...this.buscarEnProcesal(query));

    // Búsqueda en Resolución Ministerial 952-2018
    resultados.push(...this.buscarEnResolucion(query));

    // Ordenar por relevancia descendente
    return resultados.sort((a, b) => b.relevancia - a.relevancia);
  }

  /**
   * Búsqueda específica en Reglamento Nacional de Tránsito
   * Busca en glosario e infracciones
   */
  private buscarEnTransito(query: string): ResultadoBusquedaLegal[] {
    const resultados: ResultadoBusquedaLegal[] = [];

    if (!this.reglamentoTransito) return resultados;

    const queryNorm = normalizarTexto(query);

    // Buscar en glosario
    if (this.reglamentoTransito.glosario) {
      for (const termino of this.reglamentoTransito.glosario) {
        const relevancia = Math.max(
          calcularRelevancia(query, termino.termino),
          calcularRelevancia(query, termino.definicion)
        );

        if (relevancia > 0) {
          resultados.push({
            documento_tipo: "TRANSITO",
            resultado: termino as any,
            coincidencias: [
              ...extraerCoincidencias(query, termino.termino),
              ...extraerCoincidencias(query, termino.definicion),
            ],
            relevancia,
          });
        }
      }
    }

    // Buscar en infracciones por código y descripción
    if (this.reglamentoTransito.infracciones) {
      for (const infraccion of this.reglamentoTransito.infracciones) {
        const relevancia = Math.max(
          calcularRelevancia(query, infraccion.codigo),
          calcularRelevancia(query, infraccion.descripcion)
        );

        if (relevancia > 0) {
          resultados.push({
            documento_tipo: "TRANSITO",
            resultado: infraccion as any,
            coincidencias: [
              ...extraerCoincidencias(query, infraccion.codigo),
              ...extraerCoincidencias(query, infraccion.descripcion),
            ],
            relevancia,
          });
        }
      }
    }

    return resultados;
  }

  /**
   * Búsqueda en Derechos Fundamentales de la Persona
   * Busca en intents, title, summary y tags
   */
  private buscarEnDerechos(query: string): ResultadoBusquedaLegal[] {
    const resultados: ResultadoBusquedaLegal[] = [];

    for (const derecho of this.derechosFundamentales) {
      let relevancia = 0;
      const coincidencias: string[] = [];

      // Buscar en title
      const relTitle = calcularRelevancia(query, derecho.title);
      if (relTitle > relevancia) relevancia = relTitle;
      if (relTitle > 0) {
        coincidencias.push(...extraerCoincidencias(query, derecho.title));
      }

      // Buscar en intents
      for (const intent of derecho.intents) {
        const relIntent = calcularRelevancia(query, intent);
        if (relIntent > relevancia) relevancia = relIntent;
        if (relIntent > 0) {
          coincidencias.push(...extraerCoincidencias(query, intent));
        }
      }

      // Buscar en rights_summary
      const relSummary = calcularRelevancia(query, derecho.rights_summary);
      if (relSummary > relevancia) relevancia = relSummary;
      if (relSummary > 0) {
        coincidencias.push(...extraerCoincidencias(query, derecho.rights_summary));
      }

      // Buscar en tags si existen
      if (derecho.tags) {
        for (const tag of derecho.tags) {
          const relTag = calcularRelevancia(query, tag);
          if (relTag > relevancia) relevancia = relTag;
          if (relTag > 0) {
            coincidencias.push(tag);
          }
        }
      }

      if (relevancia > 0) {
        resultados.push({
          documento_tipo: "DERECHOS",
          resultado: derecho as any,
          coincidencias: [...new Set(coincidencias)], // Eliminar duplicados
          relevancia,
        });
      }
    }

    return resultados;
  }

  /**
   * Búsqueda en Código Procesal Penal
   * Busca en scenario, accion_legal y guion_de_defensa
   */
  private buscarEnProcesal(query: string): ResultadoBusquedaLegal[] {
    const resultados: ResultadoBusquedaLegal[] = [];

    for (const escenario of this.codigoProcesal) {
      let relevancia = 0;
      const coincidencias: string[] = [];

      // Buscar en scenario
      const relScenario = calcularRelevancia(query, escenario.scenario);
      if (relScenario > relevancia) relevancia = relScenario;
      if (relScenario > 0) {
        coincidencias.push(...extraerCoincidencias(query, escenario.scenario));
      }

      // Buscar en accion_legal
      const relAccion = calcularRelevancia(query, escenario.accion_legal);
      if (relAccion > relevancia) relevancia = relAccion;
      if (relAccion > 0) {
        coincidencias.push(...extraerCoincidencias(query, escenario.accion_legal));
      }

      // Buscar en guion_de_defensa
      const relGuion = calcularRelevancia(query, escenario.guion_de_defensa);
      if (relGuion > relevancia) relevancia = relGuion;
      if (relGuion > 0) {
        coincidencias.push(...extraerCoincidencias(query, escenario.guion_de_defensa));
      }

      // Buscar en limite_policial
      const relLimite = calcularRelevancia(query, escenario.limite_policial);
      if (relLimite > relevancia) relevancia = relLimite;
      if (relLimite > 0) {
        coincidencias.push(...extraerCoincidencias(query, escenario.limite_policial));
      }

      // Buscar en tags si existen
      if (escenario.tags) {
        for (const tag of escenario.tags) {
          const relTag = calcularRelevancia(query, tag);
          if (relTag > relevancia) relevancia = relTag;
          if (relTag > 0) {
            coincidencias.push(tag);
          }
        }
      }

      if (relevancia > 0) {
        resultados.push({
          documento_tipo: "PENAL",
          resultado: escenario as any,
          coincidencias: [...new Set(coincidencias)],
          relevancia,
        });
      }
    }

    return resultados;
  }

  /**
   * Búsqueda en Resolución Ministerial 952-2018
   * Busca en estructura jerárquica de derechos humanos
   */
  private buscarEnResolucion(query: string): ResultadoBusquedaLegal[] {
    const resultados: ResultadoBusquedaLegal[] = [];

    if (!this.resolucionMinisterial952) return resultados;

    // Buscar en pilares fundamentales
    if (this.resolucionMinisterial952.pilares_fundamentales) {
      for (const pilar of this.resolucionMinisterial952.pilares_fundamentales) {
        const relevancia = Math.max(
          calcularRelevancia(query, pilar.concepto),
          calcularRelevancia(query, pilar.descripcion)
        );

        if (relevancia > 0) {
          resultados.push({
            documento_tipo: "DERECHOS_HUMANOS",
            resultado: pilar as any,
            coincidencias: [
              ...extraerCoincidencias(query, pilar.concepto),
              ...extraerCoincidencias(query, pilar.descripcion),
            ],
            relevancia,
          });
        }
      }
    }

    return resultados;
  }

  /**
   * Obtiene una infracción específica por su código
   * Búsqueda rápida sin procesar relevancia
   *
   * @param codigo - Código de infracción (ej. "G.31")
   * @returns Objeto de infracción o undefined
   */
  public obtenerInfraccionPorCodigo(codigo: string): Infraccion | undefined {
    if (!this.reglamentoTransito) return undefined;

    const codigoNorm = normalizarTexto(codigo);
    return this.reglamentoTransito.infracciones.find(
      (inf) => normalizarTexto(inf.codigo) === codigoNorm
    );
  }

  /**
   * Obtiene un derecho fundamental por su ID
   *
   * @param id - ID único del derecho (ej. "inviolabilidad_domicilio")
   * @returns Objeto de derecho o undefined
   */
  public obtenerDerechoPorId(id: string): DerechoFundamental | undefined {
    const idNorm = normalizarTexto(id);
    return this.derechosFundamentales.find(
      (d) => normalizarTexto(d.id) === idNorm
    );
  }

  /**
   * Obtiene un escenario procesal por su descripción
   *
   * @param scenario - Descripción del escenario
   * @returns Objeto de escenario o undefined
   */
  public obtenerEscenarioPorNombre(scenario: string): EscenarioProcesal | undefined {
    const scenarioNorm = normalizarTexto(scenario);
    return this.codigoProcesal.find(
      (e) => normalizarTexto(e.scenario) === scenarioNorm
    );
  }

  /**
   * Retorna estadísticas de la base de datos
   * Útil para depuración y validación de carga
   */
  public obtenerEstadisticas(): {
    totalDerechos: number;
    totalEscenarios: number;
    totalInfracciones: number;
    totalGlosario: number;
  } {
    return {
      totalDerechos: this.derechosFundamentales.length,
      totalEscenarios: this.codigoProcesal.length,
      totalInfracciones: this.reglamentoTransito?.infracciones.length ?? 0,
      totalGlosario: this.reglamentoTransito?.glosario.length ?? 0,
    };
  }

  /**
   * Valida que todos los datos hayan sido cargados correctamente
   */
  public estaListo(): boolean {
    return (
      this.resolucionMinisterial952 !== null &&
      this.reglamentoTransito !== null &&
      this.derechosFundamentales.length > 0 &&
      this.codigoProcesal.length > 0
    );
  }
}

/**
 * Instancia singleton exportada del servicio
 * Se recomienda inicializar una sola vez en el punto de entrada
 */
export const servicioLegal = new LegalDataService();
