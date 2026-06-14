/**
 * EJEMPLO DE USO: LegalDataService
 * Demuestra cómo usar el servicio de búsqueda legal
 *
 * Para ejecutar:
 * $ npx ts-node ejemplos/uso-basico.ts
 */

import { LegalDataService } from "../src/services/LegalDataService";

async function ejemploUsoBasico() {
  console.log("╔════════════════════════════════════════╗");
  console.log("║  DEFENSA EXPRESS - Motor de Búsqueda   ║");
  console.log("║        (Ejemplo de Uso - TypeScript)    ║");
  console.log("╚════════════════════════════════════════╝\n");

  // Instanciar el servicio
  const servicio = new LegalDataService("Json Shit");

  try {
    // 1. Cargar datos
    console.log("⏳ Cargando base de datos legal...");
    await servicio.cargarDatos();
    console.log("✓ Base de datos cargada exitosamente\n");

    // 2. Mostrar estadísticas
    const stats = servicio.obtenerEstadisticas();
    console.log("📊 Estadísticas de carga:");
    console.log(`   - Derechos Fundamentales: ${stats.totalDerechos}`);
    console.log(`   - Escenarios Procesales: ${stats.totalEscenarios}`);
    console.log(`   - Infracciones de Tránsito: ${stats.totalInfracciones}`);
    console.log(`   - Términos de Glosario: ${stats.totalGlosario}\n`);

    // 3. Ejemplos de búsqueda
    const queries = [
      "policia quiere entrar a mi casa",
      "multa de velocidad",
      "detencion arbitraria",
      "celular privado",
    ];

    for (const query of queries) {
      console.log(`\n🔍 Búsqueda: "${query}"`);
      console.log("─".repeat(60));

      const resultados = servicio.buscar(query);

      if (resultados.length === 0) {
        console.log("   (Sin resultados)");
      } else {
        // Mostrar top 3 resultados
        resultados.slice(0, 3).forEach((resultado, idx) => {
          console.log(
            `\n   ${idx + 1}. [${resultado.documento_tipo}] - Relevancia: ${resultado.relevancia}%`
          );

          // Mostrar tipo de resultado
          if ("title" in resultado.resultado) {
            console.log(`      Título: ${(resultado.resultado as any).title}`);
          } else if ("scenario" in resultado.resultado) {
            console.log(
              `      Escenario: ${(resultado.resultado as any).scenario}`
            );
          } else if ("codigo" in resultado.resultado) {
            console.log(`      Código: ${(resultado.resultado as any).codigo}`);
          } else if ("termino" in resultado.resultado) {
            console.log(`      Término: ${(resultado.resultado as any).termino}`);
          }

          // Mostrar coincidencias
          if (resultado.coincidencias.length > 0) {
            console.log(`      Coincidencias: ${resultado.coincidencias[0]}`);
          }
        });
      }
    }

    // 4. Búsqueda por código específico
    console.log("\n\n🔎 Búsqueda específica por código: G.31");
    console.log("─".repeat(60));
    const infraccion = servicio.obtenerInfraccionPorCodigo("G.31");
    if (infraccion) {
      console.log(`   Descripción: ${infraccion.descripcion}`);
      console.log(`   Gravedad: ${infraccion.gravedad}`);
      console.log(`   Puntos: ${infraccion.puntos}`);
      console.log(`   Multa: ${infraccion.sancion_monto}`);
    }

    // 5. Búsqueda de derecho por ID
    console.log("\n\n⚖️  Búsqueda de Derecho: inviolabilidad_domicilio");
    console.log("─".repeat(60));
    const derecho = servicio.obtenerDerechoPorId("inviolabilidad_domicilio");
    if (derecho) {
      console.log(`   Título: ${derecho.title}`);
      console.log(`   Base Legal: ${derecho.legal_basis}`);
      console.log(`   Acción Inmediata: ${derecho.immediate_action.substring(0, 100)}...`);
    }

    console.log("\n\n✓ Ejemplo completado exitosamente");
  } catch (error) {
    console.error("✗ Error:", error);
    process.exit(1);
  }
}

// Ejecutar ejemplo
ejemploUsoBasico();
