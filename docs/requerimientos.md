# Análisis y Requerimientos del Sistema

## Definición del Problema
La gestión de tutorías de recuperación académica para alumnos dictaminados en Ingeniería Informática carece de una plataforma unificada. Actualmente, los datos (dictámenes, canalización, seguimiento, calificaciones) están dispersos en archivos independientes, hojas de cálculo y correos electrónicos, lo que genera inconsistencias y dificulta la trazabilidad.

**Puntos críticos detectados:**
* **Fragmentación:** Información sin relación formal entre sí (alumnos vs. profesores vs. materias).
* **Falta de Trazabilidad:** No existe un historial unificado de cambios o validaciones.
* **Procesos Manuales:** Dependencia de la manipulación manual de archivos Excel y PDFs.

---

## Solución Propuesta
Un **Prototipo Multiplataforma (Web y Móvil)** que centraliza la gestión documental.
* **Backend:** Firebase (Auth, Firestore) para sincronización en tiempo real.
* **Móvil:** App Flutter con SQLite local para funcionamiento offline.
* **Web:** Panel administrativo para Coordinación y Jefes de Academia.

---

## Requerimientos Funcionales (RF)

| Identificador | Módulo | Requerimiento | Descripción |
|:--------------| :--- | :--- | :--- |
| **RF-01**     | Seguridad | Autenticación por Roles | Acceso diferenciado para Coordinador, Jefe de Academia y Alumno. |
| **RF-02**     | Seguridad | Recuperación de Contraseña | Restablecimiento vía correo institucional. |
| **RF-04**     | Datos | Importación Masiva | Carga de archivos CSV/XLSX para crear expedientes de alumnos (ETL). |
| **RF-06**     | Datos | Catálogo de Tutores | ABM (Altas, Bajas, Modificaciones) de profesores por Academia. |
| **RF-07**     | Asignación | Asignación Manual | Vinculación de Alumno-Tutor con materia y horario específico. |
| **RF-08**     | Asignación | Tablero de Estatus | Visualización tipo semáforo (Pendiente → En Curso → Acreditado). |
| **RF-09**     | Evidencias | Carga de Bitácora | El alumno sube evidencia fotográfica/PDF de su asistencia. |
| **RF-11**     | Evidencias | Validación Digital | El Jefe de Academia aprueba o rechaza la evidencia (Workflow). |
| **RF-12**     | Evaluación | Registro de Calificación | Captura de la calificación oficial basada en el acta física. |
| **RF-13**     | Reportes | Reporte Consolidado | Generación de PDF/Excel para Gestión Escolar (Sistema ETS). |

---

## Requerimientos No Funcionales (RNF)

| ID | Categoría | Característica | Descripción Técnica |
| :--- | :--- | :--- | :--- |
| **RNF-01** | UX/UI | Multiplataforma | App Móvil (Android/iOS) para alumnos; Web para administrativos. |
| **RNF-02** | Rendimiento | Velocidad | Tiempos de carga inferiores a 3 segundos. |
| **RNF-03** | Seguridad | Integridad | Bloqueo de registros una vez acreditados (inmutabilidad). |
| **RNF-04** | Compatibilidad | Archivos | Soporte para JPG, PNG y PDF (máx 5MB). |

---

## Reglas de Negocio Principales
1.  **Centralización:** Toda la información reside en una única base de datos (Firestore); prohibido usar listas aisladas.
2.  **Validación Digital:** Sustitución de firmas físicas por flujos de aprobación de estatus en el sistema.
3.  **Seguimiento Obligatorio:** Todo alumno debe tener un estatus visible (Semáforo) en todo momento.