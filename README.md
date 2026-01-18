<div style="text-align: center;">
  <img src="assets/images/app_icon.png" alt="Logo" width="80" />

  <h1>Sistema de Acompañamiento Tutorial</h1>

  <p>
    <strong>Centralización, Trazabilidad y Gestión Digital para Tutorías de Recuperación en UPIICSA</strong>
  </p>

  <a href="https://github.com/betilloxann/proyecto_tutorias/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/betilloxann/proyecto_tutorias/flutter_ci.yml?label=Build&style=for-the-badge&logo=github" alt="CI Status"/>
  </a>
  <a href="https://github.com/betilloxann/proyecto_tutorias/releases">
    <img src="https://img.shields.io/github/v/release/betilloxann/proyecto_tutorias?style=for-the-badge&label=Versión&color=blue" alt="Latest Release"/>
  </a>
  <a href="https://proyecto-tutorias.vercel.app/">
    <img src="https://img.shields.io/badge/Demo_Web-Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white" alt="Vercel Deploy"/>
  </a>
  <br/>
  <br/>

  <img src="assets/images/hero_mockup.png" width="100%" alt="Vista General del Sistema SAT" />

  <br/>
  <br/>

  <a href="https://github.com/betilloxann/proyecto_tutorias/releases/latest/download/app-release.apk">
    <img src="https://img.shields.io/badge/📲_Descargar_APK_Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" height="45" />
  </a>
  &nbsp;&nbsp;
  <a href="https://betilloxann.github.io/proyecto_tutorias/">
    <img src="https://img.shields.io/badge/📚_Leer_Documentación-MKDocs-526CFE?style=for-the-badge&logo=materialformkdocs&logoColor=white" height="45" />
  </a>
</div>

<br/>

---

## Acerca del Proyecto

El **Sistema de Acompañamiento Tutorial (SAT)** es una solución multiplataforma (Móvil y Web) desarrollada para optimizar el **Programa Institucional de Tutorías (PIT)**.

El sistema resuelve la problemática de la dispersión de información mediante un expediente digital centralizado, permitiendo:
* **Alumnos:** Subir evidencias fotográficas y consultar su estatus en tiempo real.
* **Tutores/Jefes:** Validar documentos y asignar calificaciones digitalmente.
* **Coordinación:** Generar reportes consolidados para Gestión Escolar.

---

## Galería del Proyecto
|                      Inicio Tutorías                       |                    Gestión de Alumnos                    |                             Gestión del Alumno                             |
|:----------------------------------------------------------:|:--------------------------------------------------------:|:--------------------------------------------------------------------------:|
| <img src="assets/images/mockup_inicio.jpeg" width="220" /> | <img src="assets/images/mockup_home.jpeg" width="200" /> |         <img src="assets/images/mockup_alumno.jpeg" width="200" />         |
|               *Inicio del usuario Tutorías*                |           *Dashboard con semáforo de estatus*            | *Perfil que ven Tutorías y Academias para ver estado de alumno específico* |
---

## Stack Tecnológico

Este proyecto implementa una arquitectura moderna y escalable:

| Categoría | Tecnologías |
| :--- | :--- |
| **Frontend Móvil** | ![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white) **3.35.5** |
| **Backend (BaaS)** | ![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=flat&logo=firebase) (Auth, Firestore, Storage) |
| **CI/CD** | ![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=flat&logo=githubactions&logoColor=white) & ![Vercel](https://img.shields.io/badge/vercel-%23000000.svg?style=flat&logo=vercel&logoColor=white) |
| **Documentación** | ![MkDocs](https://img.shields.io/badge/mkdocs-%23526CFE.svg?style=flat&logo=materialformkdocs&logoColor=white) |

---

## Instalación Local

Si deseas clonar y ejecutar el proyecto en tu entorno de desarrollo:

1.  **Prerrequisitos:** Flutter SDK 3.35.5, Java 11.
2.  **Clonar:**
    ```bash
    git clone https://github.com/betilloXann/proyecto_tutorias.git
    cd proyecto_tutorias
    ```
3.  **Configuración:**
    * Necesitas el archivo `google-services.json` (Android) y `GoogleService-Info.plist` (iOS).
    * Colócalos en sus carpetas respectivas (`android/app/` y `ios/Runner/`).
4.  **Ejecutar:**
    ```bash
    flutter pub get
    flutter run
    ```
---

<div style="text-align: center;">
  <p>Desarrollado con ❤️ por el equipo de Ingeniería Informática - UPIICSA IPN</p>
</div>