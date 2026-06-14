# 🎉 DEFENSA EXPRESS - Motor Legal Local Flutter

## Estado Actual: ✅ FASE 3 COMPLETADA - ESTRUCTURA LISTA PARA EJECUTAR

---

## 📱 Descripción General

**Defensa Express** es una aplicación Flutter con motor de búsqueda legal **100% local** y **privacy-first** para situaciones de interacción con autoridades policiales en Perú.

- **Idioma**: Español
- **Plataforma**: Flutter (Android + iOS)
- **Datos**: 4 archivos JSON con base legal peruana
- **Privacidad**: ✅ Offline-First | ✅ Sin Red | ✅ Sin Telemetría
- **Licencia**: GPL-3.0-or-later (FOSS)

---

## 🏗️ Estructura de Implementación

### **Fase 1: Tipado (TypeScript)** ✅ COMPLETADA
- Generación de 25+ interfaces TypeScript
- 5 enums para valores predefinidos
- Campos `tags?: string[]` agregados
- **Archivo**: `src/types/index.ts`

### **Fase 2: Servicio de Búsqueda (TypeScript)** ✅ COMPLETADA
- Servicio `LegalDataService` con búsqueda normalizada
- Algoritmo Levenshtein para similitud fuzzy
- Cálculo de relevancia (0-100%)
- **Archivo**: `src/services/LegalDataService.ts`

### **Fase 3: Traducción a Dart + UI Flutter** ✅ COMPLETADA
- Modelos Dart equivalentes a tipos TypeScript
- Servicio `LegalDataService` en Dart
- UI Flutter con widgets interactivos
- 6 botones de acceso rápido (emergencias)
- Modal desplegable con detalles completos
- **Archivos**:
  - `lib/models/legal_models.dart` (450+ líneas)
  - `lib/services/legal_data_service.dart` (500+ líneas)
  - `lib/main.dart` (600+ líneas, UI completa)

---

## 📂 Estructura de Carpetas

```
defensa_express/
├── lib/
│   ├── main.dart                          # Aplicación principal + UI
│   ├── models/
│   │   └── legal_models.dart             # Modelos Dart (15+ clases)
│   ├── services/
│   │   └── legal_data_service.dart       # Servicio de búsqueda
│   └── local_engine.dart                 # (Legacy - opcional eliminar)
│
├── Json Shit/                             # Base de datos legal
│   ├── Derechos fundamentales de la persona.json
│   ├── Código Procesal Penal.json
│   ├── Reglamento Nacional de Tránsito.json
│   └── Resolución Ministerial N° 952-2018-IN...json
│
├── src/                                   # Código TypeScript (referencia)
│   ├── types/index.ts
│   ├── services/LegalDataService.ts
│   └── utils/normalizacion.ts
│
├── pubspec.yaml                           # Config Flutter + Assets
├── FASE_3_COMPLETA.md                    # Documentación Fase 3
└── README.md                              # Este archivo
```

---

## 🚀 Cómo Ejecutar

