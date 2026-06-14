import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'services/legal_data_service.dart';
import 'services/evidence_service.dart';
import 'models/legal_models.dart';

void main() => runApp(const DefensaExpressApp());

class DefensaExpressApp extends StatelessWidget {
  const DefensaExpressApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Defensa Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFFC8A84B),
      ),
      home: const MainScreen(),
    );
  }
}

// ============================================================================
// MODELO PARA TARJETA DE RESULTADO FORMATEADA (Plain Language)
// ============================================================================

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

  /// Factory para convertir PilarFundamental a ResultadoFormateado
  factory ResultadoFormateado.fromPilarFundamental(PilarFundamental pilar) {
    return ResultadoFormateado(
      tipoDocumento: 'PRINCIPIO',
      colorAlerta: const Color(0xFF4CAF50), // Verde para principios
      icono: '⭐',
      titulo: pilar.concepto.toUpperCase(),
      accionInmediata: pilar.descripcion,
      baseLegal: 'Res. Min. N° 952-2018-IN',
      detalles: [],
      objetoOriginal: pilar,
    );
  }
}

// ============================================================================
// FUNCIONES AUXILIARES DE TRADUCCIÓN A PLAIN LANGUAGE
// ============================================================================

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

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final LegalDataService _legalDataService = LegalDataService();
  final EvidenceService _evidenceService = EvidenceService();
  
  List<ResultadoFormateado> _searchResults = [];
  bool _showResults = false;
  bool _isRecording = false;
  bool _isLoadingResults = false;
  late AnimationController _recordingAnimController;
  late Animation<double> _recordingPulseAnimation;

  final List<Map<String, String>> _quickButtons = [
    {'emoji': '🏠', 'label': 'Policía\nquiere\nentrar', 'query': 'policía'},
    {'emoji': '📱', 'label': 'Revisar\ncelular', 'query': 'derechos'},
    {'emoji': '🆔', 'label': 'Control\nidentidad', 'query': 'policía'},
    {'emoji': '🚗', 'label': 'Infracción\ntránsito', 'query': 'tránsito'},
    {'emoji': '⚖️', 'label': 'Detención\narbitraria', 'query': 'detención'},
    {'emoji': '👥', 'label': 'Derecho\nprotesta', 'query': 'derechos'},
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeLegalData();
    
    // Animación para pulso de grabación
    _recordingAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _recordingPulseAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _recordingAnimController, curve: Curves.easeInOut));
  }

  /// Carga la base de datos legal al iniciar la app
  Future<void> _initializeLegalData() async {
    try {
      await _legalDataService.cargarDatos();
    } catch (e) {
      print('❌ Error cargando datos legales: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando base legal: $e')),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    await Future.wait([
      Permission.microphone.request(),
      Permission.camera.request(),
      Permission.storage.request(),
    ]);
  }

  /// BÚSQUEDA MEJORADA CON RESULTADOS FORMATEADOS
  void _search(String query) {
    if (query.isEmpty) {
      setState(() => _showResults = false);
      return;
    }

    setState(() => _isLoadingResults = true);

    Future.microtask(() async {
      try {
        final resultadosBusqueda = _legalDataService.buscar(query);
        
        // Convertir cada resultado a ResultadoFormateado
        final resultados = <ResultadoFormateado>[];
        
        for (var r in resultadosBusqueda) {
          final res = r.resultado;
          
          try {
            if (res is Infraccion) {
              resultados.add(ResultadoFormateado.fromInfraccion(res));
            } else if (res is DerechoFundamental) {
              resultados.add(ResultadoFormateado.fromDerechoFundamental(res));
            } else if (res is EscenarioProcesal) {
              resultados.add(ResultadoFormateado.fromEscenarioProcesal(res));
            } else if (res is PilarFundamental) {
              resultados.add(ResultadoFormateado.fromPilarFundamental(res));
            } else if (res is GlosarioTermino) {
              resultados.add(ResultadoFormateado.fromGlosario(res));
            }
          } catch (e) {
            print('⚠️ Error procesando resultado: $e');
          }
        }

        if (mounted) {
          setState(() {
            _searchResults = resultados;
            _showResults = true;
            _isLoadingResults = false;
          });
        }
      } catch (e) {
        print('❌ Error en búsqueda: $e');
        if (mounted) {
          setState(() {
            _showResults = true;
            _isLoadingResults = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ No encontramos resultados. Intenta con: "policía", "derechos", "tránsito"'),
              backgroundColor: Colors.orange[700],
            ),
          );
        }
      }
    });
  }

  Future<void> _toggleRecording() async {
    setState(() => _isRecording = !_isRecording);
    
    if (_isRecording) {
      final audioStarted = await _evidenceService.startAudioRecording(
        onError: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $msg'), backgroundColor: Colors.red),
          );
        },
      );
      
      if (audioStarted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔴 GRABACIÓN ACTIVA - Tu evidencia se protege'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _isRecording = false);
      }
    } else {
      final audioPath = await _evidenceService.stopAudioRecording();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            audioPath != null 
              ? '✅ Grabación guardada: ${audioPath.split('/').last}'
              : '⚠️ Intenta grabación nuevamente',
          ),
          backgroundColor: audioPath != null ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('DEFENSA EXPRESS'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: _isRecording 
            ? Colors.red.withOpacity(0.1)
            : Colors.transparent,
        // Barra superior sutilmente roja cuando está grabando
        flexibleSpace: _isRecording
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.red.withOpacity(0.15),
                      Colors.red.withOpacity(0.05),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_showResults) ...[
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.shield, size: 60, color: Color(0xFFC8A84B)),
                      SizedBox(height: 12),
                      Text(
                        'DEFENSA EXPRESS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '🛡️  Tus derechos, siempre contigo',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // BARRA DE BÚSQUEDA
              TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Busca rápido: policía, derechos, tránsito...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFC8A84B)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFFC8A84B), size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFC8A84B), width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 20),
              
              if (!_showResults) ...[
                // BOTONES RÁPIDOS (Cuando no hay búsqueda)
                const Text(
                  'ACCESO RÁPIDO A TUS DERECHOS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _quickButtons
                      .map((btn) => InkWell(
                            onTap: () {
                              _searchController.text = btn['query']!;
                              _search(btn['query']!);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFC8A84B),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xFF1A1A1A),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(btn['emoji']!, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(height: 6),
                                  Text(
                                    btn['label']!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white70,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ] else ...[
                // RESULTADOS FORMATEADOS
                if (_isLoadingResults)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFFC8A84B)),
                  )
                else if (_searchResults.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 1),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.orange.withOpacity(0.05),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '⚠️ NO ENCONTRAMOS RESULTADOS',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Intenta con palabras clave: "policía", "derechos", "tránsito", "detención"',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'RESULTADOS',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8A84B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _searchResults.length.toString(),
                              style: const TextStyle(
                                color: Color(0xFFC8A84B),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: _searchResults
                            .map((resultado) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildResultadoCard(resultado),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _isRecording ? _recordingPulseAnimation : const AlwaysStoppedAnimation(1.0),
        child: FloatingActionButton(
          backgroundColor: _isRecording ? Colors.red : const Color(0xFFC8A84B),
          onPressed: _toggleRecording,
          tooltip: _isRecording ? 'Detener grabación' : 'Iniciar grabación de evidencia',
          child: Text(
            _isRecording ? '⏹' : '⏺',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  /// WIDGET PARA TARJETA DE RESULTADO CON JERARQUÍA VISUAL
  Widget _buildResultadoCard(ResultadoFormateado resultado) {
    return InkWell(
      onTap: () {
        // Acción al tocar: mostrar completo en diálogo
        _mostrarResultadoCompleto(resultado);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: resultado.colorAlerta.withOpacity(0.5),
            width: 2,
          ),
          color: resultado.colorAlerta.withOpacity(0.08),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1️⃣ ENCABEZADO: Tipo de documento + Icono
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  resultado.icono,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resultado.tipoDocumento,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: resultado.colorAlerta,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 2️⃣ TÍTULO GRANDE: "¿Qué está pasando?"
            Text(
              resultado.titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            
            // 3️⃣ ACCIÓN INMEDIATA: "¿Qué hago AHORA?" (Resaltado)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: resultado.colorAlerta.withOpacity(0.12),
                border: Border.all(
                  color: resultado.colorAlerta.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                resultado.accionInmediata,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: resultado.colorAlerta,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // 4️⃣ VIÑETAS ADICIONALES (máximo 3 para mantener limpieza)
            if (resultado.detalles.isNotEmpty)
              ...resultado.detalles.take(3).map((detalle) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      detalle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  )),
            
            const SizedBox(height: 8),
            
            // 5️⃣ BASE LEGAL (Pequeño, abajo)
            Text(
              '📌 ${resultado.baseLegal}',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// DIÁLOGO PARA VER RESULTADO COMPLETO
  void _mostrarResultadoCompleto(ResultadoFormateado resultado) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Encabezado
                Row(
                  children: [
                    Text(
                      resultado.icono,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        resultado.tipoDocumento,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: resultado.colorAlerta,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Título
                Text(
                  resultado.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Acción inmediata
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: resultado.colorAlerta.withOpacity(0.15),
                    border: Border.all(color: resultado.colorAlerta.withOpacity(0.4)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    resultado.accionInmediata,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: resultado.colorAlerta,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Todos los detalles
                ...resultado.detalles.map((detalle) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        detalle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    )),
                
                const SizedBox(height: 16),
                
                // Base legal
                Text(
                  '📌 Base Legal: ${resultado.baseLegal}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botón cerrar
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'CERRAR',
                      style: TextStyle(color: Color(0xFFC8A84B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _recordingAnimController.dispose();
    super.dispose();
  }
}
