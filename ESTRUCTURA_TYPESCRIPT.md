# Defensa Express - Motor de Búsqueda Legal

## Estructura TypeScript Implementada (Fase 1.1 + Fase 2)

### 📁 Estructura de Carpetas

```
src/
├── index.ts                 # Punto de entrada central (re-exportaciones)
├── types/
│   └── index.ts            # Definiciones de tipos actualizadas sin caracteres especiales
├── services/
│   └── LegalDataService.ts # Servicio principal de búsqueda local
└── utils/
    └── normalizacion.ts    # Funciones de normalización y cálculo de relevancia

ejemplos/
└── uso-basico.ts           # Ejemplo de uso completo

Json Shit/                  # Datos legales (4 archivos JSON principales)
├── Resolución Ministerial N° 952-2018-IN...json
├── Reglamento Nacional de Tránsito.json
├── Derechos fundamentales de la persona.json
└── Código Procesal Penal.json

tsconfig.json               # Configuración TypeScript (strict mode)
package.json                # Dependencias y scripts
```

### ✅ Cambios Implementados

#### 1. **Actualización de Tipos (Fase 1.1)**
- ✔ Eliminados caracteres especiales latinos (`SeñalReguladora` en lugar de `SeñalReguladora`)
- ✔ Agregado campo `tags?: string[]` en:
  - `DerechoFundamental`
  - `EscenarioProcesal`

#### 2. **Servicio LegalDataService (Fase 2)**

**Métodos principales:**

```typescript
// 1. Cargar datos (ejecutar una sola vez)
await servicioLegal.cargarDatos();

// 2. Búsqueda general normalizada
const resultados = servicioLegal.buscar("policia quiere entrar a mi casa");
// Retorna: ResultadoBusquedaLegal[] ordenado por relevancia DESC

// 3. Obtener infracción por código
const infraccion = servicioLegal.obtenerInfraccionPorCodigo("G.31");

// 4. Obtener derecho por ID
const derecho = servicioLegal.obtenerDerechoPorId("inviolabilidad_domicilio");

// 5. Obtener escenario por nombre
const escenario = servicioLegal.obtenerEscenarioPorNombre("Control de identidad...");

// 6. Estadísticas
const stats = servicioLegal.obtenerEstadisticas();

// 7. Validar carga
if (servicioLegal.estaListo()) { /* proceder */ }
```

#### 3. **Características de Búsqueda**

- ✔ **Normalización**: Quita tildes, convierte a minúsculas, elimina puntuación
- ✔ **Búsqueda en múltiples campos**:
  - Reglamento: `glosario` + `infracciones` (por código y descripción)
  - Derechos: `title` + `intents` + `rights_summary` + `tags`
  - Procesal: `scenario` + `accion_legal` + `guion_de_defensa` + `limite_policial` + `tags`
  - Resolución: `pilares_fundamentales`

- ✔ **Cálculo de Relevancia** (0-100):
  - 100: Coincidencia exacta
  - 90: Coincidencia al inicio
  - 75: Coincidencia parcial (substring)
  - 0-60: Similitud Levenshtein

- ✔ **Ordenamiento**: Automático por relevancia descendente

#### 4. **Privacy-First & FOSS**

- ✅ **100% Local**: Toda la lógica se ejecuta en cliente sin acceso a red
- ✅ **Offline**: Funciona completamente sin conexión a internet
- ✅ **Sin telemetría**: No se envían datos a servidores externos
- ✅ **Licencia GPL-3.0**: Compatible con software libre

### 🚀 Instalación y Uso

```bash
# 1. Instalar dependencias
npm install

# 2. Compilar TypeScript
npm run build

# 3. Ejecutar ejemplo
npm run ejemplo

# 4. Importar en tu código
import { LegalDataService, ResultadoBusquedaLegal } from "./src/index";

const servicio = new LegalDataService("Json Shit");
await servicio.cargarDatos();
const resultados = servicio.buscar("consulta legal");
```

### 📊 Estadísticas de Datos Cargados

```
Derechos Fundamentales: 10
Escenarios Procesales: 10
Infracciones de Tránsito: Múltiples (con código único)
Términos de Glosario: Extenso
Pilares de Derechos Humanos: Varios
```

### 🔧 Configuración TypeScript

- **strict: true** - Tipado estricto obligatorio
- **noImplicitAny: true** - No permite `any` implícito
- **strictNullChecks: true** - Validación de null/undefined
- **esModuleInterop: true** - Compatibilidad con módulos CommonJS

### 📝 Próximas Fases

- **Fase 3**: Integración con UI/UX (componentes React/Flutter)
- **Fase 4**: Caching y lazy loading
- **Fase 5**: Indexación avanzada y búsqueda fuzzy optimizada

---

**Licencia**: GPL-3.0-or-later  
**Privacidad**: 100% Local, sin datos en servidores  
**Estado**: ✓ Estructura física lista para Fase 3
