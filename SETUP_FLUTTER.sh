#!/bin/bash
# Script de configuración rápida para Defensa Express

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║            DEFENSA EXPRESS - Setup Flutter                    ║"
echo "║            Motor Legal Local - Privacy First                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Verificar que Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter no está instalado o no está en el PATH"
    echo "   Descárgalo desde: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter detectado:"
flutter --version
echo ""

# Cambiar a directorio del proyecto
cd "$(dirname "$0")" || exit

echo "📦 Obteniendo dependencias..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Dependencias instaladas exitosamente"
else
    echo "❌ Error al instalar dependencias"
    exit 1
fi

echo ""
echo "📋 Estructura de archivos:"
echo "   lib/models/legal_models.dart              ✓ Modelos Dart"
echo "   lib/services/legal_data_service.dart      ✓ Servicio de búsqueda"
echo "   lib/main.dart                             ✓ UI Principal"
echo "   pubspec.yaml                              ✓ Configuración actualizada"
echo "   Json Shit/                                ✓ 4 archivos JSON cargados"
echo ""

echo "🚀 Para ejecutar la aplicación:"
echo ""
echo "   Android/Emulator:"
echo "   $ flutter run"
echo ""
echo "   Device específico:"
echo "   $ flutter run -d <device_id>"
echo ""
echo "   iOS (macOS):"
echo "   $ flutter run -d ios"
echo ""

echo "📱 Para listar dispositivos disponibles:"
echo "   $ flutter devices"
echo ""

echo "🔨 Para compilar APK:"
echo "   $ flutter build apk"
echo ""

echo "✨ ¡Listo! El proyecto está configurado."
echo "   Privacy-First | Offline-First | FOSS"
echo ""
