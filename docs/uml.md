# Modelado UML del Sistema

En esta sección se formaliza el diseño técnico de la solución mediante el **Lenguaje Unificado de Modelado (UML)**. Estos diagramas representan tanto la estructura estática de la información como el comportamiento dinámico de los procesos críticos.

## Diagrama de Clases
El modelo de clases describe los elementos lógicos que conforman el prototipo. Se han definido entidades clave como `Alumno`, `Dictamen` y `Asignación` para modelar el flujo de la información académica.

Este diseño permite visualizar las relaciones fundamentales del sistema:
* Un **Alumno** posee un único Dictamen activo.
* Un **Dictamen** concentra el historial de evidencias y calificaciones.
* La **Asignación** vincula al alumno con un Profesor específico para la tutoría de recuperación.

```mermaid
classDiagram
    class Alumno {
        +String boleta
        +String nombre
        +String correo
        +iniciarSesion()
        +consultarEstado()
    }

    class Dictamen {
        +int id
        +String archivoPDF
        +String estadoProceso
        +actualizarEstado()
    }

    class Asignacion {
        +Date fecha
        +String horario
        +registrar()
    }

    class Profesor {
        +String nombre
        +String academia
    }

    class Evidencia {
        +String archivo
        +Date fechaSubida
        +String estado
        +validar()
    }

    Alumno "1" *-- "1" Dictamen : tiene
    Dictamen "1" *-- "1" Asignacion : genera
    Asignacion "1" --> "1" Profesor : asignado_a
    Dictamen "1" *-- "0..*" Evidencia : contiene
```

## Diagrama de Secuencia: Validación de Evidencias
Este diagrama detalla el flujo transaccional para la carga y validación del **Acta de Calificación Final**. Representa la interacción temporal entre el Alumno (quien sube la evidencia), el Sistema (que procesa y notifica) y el Jefe de Academia (quien valida).

El proceso destaca por implementar una lógica de "segregación de funciones": el alumno no puede modificar su estatus por sí mismo, y el Jefe de Academia requiere la evidencia digital para poder asentar la calificación.

```mermaid
sequenceDiagram
    autonumber
    actor Alumno
    participant Interfaz as App/Web
    participant Sistema as Backend (Firebase)
    participant BD as Firestore
    actor Jefe as Jefe de Academia

    Note over Alumno, Jefe: Fase de Carga de Evidencia
    Alumno->>Interfaz: Sube Foto Acta Final
    Interfaz->>Sistema: POST /evidencia
    Sistema->>BD: Update estado = "En Revisión"
    Sistema-->>Jefe: Notificación (Nueva Solicitud)

    Note over Alumno, Jefe: Fase de Validación
    Jefe->>Sistema: Consultar evidencias pendientes
    Sistema->>Jefe: Retorna lista y fotos

    alt Evidencia Ilegible
        Jefe->>Sistema: Rechazar Evidencia
        Sistema->>BD: Update estado = "Corrección Requerida"
        Sistema-->>Alumno: Notificar (Volver a subir)
    else Evidencia Correcta
        Jefe->>Sistema: Ingresa Calificación y Firma
        Sistema->>BD: Registrar Calificación
        Sistema->>BD: Update estado = "ACREDITADO"
        Sistema->>BD: Bloquear Registro (Integridad)
        Sistema-->>Alumno: Notificar Resultado Final
    end
```
