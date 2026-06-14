import '../models/legal_models.dart';

/// Traduce descripciones de infracciones a lenguaje simple
String _traducirDescripcionInfraccion(String descripcion) {
  final map = {
    'estacionar': 'PARQUEASTE MAL',
    'velocidad': 'IBAS MÁS RÁPIDO DE LO PERMITIDO',
    'licencia': 'ERES CONDUCTOR SIN CARNET',
    'sobrepasar': 'CRUZASTE LA LÍNEA BLANCA',
    'semáforo': 'PASASTE LA LUZ ROJA',
    'cinturón': 'NO LLEVABAS CINTURÓN DE SEGURIDAD',
    'teléfono': 'USABAS CELULAR MIENTRAS MANEJABAS',
  };

  for (var key in map.keys) {
    if (descripcion.toLowerCase().contains(key)) {
      return map[key]!;
    }
  }

  return descripcion.substring(0, 60).toUpperCase();
}

/// Genera acción inmediata para una infracción
String _generarAccionTransito(Infraccion infraccion) {
  if (infraccion.gravedad == GravedadInfraccion.grave) {
    return '🚗 DI ESTO: "Entiendo. Quiero ver la multa en el sistema. Tomaré foto de mi documento."';
  }
  return '🚗 DI ESTO: "¿Cuál es la razón del control? Estoy disponible."';
}

/// Genera viñetas de detalles para infracción
List<String> _generarDetallesInfraccion(Infraccion infraccion) {
  return [
    '💰 Multa: ${infraccion.sancionMonto}',
    if (infraccion.puntos > 0) '⚠️ Puntos de infracción: ${infraccion.puntos}',
    if (infraccion.medidaPreventiva.isNotEmpty)
      '🔒 Medida: ${infraccion.medidaPreventiva}',
    '🔴 Gravedad: ${infraccion.gravedad.valor}',
  ];
}

/// Formatea acción inmediata de derechos
String _formatearAccionInmediata(String accion) {
  if (accion.isEmpty) return 'DI ESTO: "Conozco mis derechos."';
  
  if (!accion.toLowerCase().contains('di esto')) {
    return '💬 DI ESTO: "$accion"';
  }
  return accion;
}

/// Convierte rights_summary en vinetas cortas
List<String> _generarVinetasDeDerechos(String summary) {
  if (summary.isEmpty) return [];
  
  return summary
      .split('.')
      .where((s) => s.trim().isNotEmpty)
      .take(4) // Maximo 4 vinetas
      .map((s) => '• ${s.trim().substring(0, (s.length < 60 ? s.length : 60))}')
      .toList();
}

/// Formatea guión de defensa como "DI ESTO:"
String _formatearGuionDefensa(String guion) {
  if (guion.isEmpty) return 'DI ESTO: "Solicito hablar con mi abogado."';
  
  final partes = guion.split('|');
  if (partes.isNotEmpty) {
    return '💬 DI ESTO: "${partes.first.trim()}"';
  }
  
  return '💬 DI ESTO: "$guion"';
}
