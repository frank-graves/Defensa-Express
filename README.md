# Defensa Express ⚖️📱
> **Motor Legal Offline-First para la Defensa de Derechos Ciudadanos en Intervenciones Policiales (Perú)**

Este repositorio contiene el artefacto de software desarrollado como parte de la investigación tecnológica titulada **"DEFENSA EXPRESS: DISEÑO E IMPLEMENTACIÓN DE UN MOTOR LEGAL OFFLINE-FIRST PARA LA DEFENSA DE DERECHOS CIUDADANOS EN INTERVENCIONES POLICIALES, PERÚ"**.

**Enfoque Metodológico:** Design Science Research (DSR)

---

## 📝 Resumen del Proyecto

Defensa Express es una solución móvil diseñada para mitigar la **asimetría informativa** y la vulnerabilidad jurídica que enfrentan los ciudadanos durante las intervenciones policiales urbanas en el Perú. 

A diferencia de las plataformas estatales tradicionales, esta aplicación adopta un enfoque **Offline-First**, permitiendo realizar consultas legales instantáneas y registrar evidencias multimedia de forma 100% desconectada de la red (sin necesidad de plan de datos o Wi-Fi), resolviendo el problema de la baja conectividad en la vía pública.

---

## 🛠️ Arquitectura y Componentes Técnicos

El sistema está construido utilizando el framework **Flutter (Dart)**, enfocándose en la computación en el borde (*edge computing*) para dispositivos móviles:

* **Motor de Búsqueda Híbrido:** Implementación local de algoritmos léxicos optimizados para operar sin servidores centralizados:
    * *Tokenización y Stop Words:* Limpieza y reducción de las cadenas de búsqueda en un 35% promedio.
    * *Distancia de Levenshtein:* Tolerancia y corrección de errores tipográficos bajo escenarios de estrés del usuario.
    * *Coeficiente de Jaccard:* Ordenamiento por relevancia temática basándose en la similitud de conjuntos discontinuos de términos.
* **Corpus Normativo Local (JSON):** 41 registros normativos críticos indexados directamente de fuentes oficiales (El Peruano, SPIJ), organizados en:
    * Derechos Fundamentales (Constitución Política del Perú).
    * Código Procesal Penal (Límites al control de identidad).
    * Reglamento Nacional de Tránsito.
* **Gestión de Estado y Clean Architecture:** Estructura basada en el desacoplamiento de capas (Data, Domain, Presentation) empleando un gestor de estados reactivo para asegurar la escalabilidad del sistema.

---

## 📊 Auditoría de Evolución (v0.4.0 vs v0.5.0)

El desarrollo del artefacto siguió ciclos de evaluación cuantitativa estrictos bajo el marco DSR para medir el impacto de la optimización:

| Métrica / Problema | Prototipo Inestable (v0.4.0) | Versión Optimizada (v0.5.0) |
| :--- | :--- | :--- |
| **Bloqueo de Interfaz (UI)** | Operación síncrona en hilo principal (~80MB RAM / Congelamiento de 1.2s - 3.4s). | **Asíncrono en Background Isolates** (60 FPS estables en renderizado). |
| **Soporte de Caracteres** | Bug de desbordamiento en normalización de cadenas (eliminaba caracteres como la "ñ"). | **Saneamiento Unicode Nativo** (`normalize('NFD')`) corregido al 100%. |
| **Integridad del Corpus** | Excepción de sintaxis JSON en fuentes secundarias causaba omisión silenciosa. | **Estructura parseada y validada** mediante flujos de manejo de errores. |
| **Arquitectura** | Alto acoplamiento en servicios duplicados redundantes de procesamiento léxico. | **Desacoplado con Clean Architecture** e inyección de dependencias limpia. |

---

## 🛡️ Módulo Discreto de Evidencias

El aplicativo cuenta con un sistema de captura multimedia (audio y video) en segundo plano (*Privacy by Design*) que opera de forma discreta con la pantalla apagada, valiéndose de retroalimentación háptica (`vibration`) para guiar al usuario.

### Sustento Legal:
La legitimidad de este módulo se ampara en el **Artículo 2, inciso 10 de la Constitución Política del Perú** y la **RM N° 952-2018-IN**, las cuales establecen que las intervenciones policiales en la vía pública son actos de carácter público. Por ende, los ciudadanos poseen el derecho constitucional legítimo de documentar y filmar el procedimiento como garantía de protección jurídica.

---

## 🚀 Instrucciones de Ejecución Rápida

1.  **Clonar el repositorio:**
    ```bash
    git clone [https://github.com/frank-graves/Defensa-Express.git](https://github.com/frank-graves/Defensa-Express.git)
    ```
2.  **Instalar dependencias:**
    ```bash
    flutter pub get
    ```
3.  **Ejecutar el proyecto:**
    ```bash
    flutter run
    ```
