import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';

/// **Session de Grabación de Audio - Aislamiento de Estado**
class _AudioRecordingSession {
  String? filePath;
  DateTime? startTime;
  
  Duration get duration {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }
  
  void reset() {
    filePath = null;
    startTime = null;
  }
}

/// **Session de Grabación de Video - Aislamiento de Estado**
class _VideoRecordingSession {
  String? filePath;
  DateTime? startTime;
  CameraController? controller;
  
  Duration get duration {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }
  
  void reset() {
    filePath = null;
    startTime = null;
    controller = null;
  }
}

/// Servicio de Grabación de Evidencia - Privacy-First
/// 
/// **Arquitectura:**
/// - Singleton para control centralizado de hardware
/// - Sessions independientes para audio y video (NO estado compartido)
/// - Privacy-First: almacenamiento local, sin telemetría
/// - Implementación real: package:record + package:camera
/// - Limpieza robusta de recursos (dispose/stop)
///
/// **Características:**
/// - Grabación de audio en segundo plano (AAC 128kbps, m4a)
/// - Video en "Modo Discreto": grabación sin preview pesado
/// - Almacenamiento en carpeta privada (sandbox del SO)
/// - Borrado seguro DoD 5220.22-M con 3 pasadas
/// - Permisos verificados antes de grabar
/// - Feedback háptico (vibración)
/// - Banner legal informativo

// ============================================================================
// TOP-LEVEL FUNCTIONS FOR ISOLATE EXECUTION (DoD 5220.22-M)
// ============================================================================

/// Modelo de datos para pasar parámetros al Isolate de borrado seguro
class _SecureDeleteParams {
  final String filePath;
  
  _SecureDeleteParams(this.filePath);
}

/// Sobrescribe un archivo con un byte específico (0x00 o 0xFF) - para Isolate
Future<void> _overwriteFileInChunksIsolate(
  File file,
  int byteValue,
  int bufferSize,
) async {
  final fileSize = await file.length();
  final buffer = List<int>.filled(bufferSize, byteValue);
  final raf = await file.open(mode: FileMode.write);

  try {
    int bytesWritten = 0;
    while (bytesWritten < fileSize) {
      final remainingBytes = fileSize - bytesWritten;
      final chunkSize = remainingBytes < bufferSize ? remainingBytes : bufferSize;
      await raf.writeFrom(buffer, 0, chunkSize);
      bytesWritten += chunkSize;
    }
    await raf.flush();
  } finally {
    await raf.close();
  }
}

/// Sobrescribe un archivo con bytes aleatorios criptográficos - para Isolate
Future<void> _overwriteFileWithRandomBytesIsolate(
  File file,
  int bufferSize,
) async {
  final fileSize = await file.length();
  final random = Random.secure();
  final raf = await file.open(mode: FileMode.write);

  try {
    int bytesWritten = 0;
    while (bytesWritten < fileSize) {
      final remainingBytes = fileSize - bytesWritten;
      final chunkSize = remainingBytes < bufferSize ? remainingBytes : bufferSize;
      final randomBuffer = List<int>.generate(
        chunkSize,
        (_) => random.nextInt(256),
      );
      await raf.writeFrom(randomBuffer);
      bytesWritten += chunkSize;
    }
    await raf.flush();
  } finally {
    await raf.close();
  }
}

/// Genera nombre de archivo aleatorio para ofuscación - para Isolate
String _generateRandomFileNameIsolate() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  final buffer = StringBuffer();
  for (int i = 0; i < 12; i++) {
    buffer.write(chars[random.nextInt(chars.length)]);
  }
  return '${buffer.toString()}.tmp';
}