### **Prerequisitos**
1. Instalar [Flutter SDK](https://flutter.dev/docs/get-started/install)
2. Instalar [Dart SDK](https://dart.dev/get-dart) (incluido con Flutter)
3. Android Studio o Xcode (para emulador/dispositivo)

### **Paso 1: Obtener Dependencias**
```bash
cd c:\Users\Usuario\Downloads\defensa_express
flutter pub get
```

### **Paso 2: Listar Dispositivos**
```bash
flutter devices
```

### **Paso 3: Ejecutar la App**

**En emulador (primera vez):**
```bash
flutter run
```

**En dispositivo específico:**
```bash
flutter run -d <device_id>
```

**Con debug info:**
```bash
flutter run -v
```

### **Paso 4 (Opcional): Compilar APK**
```bash
flutter build apk --release
```

---

## 🎨 Características de UI

### **Acceso Rápido (6 Botones de Emergencia)**
1. 🏠 Policía quiere ingresar a mi casa
2. 📱 Revisar mi celular
3. 🆔 Control de identidad
4. ⚖️ Detenido arbitrariamente
5. 🚗 Infracción de tránsito
6. 👥 Derecho a protesta pacífica

### **Tarjetas de Resultados**
- ✅ Ícono + color por tipo de documento
- ✅ Barra de relevancia (0-100%)
- ✅ Título y descripción truncada
- ✅ Vista previa de coincidencias
- ✅ Clickeable → Abre modal

### **Modal de Detalles**
- ✅ Desplegable (DraggableScrollableSheet)
- ✅ Scroll dentro del modal
- ✅ Información completa y formateada
- ✅ Destaque visual para acciones críticas

### **Colores por Tipo**
- 🟢 **DERECHOS**: Verde (#4CAF50)
- 🔴 **PENAL**: Rojo (#F44336)
- 🔵 **TRÁNSITO**: Azul (#2196F3)
- 🟠 **DDHH**: Naranja (#FF9800)
- 🟡 **ESTÁNDAR**: Dorado (#C8A84B)

---

## 🔍 Cómo Funciona la Búsqueda

### **1. Normalización**
```
Input:  "¿Dónde está MÍ abogado?"
Output: "donde esta mi abogado"
```
- Convierte a minúsculas
- Quita tildes (á→a, é→e, ñ→n, etc.)
- Elimina puntuación

### **2. Búsqueda en 4 Módulos**

| Módulo | Campos | Datos |
|--------|--------|-------|
| **Derechos** | title + intents + rights_summary + tags | 10 derechos |
| **Procesal** | scenario + accion_legal + guion + tags | 10 escenarios |
| **Tránsito** | glosario + infracciones (código + desc) | ~50+ términos |
| **DDHH** | pilares_fundamentales | Resolución 952 |

### **3. Cálculo de Relevancia (0-100%)**
```
100%  → Coincidencia exacta
90%   → Coincidencia al inicio
75%   → Substring encontrado
0-60% → Similitud Levenshtein
```

### **4. Ordenamiento**
Resultados ordenados automáticamente **descendente** por relevancia.

---

## 📊 Estadísticas

| Métrica | Cantidad |
|---------|----------|
| Clases Dart | 15+ |
| Enums Dart | 5 |
| Métodos en Service | 10 |
| Widgets Flutter | 8+ |
| Líneas de Dart | 1,500+ |
| Archivos JSON | 4 |
| Datos Legales | 10K+ líneas |

---

## 🛡️ Garantías de Privacidad

✅ **100% Local**: Todo se ejecuta en el dispositivo
✅ **Offline-First**: Funciona sin Internet
✅ **Sin Telemetría**: No hay rastreo ni envío de datos
✅ **Código Abierto**: Totalmente auditable
✅ **FOSS**: Licencia GPL-3.0-or-later

---

## 🧪 Pruebas Recomendadas

### Test 1: Carga Inicial
```
✓ Abre app
✓ Muestra "Cargando base de datos legal..."
✓ Después de 2-3s → Grid de acceso rápido
✓ Stats en consola: 10 derechos, 10 escenarios, etc.
```

### Test 2: Búsqueda Básica
```
Query: "policia quiere entrar"
Result: "Intento de Ingreso al Domicilio sin Orden Judicial" (verde)
Relevancia: 90%+
```

### Test 3: Búsqueda por Código
```
Query: "G.31"
Result: Infracción de luces bajas (azul)
Muestra: Gravedad, Puntos, Sanción
```

### Test 4: Modal Desplegable
```
✓ Tap en tarjeta → BottomSheet abre
✓ Puedo hacer scroll dentro del modal
✓ "Acción Inmediata" está destacada (dorado)
✓ Cierra al deslizar hacia abajo
```

### Test 5: Normalización
```
Queries equivalentes (todas dan mismo resultado):
- "policia me revisar el fono"
- "Policía me revisa el fono"
- "¿Policía me quiere revisar el fono?"
- "POLICIA ME REVISAR EL FONO"
```

---

## 🎯 Caso de Uso Típico

```
Usuario en emergencia:
  1. Abre app mientras policía está presente
  2. Ve grid de acceso rápido
  3. Toca "Policía quiere ingresar"
  4. App muestra Derecho Fundamental + Escenario Procesal
  5. Lee "ACCIÓN INMEDIATA":
     "Dile: Oficial, con todo respeto, para ingresar a mi..."
  6. Lee "TUS DERECHOS":
     "Tu casa es inviolable..."
  7. Lee "BASE LEGAL":
     "Artículo X de la Constitución..."
  8. Actúa informado y protegido
```

---

## 📝 Archivos Clave

### Modelos Dart (`lib/models/legal_models.dart`)
- 15+ clases
- 5 enums
- Factory constructors `fromJson()`
- Métodos `toJson()`

### Servicio Dart (`lib/services/legal_data_service.dart`)
- 10 métodos públicos
- Carga de 4 JSON desde assets
- Búsqueda normalizada
- Cálculo Levenshtein
- Ordenamiento automático

### UI Flutter (`lib/main.dart`)
- `DefensaExpressApp`: App principal
- `MainScreen`: Pantalla con búsqueda
- Widgets helper para tarjetas y detalles
- Modal desplegable con DraggableScrollableSheet

### Configuración (`pubspec.yaml`)
```yaml
assets:
  - Json Shit/Derechos fundamentales de la persona.json
  - Json Shit/Código Procesal Penal.json
  - Json Shit/Reglamento Nacional de Tránsito.json
  - Json Shit/Resolución Ministerial N° 952-2018-IN...json
```

---

## 🔧 Troubleshooting

| Problema | Solución |
|----------|----------|
| "asset not found" | Verifica `pubspec.yaml`, ejecuta `flutter clean && flutter pub get` |
| App lenta en búsqueda | Normal con 4 JSON grandes; para mejorar: implementar caché |
| Modal no abre | Verifica que estés en main thread; usa `setState()` correctamente |
| Caracteres de tilde incorrectos | Verifica encoding UTF-8 en archivos JSON |
| Emulador no detectado | Ejecuta `flutter devices` y especifica con `-d` |

---

## 🚀 Próximas Mejoras (Post-Fase 3)

- [ ] Implementar caché SQLite local
- [ ] Búsqueda fuzzy tri-gram indexing
- [ ] Historial de búsquedas (persistente)
- [ ] Favoritos (guardar derechos importantes)
- [ ] Sharing (compartir resultado en WhatsApp)
- [ ] Dark/Light theme toggle
- [ ] Traducción a inglés/quechua
- [ ] Unit tests + Integration tests
- [ ] Analytics local (sin envío a red)

---

## 📚 Referencias Legales

Los datos incluidos se basan en:
1. **Resolución Ministerial N° 952-2018-IN** - Manual de DDHH
2. **Reglamento Nacional de Tránsito** - D.S. N° 016-2009-MTC
3. **Constitución Política del Perú** - Derechos Fundamentales
4. **Código Procesal Penal** - Procedimientos

---

## 📄 Licencia

**GPL-3.0-or-later**

Este proyecto es software libre. Puedes copiarlo, modificarlo y distribuirlo bajo los términos de la licencia GPL-3.0.

---

## 🙏 Créditos

- **Motor de Búsqueda**: Arquitectura TypeScript → Traducción Dart
- **Base Legal**: Contenido de fuentes públicas peruanas
- **UI/UX**: Diseño emergency-responsive para situaciones críticas

---

## 📞 Soporte

Para problemas o sugerencias:
1. Verifica la documentación en `FASE_3_COMPLETA.md`
2. Revisa los logs: `flutter logs`
3. Ejecuta con debug: `flutter run -v`

---

**Status: ✅ FASE 3 COMPLETADA - ESTRUCTURA DART + UI LISTA**

```
╔════════════════════════════════════════════════════════════════╗
║         🎉 DEFENSA EXPRESS - MOTOR LEGAL LOCAL 🎉             ║
║                                                                ║
║  ✅ Privacy-First    ✅ Offline-First    ✅ FOSS              ║
║  ✅ 4 JSON Integrados ✅ UI Completa     ✅ Listo para Usar  ║
╚════════════════════════════════════════════════════════════════╝
```
