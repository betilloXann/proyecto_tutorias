# Arquitectura de Datos y Modelo E-R

El diseño de la base de datos constituye un elemento fundamental para garantizar la **integridad, organización y trazabilidad** de la información del Programa de Tutorías.

## Modelo Entidad-Relación
Para asegurar un almacenamiento estructurado, se ha diseñado un modelo relacional que evita la duplicidad de datos y asegura la consistencia referencial.

Las principales características del modelo son:
1.  **Centralización:** Todas las entidades giran en torno al `Dictamen`, que actúa como el expediente digital único del alumno.
2.  **Trazabilidad:** La entidad `Historial` registra los cambios de estado, permitiendo auditorías futuras.
3.  **Integridad:** Las relaciones (Foreign Keys) aseguran que no existan "asignaciones huérfanas" o evidencias sin un dictamen asociado.

A continuación, se presenta el esquema lógico de las tablas y sus relaciones:

```mermaid
erDiagram
    ALUMNOS ||--|| DICTAMEN : tiene
    DICTAMEN ||--|{ EVIDENCIAS : contiene
    DICTAMEN ||--|{ HISTORIAL : registra
    DICTAMEN ||--|| CALIFICACIONES : obtiene
    DICTAMEN ||--|| ASIGNACIONES : recibe
    ASIGNACIONES }|--|| PROFESORES : asignado_a

    ALUMNOS {
        string boleta PK
        string nombre
        string correo
        string carrera
    }

    DICTAMEN {
        int id_dictamen PK
        string periodo
        string estado_proceso
        string materia
    }

    EVIDENCIAS {
        int id_evidencia PK
        string tipo
        string url_archivo
        datetime fecha_subida
    }

    PROFESORES {
        int id_profesor PK
        string nombre
        string academia
    }
```