# Guía de Instalación y Configuración

Sigue estos pasos para configurar el entorno de desarrollo local y ejecutar el proyecto **Proyecto Tutorías**.

## Prerrequisitos

Antes de comenzar, asegúrate de tener instalado el siguiente software:

* **Flutter SDK:** Versión **3.35.5** (Requerida por nuestro CI).
* **Dart SDK:** Viene incluido con Flutter (Compatible con `^3.1.0`).
* **Git:** Para clonar el repositorio.
* **IDE:** Visual Studio Code (recomendado) o Android Studio.
* **Navegador:** Chrome o Edge (para depuración Web).

## Pasos de Instalación

### 1. Clonar el Repositorio
Abre tu terminal y ejecuta:

```bash
git clone https://github.com/betilloXann/proyecto_tutorias.git
cd proyecto_tutorias
```

## 2. Instalar Dependencias

Descarga las librerías necesarias listadas en `pubspec.yaml`:

```bash
flutter pub get
```

---

## 3. Configuración de Entorno (Firebase)

El proyecto utiliza servicios de **Firebase**. Verifica que los archivos de configuración estén correctamente ubicados:

* **Android**
  El archivo `google-services.json` debe existir en:
  `android/app/`

* **iOS**
  El archivo `GoogleService-Info.plist` debe existir en:
  `ios/Runner/`

* **Dart**
  La configuración global se encuentra en:
  `lib/firebase_options.dart`

> **Nota:**
> Si estos archivos no están presentes (por reglas de `.gitignore`), solicítalos al administrador del proyecto (**betilloxann**).

---

## Ejecución del Proyecto

### Modo Desarrollo (Móvil)

Conecta tu dispositivo Android o inicia un emulador y ejecuta:

```bash
flutter run
```

### Modo Desarrollo (Web)

Para levantar la versión administrativa en el navegador:

```bash
flutter run -d chrome
```

---

## Generación de Ejecutables (Build)

Si necesitas generar los archivos para producción manualmente
*(aunque el CI lo hace automáticamente)*:

### Android APK

```bash
flutter build apk --release
```

El archivo se generará en:

```
build/app/outputs/flutter-apk/app-release.apk
```

### Web (Para Vercel)

```bash
flutter build web --release --base-href /
```

Los archivos estáticos se generarán en:

```
build/web/
```

---

## Solución de Problemas Comunes

### Error de Versión de Java

Este proyecto requiere una versión de Java compatible con **Gradle**.

* Asegúrate de usar **Java 11 o superior**
* O configura la ruta de Java en:

  ```
  android/gradle.properties
  ```
---

## Estándar de Commits (Git Emoji)
Utilizamos **Gitmoji** para categorizar los commits visualmente. Esto facilita la lectura del historial y la generación de changelogs.

| Emoji | Código | Significado | Ejemplo de Uso |
| :--- | :--- | :--- | :--- |
| ✨ | `:sparkles:` | **Nueva funcionalidad** (Feature) | `✨ Add: Pantalla de carga de evidencias` |
| 🐛 | `:bug:` | **Corrección de error** (Bugfix) | `🐛 Fix: Error al validar fecha en reporte` |
| ♻️ | `:recycle:` | **Refactorización** | `♻️ Refactor: Mover lógica de auth a repositorio` |
| 💄 | `:lipstick:` | **Cambios visuales/UI** | `💄 UI: Mejorar colores del dashboard` |
| 📝 | `:memo:` | **Documentación** | `📝 Docs: Actualizar diagrama de clases` |
| 🔧 | `:wrench:` | **Configuración** | `🔧 Config: Actualizar versión de Gradle` |
| 🚀 | `:rocket:` | **Despliegue** | `🚀 Deploy: Publicar versión 1.0 a producción` |
| 🚧 | `:construction:`| **Trabajo en progreso** | `🚧 WIP: Implementando validación de formulario` |

