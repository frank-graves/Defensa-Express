/**
 * Punto de entrada central para todos los tipos y servicios
 * Importa desde aquí para acceso simplificado
 */

// Re-exportar todos los tipos
export * from "./types/index";

// Re-exportar servicios
export { LegalDataService, servicioLegal } from "./services/LegalDataService";

// Re-exportar utilidades
export {
  normalizarTexto,
  tokenizar,
  calcularSimilitud,
  calcularRelevancia,
  extraerCoincidencias,
  filtrarStopWords,
  STOP_WORDS_ES,
} from "./utils/normalizacion";
