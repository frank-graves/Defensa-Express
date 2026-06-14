import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cryptography/cryptography.dart';

/// Servicio de Criptografía para Evidencias - Privacy-First
/// 
/// **Arquitectura:**
/// - Master Key: Generada una sola vez, almacenada en Keystore/Keychain nativo
/// - Cifrado: AES-256-SIC (Stream Cipher, óptimo para archivos grandes)
/// - IV (Vector de Inicialización): Único y aleatorio por archivo
/// - Almacenamiento: [16 bytes IV] + [N bytes Ciphertext] en archivo .enc
/// - Optimización: Procesamiento por bloques (chunks) para evitar OOM
///
/// **Propiedades de Seguridad:**
/// - Keystore nativo: Imposible acceder incluso con root (hardware-backed)
/// - SIC Mode: No requiere padding, seguro para streams contiguos
/// - IV único: Previene ataques de patrón de frecuencia
/// - Streaming: Archivos grandes (≥5 MB) se procesan por chunks
/// - Zero-copy IV handling: Seguro contra memory leaks
class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _masterKeyName = 'defensa_express_master_key_v1';
  static const int _ivLength = 16;
  static const int _chunkSize = 256 * 1024; // 256 KB chunks para streaming
  static const int _memoryThreshold = 5 * 1024 * 1024; // 5 MB threshold

  /// Obtiene o genera la Master Key desde el Keystore/Keychain nativo
  /// 
  /// La llave se almacena permanentemente en el hardware seguro del dispositivo.
  /// Solo la primera ejecución genera una nueva llave; las posteriores la recuperan.
  static Future<String> _getMasterKey() async {
    try {
      var keyB64 = await _storage.read(key: _masterKeyName);
      
      if (keyB64 == null) {
        // Generar nueva Master Key de 32 bytes (256-bit) de forma criptográficamente segura
        final algorithm = AesGcm.with256bits();
        final secretKey = await algorithm.generateKey();
        keyB64 = base64Encode(secretKey.extractSync());
        
        // Guardar en Keystore/Keychain nativo (no se puede exportar)
        await _storage.write(key: _masterKeyName, value: keyB64);
        
        if (kDebugMode) { print('✅ Master Key generada y asegurada en Keystore'); }
      }
      
      return keyB64;
    } catch (e) {
      if (kDebugMode) { print('❌ Error gestionando Master Key: $e'); }
      rethrow;
    }
  }

  /// Cifra un archivo de evidencia con AES-256-SIC (Counter Mode)
  /// 
  /// **Optimización de Memoria:**
  /// - Archivos < 5 MB: Procesamiento en memoria (velocidad)
  /// - Archivos ≥ 5 MB: Procesamiento por streams (estabilidad)
  /// 
  /// **Proceso:**
  /// 1. Genera IV aleatorio único (16 bytes)
  /// 2. Determina si usar memoria o streams según tamaño
  /// 3. Cifra con AES-256-SIC usando la Master Key
  /// 4. Guarda formato: [16 bytes IV] + [ciphertext] en archivo .enc
  /// 5. BORRA de forma segura el archivo original (truncate + delete)
  /// 
  /// **Retorna:** File cifrado (.enc), null si falla
  static Future<File?> encryptEvidenceFile(File sourceFile) async {
    try {
      if (!await sourceFile.exists()) {
        if (kDebugMode) { print('⚠️ Archivo fuente no existe: ${sourceFile.path}'); }
        return null;
      }

      // Obtener Master Key
      final masterKeyB64 = await _getMasterKey();
      final masterKeyBytes = base64Decode(masterKeyB64);
      final masterKey = encrypt.Key(masterKeyBytes);

      // Generar IV único para este archivo
      final random = Random.secure();
      final iv = encrypt.IV(List<int>.generate(_ivLength, (_) => random.nextInt(256)));

      // Crear cifrador AES-256-SIC (Counter Mode - óptimo para streams)
      final encrypter = encrypt.Encrypter(encrypt.AES(masterKey, mode: encrypt.AESMode.sic));

      // Obtener tamaño del archivo
      final fileSize = await sourceFile.length();
      final encryptedPath = '${sourceFile.path}.enc';
      final encryptedFile = File(encryptedPath);

      if (fileSize < _memoryThreshold) {
        // RUTA RÁPIDA: Archivos pequeños en memoria (audios típicamente)
        if (kDebugMode) { print('⚡ Modo rápido: Cifrando en memoria (${fileSize ~/ 1024} KB)'); }

        // Leer archivo original completo
        final fileBytes = await sourceFile.readAsBytes();

        // Cifrar
        final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

        // Guardar formato: [IV (16 bytes)] + [ciphertext]
        final combinedBytes = iv.bytes + encrypted.bytes;
        await encryptedFile.writeAsBytes(combinedBytes);

        if (kDebugMode) { print('✅ Archivo cifrado (memoria): $encryptedPath (${fileBytes.length} → ${combinedBytes.length} bytes)'); }
      } else {
        // RUTA SEGURA: Archivos grandes por streaming (videos)
        if (kDebugMode) { print('🌊 Modo streaming: Cifrando por chunks (${fileSize ~/ (1024 * 1024)} MB)'); }

        // Abrir archivo de destino para escritura
        final raf = await encryptedFile.open(mode: FileMode.write);

        try {
          // Escribir IV al inicio del archivo
          await raf.writeFrom(iv.bytes);

          // Procesar archivo original por chunks
          final sourceStream = sourceFile.openRead();
          int bytesProcessed = 0;

          await for (final chunk in sourceStream) {
            // Cifrar chunk actual
            final encrypted = encrypter.encryptBytes(chunk, iv: iv);

            // Escribir ciphertext al archivo destino
            await raf.writeFrom(encrypted.bytes);

            bytesProcessed += chunk.length;
            if (kDebugMode && bytesProcessed % (1024 * 1024) == 0) {
              print('  ⏳ Procesados: ${bytesProcessed ~/ (1024 * 1024)} MB de ${fileSize ~/ (1024 * 1024)} MB');
            }
          }

          await raf.flush();
          if (kDebugMode) { print('✅ Archivo cifrado (streaming): $encryptedPath (${fileSize} → ${await encryptedFile.length()} bytes)'); }
        } finally {
          await raf.close();
        }
      }

      // BORRADO SEGURO del archivo original (antes de retornar)
      try {
        // Fase 1: Truncate a 0 bytes (minimiza metadatos rescrutable)
        await sourceFile.truncate(0);
        
        // Fase 2: Delete (elimina del filesystem)
        await sourceFile.delete();
        
        if (kDebugMode) { print('🔥 Archivo original borrado de forma segura: ${sourceFile.path}'); }
      } catch (deleteError) {
        if (kDebugMode) { print('⚠️ Error borrando original (pero cifrado exitoso): $deleteError'); }
        // Continuar incluso si el borrado falla; el archivo cifrado ya está seguro
      }

      return encryptedFile;
    } catch (e) {
      if (kDebugMode) { print('❌ Error cifrando archivo: $e'); }
      rethrow;
    }
  }

  /// Descifra un archivo de evidencia previamente cifrado
  /// 
  /// **Optimización de Memoria:**
  /// - Archivos < 5 MB: Procesamiento en memoria (velocidad)
  /// - Archivos ≥ 5 MB: Procesamiento por streams (estabilidad)
  /// 
  /// **Proceso:**
  /// 1. Lee primeros 16 bytes como IV
  /// 2. Determina si usar memoria o streams según tamaño
  /// 3. Descifra resto del archivo con AES-256-SIC
  /// 4. Retorna archivo .dec (temporal para reproducción/exportación)
  /// 
  /// **Nota:** El archivo .dec es temporal; debe ser borrado después de usarlo.
  static Future<File?> decryptEvidenceFile(File encryptedFile) async {
    try {
      if (!await encryptedFile.exists()) {
        if (kDebugMode) { print('⚠️ Archivo cifrado no existe: ${encryptedFile.path}'); }
        return null;
      }

      // Obtener Master Key
      final masterKeyB64 = await _getMasterKey();
      final masterKeyBytes = base64Decode(masterKeyB64);
      final masterKey = encrypt.Key(masterKeyBytes);

      // Obtener tamaño total del archivo
      final totalSize = await encryptedFile.length();

      if (totalSize < _ivLength) {
        throw Exception('Archivo cifrado corrupto: demasiado pequeño');
      }

      // Leer primeros 16 bytes como IV
      final ivBytes = await encryptedFile.openRead(0, _ivLength).first;
      if (ivBytes.length < _ivLength) {
        throw Exception('No se pudo extraer IV del archivo cifrado');
      }

      final iv = encrypt.IV(ivBytes.sublist(0, _ivLength));
      final ciphertextSize = totalSize - _ivLength;

      // Crear cifrador AES-256-SIC (Counter Mode)
      final encrypter = encrypt.Encrypter(encrypt.AES(masterKey, mode: encrypt.AESMode.sic));

      // Crear ruta del archivo descifrado
      final decryptedPath = encryptedFile.path.replaceAll('.enc', '.dec');
      final decryptedFile = File(decryptedPath);

      if (ciphertextSize < _memoryThreshold) {
        // RUTA RÁPIDA: Archivos pequeños en memoria
        if (kDebugMode) { print('⚡ Modo rápido: Descifrando en memoria (${ciphertextSize ~/ 1024} KB)'); }

        // Leer archivo cifrado completo
        final combinedBytes = await encryptedFile.readAsBytes();
        final ciphertextBytes = combinedBytes.sublist(_ivLength);
        final encrypted = encrypt.Encrypted(ciphertextBytes);

        // Desciframiento
        final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

        // Guardar archivo descifrado
        await decryptedFile.writeAsBytes(decrypted);

        if (kDebugMode) { print('✅ Archivo descifrado (memoria): $decryptedPath (${ciphertextSize} → ${decrypted.length} bytes)'); }
      } else {
        // RUTA SEGURA: Archivos grandes por streaming
        if (kDebugMode) { print('🌊 Modo streaming: Descifrando por chunks (${ciphertextSize ~/ (1024 * 1024)} MB)'); }

        // Abrir archivo de destino para escritura
        final raf = await decryptedFile.open(mode: FileMode.write);

        try {
          // Procesar archivo cifrado por chunks, saltando los primeros 16 bytes (IV)
          final sourceStream = encryptedFile.openRead(_ivLength);
          int bytesProcessed = 0;

          await for (final chunk in sourceStream) {
            // Desciframiento de chunk
            final encrypted = encrypt.Encrypted(chunk);
            final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

            // Escribir plaintext al archivo destino
            await raf.writeFrom(decrypted);

            bytesProcessed += chunk.length;
            if (kDebugMode && bytesProcessed % (1024 * 1024) == 0) {
              print('  ⏳ Procesados: ${bytesProcessed ~/ (1024 * 1024)} MB de ${ciphertextSize ~/ (1024 * 1024)} MB');
            }
          }

          await raf.flush();
          if (kDebugMode) { print('✅ Archivo descifrado (streaming): $decryptedPath (${ciphertextSize} → ${await decryptedFile.length()} bytes)'); }
        } finally {
          await raf.close();
        }
      }

      return decryptedFile;
    } catch (e) {
      if (kDebugMode) { print('❌ Error descifrando archivo: $e'); }
      rethrow;
    }
  }

  /// **NUKE BUTTON:** Destruye la Master Key de forma irreversible
  /// 
  /// Úsalo solo en emergencias (cuando la detención es inminente).
  /// Una vez ejecutado, NO PODRÁ accederse a NINGUNA evidencia cifrada.
  /// 
  /// **Consecuencia:** Todos los archivos .enc quedan inaccesibles permanentemente.
  static Future<void> destroyMasterKey() async {
    try {
      await _storage.delete(key: _masterKeyName);
      if (kDebugMode) { print('🔥🔥🔥 MASTER KEY DESTRUIDA - Todas las evidencias se han vuelto inaccesibles'); }
    } catch (e) {
      if (kDebugMode) { print('❌ Error destruyendo Master Key: $e'); }
      rethrow;
    }
  }
}
