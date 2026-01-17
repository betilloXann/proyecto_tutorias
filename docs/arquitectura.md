# Arquitectura de Procesos (Workflow)

El sistema automatiza el ciclo de vida completo de la tutoría de recuperación, transformando un proceso manual fragmentado en un **flujo de trabajo digital continuo**.

## Flujo de Trabajo y Automatización
El siguiente diagrama de actividades modela la naturaleza dinámica del sistema, delimitando las responsabilidades mediante carriles (*swimlanes*) para cada actor: **Gestión Escolar**, **Sistema Automatizado**, **Jefe de Academia** y **Alumno**.

### Puntos Clave del Proceso:
* **Inicialización Automática:** El sistema crea los expedientes digitales en estado "Pendiente" tras la importación masiva.
* **Notificaciones en Tiempo Real:** Se eliminan los avisos manuales; el sistema alerta al alumno inmediatamente después de la asignación.
* **Bucle de Corrección:** Si una evidencia es rechazada por ilegible, el flujo regresa al alumno para su corrección, garantizando que solo se procesen expedientes completos.
* **Cierre Seguro:** Al dictaminar la calificación (Acreditado/No Acreditado), el sistema bloquea el registro para preservar la inmutabilidad del dato.

```mermaid
flowchart TD
%% Definición de Carriles usando Subgrafos
    subgraph Gestion["Gestión Tutorías"]
        Inicio((Inicio))
        Importar[Importar Lista Alumnos]
        Reporte[Generar Reporte Final]
        Fin((Fin del Ciclo))
    end

    subgraph Sistema["Sistema Automatizado"]
        CrearExp[Crear Expedientes 'Pendientes']
        UpdateEnCurso[Update: EN CURSO]
        Notif1[Notificar Asignación]
        RegistrarCalif[Registrar Calificación y Bloquear]
    end

subgraph Jefe["Jefe de Academia"]
Asignar[Asignar Tutor y Horario]
Decision{¿Evidencia Legible?}
Validar[Validar y Calificar]
Rechazar[Rechazar Evidencia]
DecisionCalif{¿Calif >= 6?}
DictAcred[Dictaminar: ACREDITADO]
DictNoAcred[Dictaminar: NO ACREDITADO]
end

subgraph Alumno["Alumno"]
Subir[Subir Evidencia / Acta]
Corregir[Corregir Evidencia]
end

%% Conexiones del Flujo
Inicio --> Importar
Importar --> CrearExp
CrearExp --> Asignar
Asignar --> UpdateEnCurso
UpdateEnCurso --> Notif1
Notif1 --> Subir
Subir --> Decision

Decision -- No --> Rechazar
Rechazar --> Corregir
Corregir --> Subir

Decision -- Si --> Validar
Validar --> DecisionCalif

DecisionCalif -- Si --> DictAcred
DecisionCalif -- No --> DictNoAcred

DictAcred --> RegistrarCalif
DictNoAcred --> RegistrarCalif

RegistrarCalif --> Reporte
Reporte --> Fin
```