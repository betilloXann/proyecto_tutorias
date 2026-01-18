# Estructura del Código

El proyecto sigue una **Arquitectura basada en Features (Características)** combinada con principios de **Clean Architecture**. Esto permite que cada módulo del negocio (Login, Estudiantes, Reportes) sea independiente y escalable.

## Organización de Carpetas
El código fuente en `lib/` se divide en tres capas principales:

### 1. Core (`lib/core/`)
Contiene componentes compartidos y configuración global que utiliza toda la aplicación.
* **`config/`**: Configuraciones generales como el comportamiento del scroll (`app_scroll_behavior.dart`).
* **`providers/`**: Gestión de estado global (ej. `auth_provider.dart` para la sesión del usuario).
* **`widgets/`**: Elementos de UI reutilizables (Botones, Inputs, Contenedores responsivos).

### 2. Data (`lib/data/`)
Capa encargada de la manipulación de datos y comunicación externa.
* **`models/`**: Clases que definen la estructura de los datos (ej. `EnrollmentModel`, `EvidenceModel`, `ProfessorModel`).
* **`repositories/`**: Abstracción de las fuentes de datos (ej. `AuthRepository`, `AdminRepository`).
* **`services/`**: Lógica de integración con APIs o librerías específicas (ej. `PdfGeneratorService`, `FirebaseService`).

### 3. Features (`lib/features/`)
Aquí reside la lógica de negocio dividida por módulos funcionales. Cada feature contiene sus propias Vistas (UI) y ViewModels (Lógica).

* **`login/`**: Gestión de acceso, recuperación de contraseña y búsqueda de alumnos.
* **`dashboard/`**: Menú principal y navegación.
* **`academic/`**: Gestión de academias, materias y profesores.
* **`students/`**: Detalle del alumno, historial y vistas principales del estudiante.
* **`operations/`**: Procesos operativos como carga masiva (`bulk_upload`) y subida de evidencias.
* **`reports/`**: Generación de reportes semestrales y gráficas estadísticas.
* **`admin/`**: Panel de control para el Coordinador.

---

## Patrón de Diseño: MVVM
El proyecto implementa el patrón **Model-View-ViewModel (MVVM)** para separar la interfaz gráfica de la lógica de negocio.

* **View (`views/`)**: Solo dibuja la interfaz. No toma decisiones.
* **ViewModel (`viewmodels/`)**: Contiene el estado y la lógica. Procesa los datos y notifica a la vista cuando debe redibujarse (usando `Provider`).
* **Model (`models/`)**: Estructura pura de los datos.