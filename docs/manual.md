# Manual de Usuario

Bienvenido a la guía de operación del **Sistema de Gestión de Tutorías**. Este manual está dividido por los roles de usuario definidos en el sistema.

## Perfil: Alumno
El alumno es el responsable de evidenciar su actividad académica.

### 1. Iniciar Sesión
* Ingresa con tu **Boleta** y contraseña.
* Si es tu primera vez, utiliza la opción **"Validar Cuenta"** para verificar que estás en la lista de dictaminados.

### 2. Consultar Asignación
Una vez que el Jefe de Academia te asigne un tutor, verás en tu pantalla de inicio:
* Nombre del Profesor.
* Materia (Unidad de Aprendizaje).
* Horario de atención.
* Estado actual: `EN_CURSO`.

### 3. Subir Evidencias (Bitácora)
Para justificar tu asistencia mensual:
1.  Ve a la sección **"Mis Evidencias"**.
2.  Presiona el botón **(+) Subir Evidencia**.
3.  Selecciona la foto o PDF de tu reporte firmado.
4.  El estado cambiará a `EN_REVISIÓN`.

> **Importante:** Si recibes una notificación de **"Evidencia Rechazada"**, debes entrar, ver el comentario del Jefe de Academia y volver a subir el archivo corregido.

### 4. Cierre de Semestre
Al finalizar, debes subir una foto clara de tu **Acta de Calificación** firmada. Esto iniciará el proceso de acreditación final.

---

##  Perfil: Jefe de Academia
Encargado de la gestión operativa y validación.

### 1. Asignar Tutor
1.  En el **Dashboard**, selecciona "Alumnos Pendientes".
2.  Elige un alumno y presiona **"Formalizar Asignación"**.
3.  Selecciona el Tutor del catálogo y define el horario.
4.  Al guardar, el alumno será notificado automáticamente.

### 2. Validar Evidencias
Cuando un alumno sube un archivo, aparecerá en tu bandeja de entrada.
* **Aprobar:** Si el documento es legible y válido.
* **Rechazar:** Si hay errores. Debes escribir una observación para el alumno.

### 3. Asentar Calificación Final
Al recibir el Acta Final del alumno:
1.  Verifica la firma y la nota.
2.  Ingresa la calificación numérica (6-10) en el sistema.
3.  El sistema dictaminará automáticamente: `ACREDITADO` o `NO_ACREDITADO`.
4.  **Nota:** Esta acción bloquea el expediente permanentemente.

---

## Perfil: Coordinación de Tutorías
Administrador general del ciclo.

### 1. Importación Masiva (Inicio de Semestre)
1.  Ve a **Configuración > Importar Alumnos**.
2.  Carga el archivo Excel/CSV provisto por Gestión Escolar.
3.  El sistema creará los expedientes en estado `PENDIENTE`.

### 2. Generar Reportes
Para entregar resultados a Gestión Escolar:
1.  Ve a la sección **Reportes**.
2.  Selecciona el semestre actual.
3.  Descarga el **Reporte Consolidado (PDF/Excel)**.