#!/bin/bash
# ==============================================================================
# SCRIPT: cleanup_fase5.sh
# PROYECTO: Defensa Express v0.4.0+4
# OBJETIVO: Limpieza profunda de cachés, compilaciones y artefactos sin usar
# FASE: Fase 5 - Optimización ASF (Rendimiento Extremo)
# ==============================================================================
# 
# EJECUCIÓN:
#   chmod +x cleanup_fase5.sh
#   ./cleanup_fase5.sh
#
# TIEMPO ESTIMADO: 10-15 minutos
# ==============================================================================

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🧹 LIMPIEZA PROFUNDA - Defensa Express (Fase 5)${NC}"
echo -e "${BLUE}🕐 ${TIMESTAMP}${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# ==============================================================================
# 1. LIMPIEZA DE FLUTTER
# ==============================================================================
echo -e "${YELLOW}📦 [1/6] Limpiando Flutter...${NC}"

echo "   ├─ flutter clean"
flutter clean

echo "   ├─ flutter pub get"
flutter pub get

echo "   └─ flutter pub cache clean -f"
flutter pub cache clean -f

echo -e "${GREEN}   ✅ Flutter limpio${NC}"
echo ""

# ==============================================================================
# 2. LIMPIEZA DE ANDROID (Gradle + Build)
# ==============================================================================
if [ -d "android" ]; then
    echo -e "${YELLOW}🤖 [2/6] Limpiando Android (Gradle)...${NC}"
    cd android
    
    echo "   ├─ ./gradlew clean"
    ./gradlew clean
    
    echo "   ├─ Removiendo build/ de módulos"
    find . -type d -name build -exec rm -rf {} + 2>/dev/null || true
    
    echo "   ├─ Removiendo .gradle/"
    rm -rf .gradle/
    
    echo "   ├─ Removiendo .idea/"
    rm -rf .idea/
    
    echo "   └─ Removiendo local.properties"
    rm -f local.properties
    
    cd ..
    echo -e "${GREEN}   ✅ Android limpio${NC}"
else
    echo -e "${YELLOW}   ⚠️  Carpeta android/ no existe, saltando${NC}"
fi
echo ""

# ==============================================================================
# 3. LIMPIEZA DE iOS (CocoaPods + Xcode Build)
# ==============================================================================
if [ -d "ios" ]; then
    echo -e "${YELLOW}🍎 [3/6] Limpiando iOS (CocoaPods + Xcode)...${NC}"
    cd ios
    
    echo "   ├─ Removiendo Pods/"
    rm -rf Pods/
    
    echo "   ├─ Removiendo Podfile.lock"
    rm -f Podfile.lock
    
    echo "   ├─ pod cache clean --all"
    pod cache clean --all 2>/dev/null || true
    
    echo "   ├─ Removiendo build/"
    rm -rf build/
    
    echo "   ├─ Removiendo .idea/"
    rm -rf .idea/
    
    echo "   └─ Removiendo Flutter generated"
    rm -rf Flutter/Flutter.framework
    rm -rf Flutter/Flutter.podspec
    
    cd ..
    echo -e "${GREEN}   ✅ iOS limpio${NC}"
else
    echo -e "${YELLOW}   ⚠️  Carpeta ios/ no existe, saltando${NC}"
fi
echo ""

# ==============================================================================
# 4. LIMPIEZA DE BUILD/ Y ARTEFACTOS
# ==============================================================================
echo -e "${YELLOW}🏗️  [4/6] Limpiando artefactos de compilación...${NC}"

echo "   ├─ Removiendo build/"
rm -rf build/

echo "   ├─ Removiendo .dart_tool/"
rm -rf .dart_tool/

echo "   ├─ Removiendo pubspec.lock"
rm -f pubspec.lock

echo -e "${GREEN}   ✅ Artefactos limpios${NC}"
echo ""

# ==============================================================================
# 5. LIMPIEZA DE FICHEROS TEMPORALES
# ==============================================================================
echo -e "${YELLOW}🗑️  [5/6] Limpiando ficheros temporales...${NC}"

echo "   ├─ Removiendo *.iml files"
find . -name "*.iml" -delete 2>/dev/null || true

echo "   ├─ Removiendo __pycache__/"
find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true

echo "   ├─ Removiendo .DS_Store (macOS)"
find . -name ".DS_Store" -delete 2>/dev/null || true

echo -e "${GREEN}   ✅ Temporales limpios${NC}"
echo ""

# ==============================================================================
# 6. RE-INICIALIZACIÓN
# ==============================================================================
echo -e "${YELLOW}🔄 [6/6] Re-inicializando proyecto...${NC}"

echo "   └─ flutter pub get"
flutter pub get

echo -e "${GREEN}   ✅ Proyecto re-inicializado${NC}"
echo ""

# ==============================================================================
# FINALIZACIÓN
# ==============================================================================
ENDTIME=$(date +"%Y-%m-%d %H:%M:%S")

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ LIMPIEZA COMPLETADA${NC}"
echo -e "${BLUE}🕐 ${ENDTIME}${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}📊 Estado después:${NC}"
echo "   • Flutter: limpio"
echo "   • Android: limpio"
echo "   • iOS: limpio"
echo "   • Build artifacts: eliminados"
echo "   • Dependencias: re-descargadas"
echo ""

echo -e "${GREEN}🚀 Próximos pasos:${NC}"
echo "   1. flutter run --debug                    # Ejecutar en desarrollo"
echo "   2. flutter build apk --release            # Compilar APK"
echo "   3. flutter build ios --release            # Compilar iOS"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
