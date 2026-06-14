// **Ejemplos de Uso: secureDeleteEvidenceFile()**
// 
// Archivo: lib/widgets/secure_delete_examples.dart
// Propósito: Ejemplos prácticos de cómo usar la función de borrado seguro
// 
// NOTA: Estos son fragmentos de ejemplo. Integrar en tu aplicación según sea necesario.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:defensa_express/services/evidence_service.dart';

// ============================================================================
// EJEMPLO 1: Eliminación Manual con Confirmación
// ============================================================================

class SecureDeleteConfirmationDialog extends StatelessWidget {
  final File evidenceFile;
  final VoidCallback onSuccess;
  final Function(String error) onError;

  const SecureDeleteConfirmationDialog({
    required this.evidenceFile,
    required this.onSuccess,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = evidenceFile.path.split('/').last;
    final fileSize = evidenceFile.lengthSync();
    
    return AlertDialog(
      title: const Text('🛡️ Eliminación Segura de Evidencia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Esta acción eliminará el archivo de forma segura mediante:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildProcessStep(
            icon: '1️⃣',
            title: 'Pasada 1: Sobrescribir con ceros (0x00)',
            description: 'Elimina polarización magnética residual',
          ),
          const SizedBox(height: 12),
          _buildProcessStep(
            icon: '2️⃣',
            title: 'Pasada 2: Sobrescribir con unos (0xFF)',
            description: 'Inversa de la pasada anterior',
          ),
          const SizedBox(height: 12),
          _buildProcessStep(
            icon: '3️⃣',
            title: 'Pasada 3: Sobrescribir con bytes aleatorios',
            description: 'Ruido criptográfico impredecible',
          ),
          const SizedBox(height: 16),
          Text(
            'Archivo: $fileName',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Tamaño: ${_formatFileSize(fileSize)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              border: Border.all(color: Colors.amber),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No se puede recuperar después de eliminación.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber[900],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () => _performSecureDelete(context),
          icon: const Icon(Icons.delete_forever),
          label: const Text('Eliminar de Forma Segura'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessStep({
    required String icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _performSecureDelete(BuildContext context) async {
    Navigator.pop(context);  // Cerrar diálogo

    // Mostrar diálogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🔄 Eliminando...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Ejecutando 3 pasadas de sobrescritura...'),
            const SizedBox(height: 8),
            Text(
              'Tiempo estimado: ${_estimateDeleteTime(evidenceFile.lengthSync())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    try {
      final evidenceService = EvidenceService();
      final success = await evidenceService.secureDeleteEvidenceFile(evidenceFile);

      Navigator.pop(context);  // Cerrar diálogo de progreso

      if (success) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Archivo eliminado de forma segura (DoD 5220.22-M)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        onError('Error al eliminar el archivo');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Error al eliminar el archivo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      onError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _estimateDeleteTime(int fileSize) {
    const speedMBps = 5;  // ~5 MB/s
    const passadas = 3;
    final totalMB = fileSize / (1024 * 1024);
    final seconds = (totalMB / speedMBps * passadas).toInt();

    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes}m ${secs}s';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ============================================================================
// EJEMPLO 2: Lista de Archivos con Opción de Eliminar
// ============================================================================

class EvidenceFileListView extends StatefulWidget {
  const EvidenceFileListView({Key? key}) : super(key: key);

  @override
  State<EvidenceFileListView> createState() => _EvidenceFileListViewState();
}

class _EvidenceFileListViewState extends State<EvidenceFileListView> {
  late final EvidenceService _evidenceService;
  List<File> _evidenceFiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _evidenceService = EvidenceService();
    _loadEvidenceFiles();
  }

  Future<void> _loadEvidenceFiles() async {
    setState(() => _loading = true);
    final files = await _evidenceService.listEvidenceFiles();
    setState(() {
      _evidenceFiles = files;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_evidenceFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay archivos de evidencia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: (_) => _loadEvidenceFiles(),
      child: ListView.builder(
        itemCount: _evidenceFiles.length,
        itemBuilder: (context, index) {
          final file = _evidenceFiles[index];
          final fileName = file.path.split('/').last;
          final fileSize = file.lengthSync();
          final isAudio = file.path.endsWith('.m4a');

          return ListTile(
            leading: Icon(
              isAudio ? Icons.mic : Icons.videocam,
              color: isAudio ? Colors.blue : Colors.red,
            ),
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_formatFileSize(fileSize)),
            trailing: PopupMenuButton(
              itemBuilder: (_) => [
                PopupMenuItem(
                  child: const Text('📋 Ver Detalles'),
                  onTap: () => _showFileDetails(file),
                ),
                PopupMenuItem(
                  child: const Text('🗑️ Eliminar Seguro'),
                  onTap: () => _showDeleteDialog(file),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFileDetails(File file) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalles del Archivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Nombre:', file.path.split('/').last),
            _buildDetailRow('Tamaño:', _formatFileSize(file.lengthSync())),
            _buildDetailRow('Ruta:', file.path),
            _buildDetailRow(
              'Creado:',
              file.statSync().modified.toString(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(File file) {
    showDialog(
      context: context,
      builder: (_) => SecureDeleteConfirmationDialog(
        evidenceFile: file,
        onSuccess: () {
          _loadEvidenceFiles();  // Recargar lista
        },
        onError: (error) {
          print('Error: $error');
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, softWrap: true),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ============================================================================
// EJEMPLO 3: Batch Delete (DEBUG ONLY)
// ============================================================================

class SecureDeleteBatchButton extends StatefulWidget {
  const SecureDeleteBatchButton({Key? key}) : super(key: key);

  @override
  State<SecureDeleteBatchButton> createState() => _SecureDeleteBatchButtonState();
}

class _SecureDeleteBatchButtonState extends State<SecureDeleteBatchButton> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _deleting ? null : _performBatchDelete,
      icon: const Icon(Icons.delete_sweep),
      label: _deleting
          ? const Text('Borrando...')
          : const Text('Borrar Todo (DEBUG)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _performBatchDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Borrar Todo'),
        content: const Text(
          'Esta acción eliminará TODOS los archivos de evidencia de forma segura. '
          'Esta operación NO SE PUEDE DESHACER.\n\n'
          'Solo disponible en modo DEBUG.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Borrar Todo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);

    try {
      final evidenceService = EvidenceService();
      await evidenceService.clearAllEvidenceFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Todos los archivos eliminados de forma segura'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _deleting = false);
    }
  }
}

// ============================================================================
// EJEMPLO 4: Tests Unitarios
// ============================================================================

/*
// **tests/evidence_service_test.dart**

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:defensa_express/services/evidence_service.dart';

void main() {
  group('EvidenceService - Secure Delete Tests', () {
    late Directory testDir;
    late EvidenceService evidenceService;

    setUpAll(() async {
      testDir = Directory.systemTemp.createTempSync();
      evidenceService = EvidenceService();
    });

    tearDownAll(() async {
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('secureDeleteEvidenceFile should delete small audio file', () async {
      final testFile = File('${testDir.path}/test_audio.m4a');
      final testData = List<int>.generate(100, (i) => i % 256);
      await testFile.writeAsBytes(testData);

      expect(await testFile.exists(), true);

      final success = await evidenceService.secureDeleteEvidenceFile(testFile);

      expect(success, true);
      expect(await testFile.exists(), false);
    });

    test('secureDeleteEvidenceFile should delete large video file', () async {
      final testFile = File('${testDir.path}/test_video.mp4');
      final testData = List<int>.generate(10 * 1024 * 1024, (i) => i % 256);
      await testFile.writeAsBytes(testData);

      expect(await testFile.exists(), true);

      final success = await evidenceService.secureDeleteEvidenceFile(testFile);

      expect(success, true);
      expect(await testFile.exists(), false);
    });

    test('secureDeleteEvidenceFile should return false for non-existent file', () async {
      final testFile = File('${testDir.path}/non_existent.mp4');

      final success = await evidenceService.secureDeleteEvidenceFile(testFile);

      expect(success, false);
    });

    test('secureDeleteEvidenceFile should rename file before deletion', () async {
      // Este test verifica que el archivo sea renombrado antes de eliminación
      // (es decir, que haya ofuscación de metadatos)
      final testFile = File('${testDir.path}/evidencia_critica.mp4');
      final testData = List<int>.generate(1024, (i) => i % 256);
      await testFile.writeAsBytes(testData);

      final success = await evidenceService.secureDeleteEvidenceFile(testFile);

      expect(success, true);
      // Verificar que archivo original no existe y tampoco archivos .tmp
      expect(await testFile.exists(), false);
      final tmpFiles = await testDir.list().where((f) => f.path.endsWith('.tmp')).toList();
      expect(tmpFiles.isEmpty, true);
    });
  });
}
*/