/// **FUNCIÓN PRINCIPAL DE BORRADO SEGURO - Ejecutada en Isolate**
/// 
/// Esta función orquesta todas las 3 pasadas DoD 5220.22-M y se ejecuta
/// completamente en un Isolate separado del Main Thread.
/// 
/// **Parámetros:** Ruta del archivo (String) - serializable
/// **Retorna:** true si se eliminó exitosamente, false si falló
/// 
/// **Ventaja de Isolate:** Las operaciones de I/O pesadas no bloquean la UI
Future<bool> _performSecureDeleteInIsolate(String filePath) async {
  try {
    final file = File(filePath);
    
    if (!await file.exists()) {
      if (kDebugMode) { print('⚠️ Archivo no encontrado: $filePath'); }
      return false;
    }

    final fileSize = await file.length();
    const maxSafeSize = 2 * 1024 * 1024 * 1024; // 2 GB
    
    if (fileSize > maxSafeSize) {
      if (kDebugMode) { print('⚠️ Archivo demasiado grande ($fileSize bytes).'); }
      return false;
    }

    const bufferSize = 64 * 1024;

    // Pasada 1: Sobrescribir con ceros
    if (kDebugMode) { print('🔄 Pasada 1/3: Sobrescribiendo con ceros (0x00)...'); }
    await _overwriteFileInChunksIsolate(file, 0x00, bufferSize);

    // Pasada 2: Sobrescribir con unos
    if (kDebugMode) { print('🔄 Pasada 2/3: Sobrescribiendo con unos (0xFF)...'); }
    await _overwriteFileInChunksIsolate(file, 0xFF, bufferSize);

    // Pasada 3: Sobrescribir con bytes aleatorios
    if (kDebugMode) { print('🔄 Pasada 3/3: Sobrescribiendo con ruido criptográfico...'); }
    await _overwriteFileWithRandomBytesIsolate(file, bufferSize);

    // Ofuscación: Renombrar
    if (kDebugMode) { print('🔄 Ofuscando metadatos: renombrando archivo...'); }
    final obfuscatedName = _generateRandomFileNameIsolate();
    final renamedFile = File('${file.parent.path}/$obfuscatedName');

    try {
      await file.rename(renamedFile.path);
    } catch (e) {
      if (kDebugMode) { print('⚠️ Renombrado fallido, continuando: $e'); }
    }

    // Eliminación final
    final fileToDelete = await renamedFile.exists() ? renamedFile : file;
    await fileToDelete.delete();

    if (kDebugMode) { print('✅ Archivo eliminado de forma segura (en Isolate): $filePath'); }
    return true;
  } catch (e) {
    if (kDebugMode) { print('❌ Error eliminando archivo en Isolate: $e'); }
    return false;
  }
}

class EvidenceService {
  static final EvidenceService _instance = EvidenceService._internal();

  factory EvidenceService() {
    return _instance;
  }

  EvidenceService._internal();

  // ============================================================================
  // HARDWARE: Recorders y Controladores
  // ============================================================================
  
  /// Grabador de audio real (package:record)
  late final AudioRecorder _audioRecorder = AudioRecorder();
  
  /// Controlador de cámara (puede ser null si no se inicializa)
  CameraController? _cameraController;
  
  /// Flag para prevenir inicialización múltiple de cámara
  bool _cameraInitializing = false;

  // ============================================================================
  // ESTADO: Sessions Independientes (FIX: evita corrupción)
  // ============================================================================
  
  /// Session de audio (estado AISLADO)
  final _audioSession = _AudioRecordingSession();
  
  /// Session de video (estado AISLADO)
  final _videoSession = _VideoRecordingSession();

  // ============================================================================
  // GETTERS: Acceso Público al Estado
  // ============================================================================

  bool get isRecordingAudio => _audioSession.filePath != null;
  bool get isRecordingVideo => _videoSession.filePath != null;
  bool get isRecording => isRecordingAudio || isRecordingVideo;
  
  /// Retorna el tiempo de la session que está activa (audio o video)
  Duration get recordingDuration {
    if (isRecordingAudio) return _audioSession.duration;
    if (isRecordingVideo) return _videoSession.duration;
    return Duration.zero;
  }

