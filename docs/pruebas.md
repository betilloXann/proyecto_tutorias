# Estrategia de Pruebas

La calidad del software se asegura mediante pruebas automatizadas que verifican la lógica de negocio antes de cada despliegue. Debido a la arquitectura **MVVM**, nos enfocamos principalmente en **Pruebas Unitarias** de los *ViewModels*, asegurando que la gestión de estado y las reglas de negocio funcionen aisladas de la interfaz gráfica.

## Tecnologías de Testing
* **`flutter_test`**: Framework nativo para ejecución de pruebas unitarias y de widgets.
* **`mockito`**: Librería para simular dependencias externas (como Firebase Auth o Firestore) sin necesidad de un backend real durante los tests.
* **`build_runner`**: Herramienta de generación de código utilizada para crear los archivos de "Mocks" automáticamente.

## Alcance de las Pruebas
Actualmente cubrimos la lógica crítica de los siguientes módulos:

### 1. Autenticación (`LoginViewModel`)
* ✅ Verificar inicio de sesión exitoso con credenciales simuladas.
* ✅ Manejo de errores (contraseña incorrecta, usuario no encontrado).
* ✅ Persistencia de sesión (verificar si el usuario se mantiene logueado).

### 2. Registro (`RegisterViewModel`)
* ✅ Validación de reglas de negocio en formularios (formato de correo institucional, longitud de boleta).
* ✅ Verificación de coincidencia de contraseñas.

### 3. Búsqueda de Estudiantes (`StudentLookupViewModel`)
* ✅ Verificar si un alumno existe en la "White-list" de dictaminados.
* ✅ Manejo de estados de carga (`Loading` → `Success` o `Error`).

## Comandos para Desarrolladores

### Ejecutar todas las pruebas
Para correr la suite completa de pruebas unitarias:
```bash
flutter test
```

### Regenerar Mocks

Si modificas algún repositorio o servicio, necesitas regenerar los mocks para que las pruebas funcionen. Ejecuta:

```bash
dart run build_runner build --delete-conflicting-outputs
```
> **Nota:** Estas pruebas se ejecutan automáticamente en nuestro pipeline de **CI/CD** cada vez que se hace un *Push* o *Pull Request* a las ramas principales.