import 'package:flutter/material.dart';
import 'legal_models.dart';
import '../utils/plain_language.dart';

class ResultadoFormateado {
  final String tipoDocumento; // MTC, CPP, DERECHOS, GLOSARIO, etc.
  final Color colorAlerta; // Rojo (detención), Amarillo (tránsito), Azul (derechos)
  final String icono; // Emoji para identificación visual rápida
  final String titulo; // "¿Qué está pasando?" - GRANDE
  final String accionInmediata; // "¿Qué hago AHORA?" - Resaltado con "DI ESTO:"
  final String baseLegal; // Artículo/norma - PEQUEÑO
  final List<String> detalles; // Viñetas adicionales (máx 10 palabras cada una)
  final dynamic objetoOriginal; // Para referencia interna

  ResultadoFormateado({
    required this.tipoDocumento,
    required this.colorAlerta,
    required this.icono,
    required this.titulo,
    required this.accionInmediata,
    required this.baseLegal,
    required this.detalles,
    required this.objetoOriginal,
  });

  /// Factory para convertir Infracción a ResultadoFormateado
  factory ResultadoFormateado.fromInfraccion(Infraccion infraccion) {
    final esGrave = infraccion.gravedad == GravedadInfraccion.grave ||
        infraccion.gravedad == GravedadInfraccion.muyGrave;
    
    return ResultadoFormateado(
      tipoDocumento: 'TRÁNSITO',
      colorAlerta: const Color(0xFFFFB300), // Amarillo para tránsito
      icono: '🚗',
      titulo: _traducirDescripcionInfraccion(infraccion.descripcion),
      accionInmediata: _generarAccionTransito(infraccion),
      baseLegal: 'RNT D.S. N° 016-2009-MTC | ${infraccion.codigo}',
      detalles: _generarDetallesInfraccion(infraccion),
      objetoOriginal: infraccion,
    );
  }

  /// Factory para convertir DerechoFundamental a ResultadoFormateado
  factory ResultadoFormateado.fromDerechoFundamental(DerechoFundamental derecho) {
    return ResultadoFormateado(
      tipoDocumento: 'DERECHOS',
      colorAlerta: const Color(0xFF2196F3), // Azul para derechos
      icono: '⚖️',
      titulo: derecho.title.toUpperCase(),
      accionInmediata: _formatearAccionInmediata(derecho.immediateAction),
      baseLegal: derecho.legalBasis,
      detalles: _generarVinetasDeDerechos(derecho.rightsSummary),
      objetoOriginal: derecho,
    );
  }

  /// Factory para convertir EscenarioProcesal a ResultadoFormateado
  factory ResultadoFormateado.fromEscenarioProcesal(EscenarioProcesal escenario) {
    final esDetenccion = escenario.scenario.toLowerCase().contains('detenc') ||
        escenario.scenario.toLowerCase().contains('arrest');
    
    return ResultadoFormateado(
      tipoDocumento: 'PROCEDIMIENTO',
      colorAlerta: esDetenccion 
          ? const Color(0xFFEF5350) // Rojo para detenciones
          : const Color(0xFFC8A84B), // Dorado para otros
      icono: esDetenccion ? '🚨' : '📋',
      titulo: escenario.scenario.toUpperCase(),
      accionInmediata: _formatearGuionDefensa(escenario.guionDeDefensa),
      baseLegal: 'Código Procesal Penal | ${escenario.accionLegal}',
      detalles: [
        '⚠️ LÍMITE POLICIAL: ${escenario.limitePolicial}',
        ...escenario.tags?.map((t) => '• $t').toList() ?? [],
      ],
      objetoOriginal: escenario,
    );
  }

  /// Factory para convertir GlosarioTermino a ResultadoFormateado
  factory ResultadoFormateado.fromGlosario(GlosarioTermino termino) {
    return ResultadoFormateado(
      tipoDocumento: 'DEFINICIÓN',
      colorAlerta: const Color(0xFF9C27B0), // Púrpura para glosario
      icono: '📖',
      titulo: termino.termino.toUpperCase(),
      accionInmediata: termino.definicion,
      baseLegal: 'Glosario Legal',
      detalles: [],
      objetoOriginal: termino,
    );
  }
}
