# Shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Una herramienta y paquete para gestionar proyectos DDD (Domain Driven Design) en Dart/Flutter, con análisis de salud de dominios, automatización de limpieza, exportación YAML e integración CLI.

## Funcionalidades

- CLI para análisis de salud de dominios
- Comando de limpieza automática para múltiples microfrontends (multi-paquetes)
- Exportación de resultados e historial local
- Exportación de dominios y responsables a YAML versionable
- Gestión de responsables (owners) por dominio
- Gestión de user stories y tareas, con soporte para vincular historias a uno o más dominios (o global)
- CLI interactiva robusta con color, arte ASCII y usuario activo persistente
- Impide agregar responsables a dominios inexistentes
- Puede usarse como paquete para análisis programático

## Instalación

Agrega a tu `pubspec.yaml` para usar como paquete:

```yaml
dependencies:
  shepherd: ^0.1.0
```

O instala globalmente para usar la CLI:

```sh
dart pub global activate shepherd
```

## Uso de la CLI

### Inicializar un nuevo proyecto (configuración guiada)
```sh
shepherd init
```
Este comando es responsable de la configuración inicial de un proyecto gestionado por Shepherd y normalmente lo ejecuta la persona responsable de la configuración del proyecto. Te guía por el registro de dominios, responsables, tipo de repositorio y todos los metadatos necesarios. Úsalo al iniciar un nuevo proyecto o repositorio.

> **Nota:** Si te unes a un proyecto ya existente (por ejemplo, después de un `git pull`), el proyecto ya estará configurado y tendrás todos los archivos YAML necesarios (como `devops/domains.yaml` y `shepherd_activity.yaml`). En ese caso, **no** ejecutes `shepherd init`. En su lugar, ejecuta:

### Importar configuración del proyecto
```sh
shepherd pull
```
Esto importará todos los dominios, responsables, user stories y tareas de los archivos YAML a tu base de datos local, además de pedirte seleccionar o registrar tu usuario activo. Este es el primer paso recomendado para cualquier desarrollador que se una a un proyecto Shepherd ya configurado.

### Analizar dominios del proyecto
```sh
shepherd analyze
```

### Limpiar todos los proyectos/microfrontends
```sh
shepherd clean
```

### Limpiar solo el proyecto actual
```sh
shepherd clean project
```

### Configurar dominios y responsables (interactivo)
```sh
shepherd config
```

### Agregar responsable a un dominio existente (solo para dominios ya existentes)
```sh
shepherd add-owner <dominio>
```

### Exportar dominios y responsables a YAML versionable
```sh
shepherd export-yaml
# Genera el archivo devops/domains.yaml
```

### Actualizar changelog automáticamente
```sh
shepherd changelog
```

### Ayuda
```sh
shepherd help
```

### Sobre Shepherd
```sh
shepherd about
```
Muestra información del paquete, autor, homepage, repositorio, documentación y licencia en un formato visualmente mejorado. Los enlaces son clicables en terminales compatibles.

### Flujo híbrido: shepherd pull
```sh
shepherd pull
```
Sincroniza tu base de datos local (`shepherd.db`) con el último `devops/domains.yaml` y registro de actividades (`shepherd_activity.yaml`).
- Solicita el usuario activo y valida en el YAML.
- Si el usuario no existe, permite agregar un nuevo responsable de forma interactiva y actualiza el YAML.
- Importa todos los dominios, responsables, user stories y tareas a la base local para una gestión robusta y versionada.
- Garantiza que el usuario activo siempre se guarde en `user_active.yaml` de forma consistente.

## Uso como Paquete

```dart
import 'package:shepherd/shepherd.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'dart:io';

Future<void> main() async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final configService = ConfigService(shepherdDb);
  final infoService = DomainInfoService(shepherdDb);
  final analysisService = AnalysisService();

  // Registrar responsables
  final aliceId = await shepherdDb.insertPerson(
    firstName: 'Alice', lastName: 'Silva', type: 'lead_domain');
  final bobId = await shepherdDb.insertPerson(
    firstName: 'Bob', lastName: 'Souza', type: 'developer');

  // Registrar dominios
  await configService.addDomain('auth_domain', [aliceId, bobId]);

  // Listar dominios
  final domains = await infoService.listDomains();
  print(domains);

  // Analizar dominios
  final results = await analysisService.analyzeProject(projectPath);
  print(results);

  await shepherdDb.close();
}
```

