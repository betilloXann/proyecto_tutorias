# Stack Tecnológico

El sistema se ha construido como un **Prototipo Multiplataforma** utilizando tecnologías modernas que garantizan escalabilidad y eficiencia.

## Tecnologías Principales

| Componente | Tecnología | Descripción |
| :--- | :--- | :--- |
| **Frontend** | **Flutter (Dart)** | Desarrollo de interfaces nativas para iOS, Android y Web desde un solo código base. |
| **Backend (BaaS)** | **Firebase** | Proveedor de servicios en la nube para autenticación y base de datos. |
| **Base de Datos** | **Cloud Firestore** | Base de datos NoSQL documental para sincronización en tiempo real. |
| **Almacenamiento** | **Firebase Storage** | Repositorio para guardar las evidencias (imágenes y PDFs) de los alumnos. |

## Librerías Clave Implementadas
El proyecto integra paquetes especializados para resolver requerimientos complejos:

### Gestión de Documentos
* **`pdf` & `printing`**: Generación dinámica de reportes en formato PDF.
* **`excel`**: Creación y manipulación de hojas de cálculo para reportes administrativos.
* **`cleartec_docx_template`**: Automatización de documentos Word (rellenado de plantillas oficiales).
* **`file_picker`**: Selección de archivos nativa en móvil y web.

### Visualización y UI
* **`fl_chart`**: Renderizado de gráficas estadísticas para el dashboard de reportes.
* **`flutter_svg`**: Manejo eficiente de iconos y vectores.

### Infraestructura
* **`firebase_auth`**: Gestión segura de sesiones y usuarios.
* **`provider`**: Inyección de dependencias y gestión de estado (MVVM).