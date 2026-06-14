/**
 * Utilidades para normalización y búsqueda de texto
 * Privacy-First: Todas las operaciones son locales y sincrónicas
 */

/**
 * Normaliza texto removiendo tildes, mayúsculas y caracteres especiales
 * Manteniendo espacios y números para búsqueda semántica correcta
 */
export function normalizarTexto(texto: string): string {
  if (!texto) return "";

  return texto
    .toLowerCase()
    .normalize("NFD") // Descompone caracteres acentuados
    .replace(/[\u0300-\u036f]/g, "") // Elimina diacríticos
    .replace(/[^\w\s]/g, "") // Elimina caracteres especiales excepto espacios
    .trim();
}

/**
 * Tokeniza un texto en palabras individuales
 * Filtra palabras muy cortas (< 2 caracteres)
 */
export function tokenizar(texto: string): string[] {
  return normalizarTexto(texto)
    .split(/\s+/)
    .filter((palabra) => palabra.length > 1);
}

/**
 * Calcula similitud Levenshtein entre dos strings (0-1)
 * Útil para búsqueda fuzzy
 */
export function calcularSimilitud(s1: string, s2: string): number {
  const norm1 = normalizarTexto(s1);
  const norm2 = normalizarTexto(s2);

  if (norm1 === norm2) return 1;
  if (!norm1 || !norm2) return 0;

  const matriz: number[][] = Array(norm1.length + 1)
    .fill(null)
    .map(() => Array(norm2.length + 1).fill(0));

  for (let i = 0; i <= norm1.length; i++) matriz[i][0] = i;
  for (let j = 0; j <= norm2.length; j++) matriz[0][j] = j;

  for (let i = 1; i <= norm1.length; i++) {
    for (let j = 1; j <= norm2.length; j++) {
      const costo = norm1[i - 1] === norm2[j - 1] ? 0 : 1;
      matriz[i][j] = Math.min(
        matriz[i - 1][j] + 1,
        matriz[i][j - 1] + 1,
        matriz[i - 1][j - 1] + costo
      );
    }
  }

  const distancia = matriz[norm1.length][norm2.length];
  const maxLen = Math.max(norm1.length, norm2.length);

  return Math.max(0, 1 - distancia / maxLen);
}

/**
 * Calcula relevancia entre query y target
 * Retorna puntuación 0-100
 */
export function calcularRelevancia(query: string, target: string): number {
  const queryNorm = normalizarTexto(query);
  const targetNorm = normalizarTexto(target);

  // Coincidencia exacta: máxima relevancia
  if (queryNorm === targetNorm) return 100;

  // Coincidencia al inicio: alta relevancia
  if (targetNorm.startsWith(queryNorm)) return 90;

  // Coincidencia parcial (subcadena): relevancia media
  if (targetNorm.includes(queryNorm)) return 75;

  // Similitud Levenshtein: baja-media relevancia
  const similitud = calcularSimilitud(queryNorm, targetNorm);
  return Math.round(similitud * 60);
}

/**
 * Busca ocurrencias de query en un texto
 * Retorna índices de coincidencias normalizadas
 */
export function extraerCoincidencias(query: string, target: string): string[] {
  const queryNorm = normalizarTexto(query);
  const targetNorm = normalizarTexto(target);
  const targetOriginal = target;

  const coincidencias: string[] = [];

  if (targetNorm.includes(queryNorm)) {
    const indice = targetNorm.indexOf(queryNorm);
    const inicio = Math.max(0, indice - 30);
    const fin = Math.min(targetOriginal.length, indice + queryNorm.length + 30);
    coincidencias.push(`...${targetOriginal.substring(inicio, fin).trim()}...`);
  }

  return coincidencias;
}

/**
 * Stop words comunes en español para filtrar resultados irrelevantes
 */
export const STOP_WORDS_ES = new Set([
  "el",
  "la",
  "los",
  "las",
  "un",
  "una",
  "unos",
  "unas",
  "a",
  "ante",
  "bajo",
  "con",
  "de",
  "desde",
  "en",
  "para",
  "por",
  "segun",
  "sin",
  "sobre",
  "y",
  "e",
  "ni",
  "que",
  "me",
  "te",
  "se",
  "mi",
  "tu",
  "su",
  "mis",
  "tus",
  "sus",
  "no",
  "si",
  "es",
  "soy",
  "eres",
  "somos",
  "sois",
  "estoy",
  "estamos",
  "estais",
  "estan",
  "estar",
  "tengo",
  "tienes",
  "tiene",
  "tenemos",
  "teneis",
  "tienen",
]);

/**
 * Filtra stop words de un arreglo de tokens
 */
export function filtrarStopWords(tokens: string[]): string[] {
  return tokens.filter((token) => !STOP_WORDS_ES.has(token));
}