## Ejemplo Completo

Consulta ejemplos completos y didácticos en la carpeta [`example/`](example/shepherd_example.dart).

## Exportación YAML

El comando `shepherd export-yaml` genera el archivo `devops/domains.yaml` con todos los dominios y responsables del proyecto, listo para versionado e integración CI/CD.

## Changelog & Historial Automático

El comando `shepherd changelog` actualiza automáticamente tu `CHANGELOG.md` con la versión y rama actuales. Cuando se detecta una nueva versión, las entradas anteriores se archivan en `dev_tools/changelog_history.md`, manteniendo tu changelog principal limpio y organizado.

- `CHANGELOG.md`: Siempre contiene la versión más reciente y los cambios actuales.
- `dev_tools/changelog_history.md`: Almacena todas las entradas anteriores para referencia histórica.

## Estructura de la Base de Datos shepherd.db

Shepherd utiliza una base SQLite local para almacenar la información del proyecto. Las principales tablas son:

- **pending_prs**: Pull Requests pendientes
  - Columnas: `id`, `repository`, `source_branch`, `target_branch`, `title`, `description`, `work_items`, `reviewers`, `created_at`
- **domain_health**: Historial de salud de dominios
  - Columnas: `id`, `domain_name`, `timestamp`, `health_score`, `commits_since_last_tag`, `days_since_last_tag`, `warnings`, `project_path`
- **persons**: Personas (miembros, responsables, etc)
  - Columnas: `id`, `first_name`, `last_name`, `email`, `type`, `github_username`
- **domain_owners**: Relación entre dominios y personas (responsables)
  - Columnas: `id`, `domain_name`, `project_path`, `person_id`
- **domains**: Dominios registrados
  - Columnas: `name`
- **analysis_log**: Logs de ejecución de análisis
  - Columnas: `id`, `timestamp`, `project_path`, `duration_ms`, `status`, `total_domains`, `unhealthy_domains`, `warnings`
- **stories**: User stories
  - Columnas: `id`, `title`, `description`, `domains`, `status`, `created_by`, `created_at`
- **tasks**: Tareas vinculadas a user stories
  - Columnas: `id`, `story_id`, `title`, `description`, `status`, `assignee`, `created_at`

> La base se crea automáticamente en la primera ejecución de cualquier comando Shepherd que requiera persistencia.

## User Stories & Tareas

Shepherd permite gestionar user stories y sus tareas vía CLI, almacenando todo en el archivo `dev_tools/shepherd/shepherd_activity.yaml`.

- Agrega, lista y vincula user stories a uno o más dominios (separados por coma) o globalmente (deja en blanco).
- Cada user story puede contener varias tareas, con estado, responsable y descripción.
- El menú de stories/tareas puede ser accedido desde el menú de dominios.
- Al crear una user story, la CLI mostrará todos los dominios disponibles y permitirá seleccionar cuáles vincular (o dejar en blanco para TODOS).
- Impide vincular stories a dominios inexistentes.

Ejemplo de estructura YAML generada:

```yaml
- type: "user_story"
  id: "1234"
  title: "Pausar contribuciones"
  description: "El objetivo es pausar contribuciones por la app y el portal RH."
  domains: ["RH"]
  status: "open"
  created_by: "joao"
  created_at: "2025-07-20T16:12:33.249557"
  tasks:
    - id: "2323"
      title: "Implementar botón de pausar"
      description: "Agregar botón en la pantalla principal."
      status: "open"
      assignee: "maria"
      created_at: "2025-07-20T16:21:53.617055"
```

> El archivo se crea automáticamente al agregar la primera user story o tarea.

## Soporte de Plataformas

**Nota:** Este paquete está destinado al uso en línea de comandos y desktop/servidor. No hay soporte para Web debido al uso de `dart:io`.

---

### Mejoras recientes de CLI/UX (0.0.6)

- Todos los menús y prompts ahora soportan cancelar/volver con '9' en cualquier paso.
- Solo es posible agregar owners o user stories a dominios existentes.
- Las user stories pueden vincularse a uno o más dominios, o globalmente.
- La opción 'Init' fue removida del menú principal (ahora solo vía `shepherd init`).
- El usuario activo ahora se muestra y persiste.
- Mejoras de validación, manejo de errores y experiencia de usuario en toda la CLI.