  /// Solicita permisos de micrófono, cámara y almacenamiento
  Future<bool> requestPermissions() async {
    try {
      final statuses = await [
        Permission.microphone,
        Permission.camera,
      ].request();

      final allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        if (kDebugMode) { print('❌ Permisos denegados: ${statuses.toString()}'); }
        return false;
      }

      if (kDebugMode) { print('✅ Todos los permisos concedidos'); }
      return true;
    } catch (e) {
      if (kDebugMode) { print('❌ Error solicitando permisos: $e'); }
      return false;
    }
  }

  /// Obtiene la carpeta privada de la app (sandboxed, no accesible públicamente)
  Future<Directory> _getEvidenceDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final evidenceDir = Directory('${appDir.path}/DefensaExpress/Evidence');

    if (!await evidenceDir.exists()) {
      await evidenceDir.create(recursive: true);
    }

    return evidenceDir;
  }

  /// Genera nombre de archivo con timestamp (formato: DEF_EXPR_YYYY-MM-DD_HH-mm-ss)
  String _generateFileName(String extension) {
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    return 'DEF_EXPR_${timestamp}$extension';
  }

  // ============================================================================
  // GRABACIÓN DE AUDIO - IMPLEMENTACIÓN REAL (package:record)
  // ============================================================================

  /// Verifica permiso de micrófono y solicita si es necesario
  Future<bool> _verifyAudioPermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return true;
  }

  /// Inicia grabación de audio en segundo plano
  /// 
  /// **Configuración:**
  /// - Formato: m4a (AAC-LC)
  /// - Sample rate: 44.1 kHz
  /// - Canales: 1 (mono)
  /// - Bitrate: 128 kbps (óptimo para almacenamiento)
  /// 
  /// **Almacenamiento:**
  /// - Ruta privada: `/data/user/*/DefensaExpress/Evidence/`
  /// - NO accesible públicamente (sandbox del SO)
  Future<bool> startAudioRecording({
    Function(String message)? onError,
  }) async {
    try {
      // Guard: Evitar grabación múltiple simultánea
      if (isRecordingAudio) {
        onError?.call('Ya hay grabación de audio en progreso');
        return false;
      }

      // Verificar permisos
      final hasPermission = await _verifyAudioPermission();
      if (!hasPermission) {
        onError?.call('Permiso de micrófono denegado');
        return false;
      }

      // Crear archivo de destino en carpeta privada
      final evidenceDir = await _getEvidenceDirectory();
      final audioPath = '${evidenceDir.path}/${_generateFileName('.m4a')}';

      // Iniciar grabación REAL con package:record
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,      // Codec: AAC-LC
          sampleRate: 44100,                 // Tasa de muestreo: 44.1 kHz
          numChannels: 1,                    // Mono (1 canal)
          bitRate: 128000,                   // Bitrate: 128 kbps
        ),
        path: audioPath,
      );

      // Actualizar estado de la session
      _audioSession.filePath = audioPath;
      _audioSession.startTime = DateTime.now();

      // Feedback háptico (sin mirar pantalla)
      await _hapticFeedback(duration: 100);

      if (kDebugMode) { print('✅ Grabación de audio iniciada: $audioPath'); }
      return true;
    } catch (e) {
      onError?.call('Error iniciando grabación de audio: $e');
      if (kDebugMode) { print('❌ Error iniciando audio: $e'); }
      return false;
    }
  }

  /// Detiene grabación de audio y retorna la ruta del archivo
  Future<String?> stopAudioRecording() async {
    try {
      if (!isRecordingAudio) {
        return null;
      }

      // Detener grabador REAL
      final path = await _audioRecorder.stop();
      
      final duration = _audioSession.duration;
      if (kDebugMode) { print('✅ Grabación de audio finalizada: $path (${duration.inSeconds}s)'); }

      // Feedback háptico
      await _hapticFeedback(duration: 150);

      // Guardar ruta antes de limpiar estado
      final result = _audioSession.filePath;
      _audioSession.reset();  // Limpiar estado

      return result;
    } catch (e) {
      if (kDebugMode) { print('❌ Error deteniendo audio: $e'); }
      return null;
    }
  }

  // ============================================================================
  // GRABACIÓN DE VIDEO - IMPLEMENTACIÓN REAL (package:camera)
  // ============================================================================

  /// Verifica permiso de cámara y solicita si es necesario
  Future<bool> _verifyCameraPermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return true;
  }

  /// Obtiene lista de cámaras disponibles en el dispositivo
  /// Preferencia: Cámara trasera (principal)
  Future<CameraDescription?> _getBackCamera() async {
    try {
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        if (kDebugMode) { print('❌ No hay cámaras disponibles en el dispositivo'); }
        return null;
      }

      // Buscar cámara trasera (frontal como fallback)
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,  // Fallback: primera cámara disponible
      );

      return backCamera;
    } catch (e) {
      if (kDebugMode) { print('❌ Error obteniendo cámaras: $e'); }
      return null;
    }
  }

  /// Inicia grabación de video en "Modo Discreto"
  /// 
  /// **Características:**
  /// - Cámara trasera por defecto
  /// - Resolución media/alta
  /// - Audio incluido en video
  /// - Sin preview pesado en UI (discreto)
  /// - Almacenamiento privado: mp4
  /// 
  /// **Flujo:**
  /// 1. Verificar permisos de cámara
  /// 2. Obtener descripción de cámara trasera
  /// 3. Inicializar CameraController
  /// 4. Iniciar grabación de video
  /// 5. Guardar ruta en session aislada
  Future<bool> startDiscreteVideoRecording({
    Function(String message)? onError,
  }) async {
    try {
      // Guard: Evitar grabación múltiple simultánea
      if (isRecordingVideo) {
        onError?.call('Ya hay grabación de video en progreso');
        return false;
      }

      // Verificar permisos
      final hasPermission = await _verifyCameraPermission();
      if (!hasPermission) {
        onError?.call('Permiso de cámara denegado');
        return false;
      }

      // Guard: Evitar inicializaciones múltiples simultáneas
      if (_cameraInitializing) {
        onError?.call('Inicialización de cámara en progreso');
        return false;
      }

      _cameraInitializing = true;

      // Obtener descripción de cámara (trasera preferente)
      final cameraDesc = await _getBackCamera();
      if (cameraDesc == null) {
        _cameraInitializing = false;
        onError?.call('No hay cámaras disponibles');
        return false;
      }

      // Limpiar controlador anterior si existe
      await _cameraController?.dispose();

      // **INICIALIZAR CONTROLADOR DE CÁMARA REAL**
      _cameraController = CameraController(
        cameraDesc,
        ResolutionPreset.high,  // Resolución media/alta (720p-1080p)
        enableAudio: true,       // ✅ Audio incluido en video
      );

      // Inicializar de forma sincrónica
      await _cameraController!.initialize();

      // Crear archivo de destino en carpeta privada
      final evidenceDir = await _getEvidenceDirectory();
      final videoPath = '${evidenceDir.path}/${_generateFileName('.mp4')}';

      // **INICIAR GRABACIÓN DE VIDEO REAL**
      await _cameraController!.startVideoRecording();

      // Actualizar estado de la session
      _videoSession.filePath = videoPath;
      _videoSession.startTime = DateTime.now();
      _videoSession.controller = _cameraController;

      _cameraInitializing = false;

      // Feedback háptico (doble para video - crítico)
      await _hapticFeedback(duration: 100);
      await Future.delayed(const Duration(milliseconds: 150));
      await _hapticFeedback(duration: 100);

      if (kDebugMode) { print('✅ Grabación de video iniciada (Modo Discreto): $videoPath'); }
      return true;
    } catch (e) {
      _cameraInitializing = false;
      onError?.call('Error iniciando grabación de video: $e');
      if (kDebugMode) { print('❌ Error iniciando video: $e'); }
      return false;
    }
  }

  /// Detiene grabación de video y retorna la ruta del archivo
  /// 
  /// **Limpieza de Recursos:**
  /// 1. Detener grabación de video
  /// 2. Guardar archivo XFile a ruta privada
  /// 3. Descartar controlador de cámara (libera cámara y sensores)
  Future<String?> stopDiscreteVideoRecording() async {
    try {
      if (!isRecordingVideo) {
        return null;
      }

      if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
        if (kDebugMode) { print('⚠️ Cámara no está grabando'); }
        return null;
      }

      // Detener grabación REAL
      final videoFile = await _cameraController!.stopVideoRecording();

      final duration = _videoSession.duration;
      if (kDebugMode) { print('✅ Grabación de video finalizada: ${videoFile.path} (${duration.inSeconds}s)'); }

      // Guardar ruta final en carpeta privada (si no está ya ahí)
      final evidenceDir = await _getEvidenceDirectory();
      final finalPath = '${evidenceDir.path}/${_generateFileName('.mp4')}';
      
      // Mover archivo a carpeta privada si es necesario
      final savedFile = await videoFile.saveTo(finalPath);
      if (kDebugMode) { print('✅ Video guardado en: $finalPath'); }

      // Feedback háptico
      await _hapticFeedback(duration: 150);

      // Limpiar recursos ANTES de resetear estado
      await _cameraController?.dispose();
      _cameraController = null;

      // Guardar ruta antes de limpiar estado
      _videoSession.filePath = finalPath;
      final result = _videoSession.filePath;
      _videoSession.reset();  // Limpiar estado

      return result;
    } catch (e) {
      if (kDebugMode) { print('❌ Error deteniendo video: $e'); }
      
      // LIMPIEZA FORZADA en caso de error
      try {
        await _cameraController?.dispose();
        _cameraController = null;
      } catch (disposeError) {
        if (kDebugMode) { print('⚠️ Error en cleanup de cámara: $disposeError'); }
      }
      
      _videoSession.reset();
      return null;
    }
  }

  // ============================================================================
  // GRABACIÓN COMBINADA (AUDIO + VIDEO)
  // ============================================================================

  /// Inicia grabación simultánea de audio y video
  /// 
  /// **Estrategia:**
  /// 1. Iniciar audio
  /// 2. Iniciar video
  /// 3. Si video falla, continuar con audio (graceful degradation)
  Future<bool> startFullEvidenceRecording({
    Function(String message)? onError,
  }) async {
    try {
      // Iniciar audio primero (más rápido)
      final audioStarted = await startAudioRecording(onError: onError);
      if (!audioStarted) {
        return false;
      }

      // Iniciar video (puede fallar, pero audio sigue funcionando)
      final videoStarted = await startDiscreteVideoRecording(onError: onError);
      if (!videoStarted) {
        if (kDebugMode) { print('⚠️ Video falló, continuando con audio solamente'); }
        // No retornar false, ya tenemos audio
      }

      if (kDebugMode) { print('✅ Grabación completa (Audio + Video) iniciada'); }
      return true;
    } catch (e) {
      onError?.call('Error iniciando grabación completa: $e');
      if (kDebugMode) { print('❌ Error: $e'); }
      return false;
    }
  }

  /// Detiene todas las grabaciones activas
  /// 
  /// **Retorna:**
  /// ```dart
  /// {
  ///   'audio': '/data/.../DEF_EXPR_2026-06-11_14-30-45.m4a',
  ///   'video': '/data/.../DEF_EXPR_2026-06-11_14-30-45.mp4',
  /// }
  /// ```
  Future<Map<String, String?>> stopAllRecordings() async {
    try {
      final results = <String, String?>{
        'audio': await stopAudioRecording(),
        'video': await stopDiscreteVideoRecording(),
      };

      if (kDebugMode) { print('✅ Todas las grabaciones detenidas'); }
      return results;
    } catch (e) {
      if (kDebugMode) { print('❌ Error deteniendo grabaciones: $e'); }
      return {'audio': null, 'video': null};
    }
  }

  // ============================================================================
  // GESTIÓN DE ARCHIVOS
  // ============================================================================

  /// Obtiene lista de archivos de evidencia en carpeta privada
  Future<List<File>> listEvidenceFiles() async {
    try {
      final evidenceDir = await _getEvidenceDirectory();
      final files = await evidenceDir
          .list()
          .where((e) => e is File)
          .cast<File>()
          .where(
              (f) => f.path.endsWith('.m4a') || f.path.endsWith('.mp4'))
          .toList();

      return files;
    } catch (e) {
      if (kDebugMode) { print('❌ Error listando archivos: $e'); }
      return [];
    }
  }

  /// Obtiene información metadata de un archivo de evidencia
  Future<Map<String, dynamic>> getEvidenceFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {};
      }

      final stat = await file.stat();
      final fileName = filePath.split('/').last;
      final fileSize = stat.size;
      final isAudio = filePath.endsWith('.m4a');
      final isVideo = filePath.endsWith('.mp4');

      return {
        'name': fileName,
        'path': filePath,
        'size': fileSize,
        'sizeFormatted': _formatFileSize(fileSize),
        'type': isAudio ? 'audio' : isVideo ? 'video' : 'unknown',
        'created': stat.modified,
      };
    } catch (e) {
      if (kDebugMode) { print('❌ Error obteniendo info del archivo: $e'); }
      return {};
    }
  }



  // ============================================================================
  // LIMPIEZA DE RECURSOS (Cleanup & Dispose)
  // ============================================================================

  /// **CRÍTICO:** Cleanup de todos los recursos de hardware
  /// 
  /// Debe llamarse cuando:
  /// - La app va a background (onPaused)
  /// - La app se cierra
  /// - Cambio de escena que no necesita grabación
  /// 
  /// **Limpia:**
  /// 1. Detiene grabaciones activas
  /// 2. Desecha controlador de cámara (libera sensores)
  /// 3. Resetea estado de sessions
  /// 
  /// **Importancia:** 
  /// Sin limpieza, el hardware queda bloqueado y drena batería
  Future<void> dispose() async {
    try {
      if (kDebugMode) { print('🧹 Limpiando recursos de EvidenceService...'); }

      // Detener grabaciones si están activas
      if (isRecordingAudio) {
        await stopAudioRecording();
      }

      if (isRecordingVideo) {
        await stopDiscreteVideoRecording();
      }

      // Descartar controlador de cámara (CRÍTICO)
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
        if (kDebugMode) { print('✅ Cámara desechada (recursos liberados)'); }
      }

      // Limpiar caché de imágenes en memoria (DoD 5220.22-M: privacy en RAM)
      try {
        final imageCache = PaintingBinding.instance.imageCache;
        imageCache.clearLiveImages();
        imageCache.clear();
        if (kDebugMode) { print('✅ ImageCache limpiado (memoria segura)'); }
      } catch (e) {
        if (kDebugMode) { print('⚠️ No se pudo limpiar ImageCache: $e'); }
      }

      // Resetear sessions
      _audioSession.reset();
      _videoSession.reset();

      if (kDebugMode) { print('✅ Cleanup completado'); }
    } catch (e) {
      if (kDebugMode) { print('⚠️ Error en cleanup: $e'); }
    }
  }

  // ============================================================================
  // METADATA LEGAL
  // ============================================================================

  /// Banner legal informativo que debe mostrarse antes de grabar
  static String getLegalBanner() {
    return '''
╔════════════════════════════════════════════════════════════════╗
║                    🛡️  GRABACIÓN DE EVIDENCIA                 ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  Fundamento Legal:                                           ║
║  El ciudadano tiene derecho a grabar las intervenciones      ║
║  policiales conforme al principio de TRANSPARENCIA Y         ║
║  CONTROL DE LA FUNCIÓN PÚBLICA.                              ║
║                                                                ║
║  Base Normativa:                                             ║
║  • Artículo 2.6 - Constitución Política del Perú              ║
║    "Derecho a la información"                                ║
║                                                                ║
║  • Artículo 43 - Ley Acceso a Información Pública Nº 27806   ║
║    "Transparencia en actos administrativos"                  ║
║                                                                ║
║  • Ley Orgánica PNP Nº 24949                                  ║
║    "Los agentes deben actuar conforme a ley"                 ║
║                                                                ║
║  Privacidad de Datos:                                        ║
║  ✓ Archivos almacenados LOCALMENTE en el dispositivo         ║
║  ✓ NO se envía a servidores externos                         ║
║  ✓ NO hay sincronización con la nube                         ║
║  ✓ Carpeta privada: /data/user/*/DefensaExpress/Evidence    ║
║  ✓ Eliminación segura: DoD 5220.22-M (3 pasadas)             ║
║                                                                ║
║  Responsabilidad:                                            ║
║  El usuario es responsable del uso conforme a ley. Esta     ║
║  herramienta es únicamente para defensa de derechos.         ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
''';
  }

  // ============================================================================
  // PRIVACIDAD Y SEGURIDAD - HELPERS
  // ============================================================================

  /// Feedback háptico (vibración) para confirmación sin mirar pantalla
  Future<void> _hapticFeedback({int duration = 100}) async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: duration);
      }
    } catch (e) {
      if (kDebugMode) { print('⚠️ Vibración no disponible: $e'); }
    }
  }

  /// Formatea tamaño de archivo en unidades legibles (B, KB, MB, GB)
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // ============================================================================
  // BORRADO SEGURO DE EVIDENCIA (DoD 5220.22-M)
  // ============================================================================

  /// Elimina un archivo de evidencia de forma segura con 3 pasadas DoD 5220.22-M
  /// 
  /// **REFACTORIZADO CON ISOLATE:** Este método ahora delega la operación
  /// pesada de I/O a un Isolate separado usando compute(), eliminando
  /// completamente cualquier bloqueo del Main Thread.
  /// 
  /// **Estándar:** National Security Agency (NSA)
  /// **Pasadas:**
  /// 1. Sobrescribir con 0x00 (ceros)
  /// 2. Sobrescribir con 0xFF (unos)
  /// 3. Sobrescribir con bytes aleatorios criptográficos
  /// 
  /// **Guardias:**
  /// - Max seguro: 2 GB
  /// - Buffer: 64 KB (evita OutOfMemoryError)
  /// - Ofuscación: Renombrado a string aleatorio
  /// - **Isolate:** Ejecución completamente asíncrona sin bloqueos
  /// 
  /// **Retorna:** true si se eliminó exitosamente
  Future<bool> secureDeleteEvidenceFile(File file) async {
    try {
      // Validación previa rápida en Main Thread
      if (!await file.exists()) {
        if (kDebugMode) { print('⚠️ Archivo no encontrado: ${file.path}'); }
        return false;
      }

      // Delegar TODO el trabajo pesado al Isolate
      final result = await compute(
        _performSecureDeleteInIsolate,
        file.path,  // Parámetro serializable (String)
      );

      return result;
    } catch (e) {
      if (kDebugMode) { print('❌ Error en secureDeleteEvidenceFile: $e'); }
      return false;
    }
  }

  // ============================================================================
  // DEBUG & MANTENIMIENTO
  // ============================================================================

  /// Limpia todos los archivos de evidencia (SOLO DEBUG)
  /// Guard: `kDebugMode` previene ejecución en RELEASE
  Future<void> clearAllEvidenceFiles() async {
    if (!kDebugMode) {
      if (kDebugMode) { print('⛔ clearAllEvidenceFiles() bloqueado en modo RELEASE'); }
      return;
    }

    try {
      final evidenceDir = await _getEvidenceDirectory();
      final files = await evidenceDir.list().toList();

      for (var file in files) {
        if (file is File) {
          await secureDeleteEvidenceFile(file);
        }
      }

      if (kDebugMode) { print('✅ Carpeta de evidencia limpiada (DEBUG)'); }
    } catch (e) {
      if (kDebugMode) { print('❌ Error limpiando carpeta: $e'); }
    }
  }
}
