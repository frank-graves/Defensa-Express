# 🔧 Instrucciones de Reparación: Resolución Ministerial N° 952-2018-IN

## 📍 Ubicación del Error

**Archivo:** `Json Shit/Resolución Ministerial N° 952-2018-IN (952-2018-in-20-aproba...).json`  
**Línea aproximada:** 43-44  
**Tipo de error:** Objeto `{` órfano sin clave (viola RFC 8259)

---

## ❌ Problema Actual

```json
  "medios_de_policia": [
    "Bastón policial (Goma, Tonfa, Extensible)",
    "Agentes químicos (Aerosol pimienta, Gas lacrimógeno)",
    "Grilletes de seguridad",
    "Armas de fuego"
  ],
  {                          ← ❌ OBJETO ÓRFANO
  "manual_id": "RM-952-2018-IN",
  "titulo": "Manual de Derechos Humanos Aplicados a la Función Policial",
  ...
```

**Por qué es inválido:**
- En JSON, un objeto `{}` debe estar asociado a una **clave** dentro de un objeto padre
- La sintaxis es: `"clave": { ... }` o un array `[ { ... } ]`
- Un `{` desnudo en el medio de propiedades del objeto viola RFC 8259

**Efecto:**
- `jsonDecode()` en Dart **lanza excepción**
- El corpus de la Resolución Ministerial **no se carga**
- Motor de búsqueda excluye este documento

---

## ✅ Solución: Eliminar el `{` Innecesario

### Opción 1: Editar Manualmente (Recomendado para Control Total)

1. **Abrir el archivo en VS Code:**
   ```
   Json Shit/Resolución Ministerial N° 952-2018-IN (952-2018-in-20-aproba...).json
   ```

2. **Usar Ctrl+G (Go to Line) para ir a línea 43:**
   - Presionar: `Ctrl+G`
   - Escribir: `43`
   - Presionar: `Enter`

3. **Buscar el patrón (`Ctrl+F`):**
   ```
   ],
     {
     "manual_id"
   ```

4. **Cambio exacto:**
   - **ANTES:**
     ```json
     ],
       {
       "manual_id": "RM-952-2018-IN",
     ```
   - **DESPUÉS:**
     ```json
     ],
       "manual_id": "RM-952-2018-IN",
     ```
   - **Acción:** Eliminar el `{` en la línea 44

5. **Guardar:** `Ctrl+S`

---

### Opción 2: Usar Regex Replace (Rápido)

1. **Abrir Find & Replace:** `Ctrl+H`

2. **Find:** 
   ```
   ],\s+\{\s+"manual_id"
   ```

3. **Replace:**
   ```
   ],
     "manual_id"
   ```

4. **Replace All:** Click en "Replace All" button (o `Ctrl+Alt+Enter`)

5. **Guardar:** `Ctrl+S`

---

### Opción 3: Validar y Reparar vía Terminal

```bash
# 1. Instalar herramienta de validación JSON
dart pub global activate json_schema

# 2. Validar archivo actual (debería fallar)
dart pub global run json_schema "Json Shit/Resolución Ministerial N° 952-2018-IN"*.json

# 3. Editar manualmente (opción 1 o 2)

# 4. Validar nuevamente (debería pasar)
dart pub global run json_schema "Json Shit/Resolución Ministerial N° 952-2018-IN"*.json
```

---

## 🧪 Validación Post-Reparación

### Test 1: Validar JSON Localmente

```bash
# PowerShell / Windows
$json = Get-Content -Path "Json Shit\Resolución Ministerial N° 952-2018-IN (952-2018-in-20-aproba...).json" -Raw
$parsed = $json | ConvertFrom-Json
Write-Host "✓ JSON válido" -ForegroundColor Green
```

### Test 2: Validar Online

Copiar el contenido del archivo reparado a: https://jsonlint.com/  
Debe mostrar: ✅ **Valid JSON**

### Test 3: Verificar en Dart

```dart
import 'dart:convert';

void main() {
  try {
    final jsonString = r'''
    {
      "medios_de_policia": [...],
      "manual_id": "RM-952-2018-IN",
      ...
    }
    ''';
    final parsed = jsonDecode(jsonString);
    print('✓ JSON parseable en Dart');
  } catch (e) {
    print('✗ Error: $e');
  }
}
```

---

## 📋 Checklist Post-Reparación

- [ ] Archivo abierto en VS Code
- [ ] Línea 43-44 verificada: `],` seguida de `"manual_id"` (sin `{`)
- [ ] Archivo guardado (`Ctrl+S`)
- [ ] Validación JSON pasada en jsonlint.com
- [ ] Copiar archivo reparado a `assets/legal_data/`
- [ ] Actualizar `pubspec.yaml` si es necesario
- [ ] Ejecutar `flutter pub get`
- [ ] Ejecutar `flutter analyze` (sin errores)

---

## 🚀 Siguientes Pasos

Una vez reparado:

```bash
# 1. Copiar archivo reparado a assets
cp "Json Shit/Resolución Ministerial N° 952-2018-IN"*.json assets/legal_data/

# 2. Verificar que pubspec.yaml incluya assets
cat pubspec.yaml | grep -A 2 "flutter:"

# 3. Actualizar pubspec
flutter pub get

# 4. Verificar que el código compila sin errores
flutter analyze

# 5. (Opcional) Ejecutar tests
flutter test
```

---

## 📝 Detalles Técnicos

**RFC 8259 Compliance:**
```
RFC 8259 - The JavaScript Object Notation (JSON) Data Interchange Format

3.1. BEGIN-OBJECT

   An object is an unordered collection of zero or more name/value
   pairs, enclosed by curly brackets, with name and value separated by
   a colon.

   object = begin-object [ member *( value-separator member ) ]
            end-object

   member = string name-separator value
```

El `{` sin un `member` (string + colon + value) es inválido.

---

## ⚠️ Errores Comunes a Evitar

| Acción | ✗ Incorrecto | ✓ Correcto |
|--------|-------------|-----------|
| Después del array | `],\n{` | `],\n"key"` |
| Formato de clave | `{manual_id: ...}` | `{"manual_id": ...}` |
| Comilla en valores | `"titulo": Manual de...` | `"titulo": "Manual de..."` |
| Trailing comma | `"key": "value",}` | `"key": "value"}` |

