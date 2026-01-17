# Módulos Funcionales del Sistema

El sistema se compone de 6 módulos lógicos independientes que agrupan las funcionalidades por responsabilidad de negocio.

## Módulo 1: Seguridad y Auth
*Ubicación: `lib/features/login`*
Encargado de gestionar la identidad y el acceso mediante roles (RBAC).
* **Autenticación:** Login seguro con credenciales institucionales.
* **Recuperación:** Flujo para restablecer contraseñas vía correo.
* **Student Lookup:** Permite verificar si un alumno está dictaminado antes de permitirle registrarse.

## Módulo 2: Ingesta y Administración
*Ubicación: `lib/features/operations` y `lib/features/academic`*
Responsable de la inicialización de datos y gestión de catálogos.
* **Carga Masiva (ETL):** Procesamiento de archivos Excel/CSV para dar de alta alumnos masivamente.
* **Gestión de Tutores:** ABM (Altas, Bajas, Modificaciones) del catálogo de profesores por academia.

## Módulo 3: Workflow de Asignación
*Ubicación: `lib/features/students` y `lib/features/academic`*
Núcleo lógico que controla el ciclo de vida de la tutoría.
* **Motor de Asignación:** Vinculación manual de Alumno-Tutor-Materia.
* **Máquina de Estados:** Control automático del estatus (`Pendiente` → `En Curso` → `Acreditado`).

## Módulo 4: Gestión Documental (DMS)
*Ubicación: `lib/features/operations/upload_evidence`*
Repositorio digital seguro para el soporte del proceso.
* **Carga de Evidencias:** Interfaz para subir bitácoras y actas (PDF/Imagen).
* **Validación:** Flujo de aprobación/rechazo por parte del Jefe de Academia.

## Módulo 5: Evaluación y Reportes
*Ubicación: `lib/features/reports`*
Formalización de resultados y entregables.
* **Registro de Calificaciones:** Captura segura de la nota final.
* **Reportes Oficiales:** Generación de PDFs y Excels listos para entregar a Gestión Escolar.
* **Gráficas:** Visualización estadística del rendimiento semestral.

## Módulo 6: Notificaciones
Servicio transversal para mantener informados a los actores.
* **Alertas:** Correos automáticos ante asignación de tutor o rechazo de evidencia.