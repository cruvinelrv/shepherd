# Shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Una herramienta y paquete para gestionar proyectos DDD (Domain Driven Design) en Dart/Flutter, con análisis de salud de dominios, automatización de limpieza, exportación YAML e integración CLI.

## Funcionalidades

## Arquitectura de Dominios Shepherd

Shepherd está organizado en dominios principales, cada uno responsable por una parte del flujo de gestión y automatización:


```
+-------------------+
|     Shepherd      |
+-------------------+
         |
         +-----------------------------+
         |                             |
+--------+--------+         +----------+---------+
|    Dominios     |         |     Funciones      |
+-----------------+         +--------------------+
|                 |         |                    |
|  config         |<------->|  Configuración     |
|  deploy         |<------->|  Despliegue        |
|  init           |<------->|  Inicialización    |
|  domains        |<------->|  Lógica de negocio |
|  menu           |<------->|  Menús & CLI UX    |
|  tools          |<------->|  Utilidades        |
|  sync           |<------->|  Sincronización    |
+-----------------+         +--------------------+
```


**Detalles de los dominios:**

- **config**  - Gestiona configuraciones del proyecto, ambientes, usuarios.
- **deploy**  - Gestiona el flujo de despliegue, PRs, versionado.
- **init**    - Onboarding, creación e inicialización de proyectos.
- **domains** - Lógica de negocio, entidades, casos de uso de dominio.
- **menu**    - Menús, navegación y experiencia de usuario en la CLI.
- **tools**   - Utilidades, helpers, servicios auxiliares.
- **sync**    - Sincronización de datos, import/export, integración con base de datos.

> Los dominios se comunican principalmente a través de la capa de dominio y servicios, manteniendo el código modular y fácil de mantener.


### DOMINIO
- Análisis de salud de dominios (CLI y programático)
- Gestión de responsables por dominio
- Gestión de historias de usuario y tareas, con soporte para vincular historias a uno o más dominios (o global)
- Impide agregar responsables o historias a dominios inexistentes
- Listar, vincular y analizar dominios y su salud
- Soporte nativo para proyectos con múltiples microfrontends (repositorios multi-paquete)
- Cada microfrontend puede tener su propio `pubspec.yaml` y versionado, gestionado vía `microfrontends.yaml`
- Los flujos de deploy y versionado detectan y actualizan solo los microfrontends relevantes, con opción de también actualizar el `pubspec.yaml` raíz
- Los comandos de la CLI proporcionan retroalimentación clara sobre qué microfrontends fueron actualizados
- Los flujos de onboarding y configuración guían el registro y gestión de microfrontends
- Gestión centralizada de feature toggles por dominio, almacenados en `feature_toggles.yaml`
- Sincronización entre el YAML de feature toggles y la base de datos local para consistencia
- Comandos de la CLI para regenerar, validar y exportar feature toggles de cada dominio
- Garantiza control robusto y visibilidad de features habilitadas/deshabilitadas en todos los dominios y microfrontends

### HERRAMIENTAS
- CLI interactivo robusto con color, arte ASCII y usuario activo persistente
- Puede usarse como paquete para análisis programático
- Comandos de ayuda y acerca de
- Comando de limpieza automática para múltiples microfrontends (multi-paquetes)

### DEPLOY
- Exportación de dominios y responsables a YAML versionable
- Exportación de resultados e historial local
- Exportación YAML para integración CI/CD
- Comandos de changelog (gestión automática de changelog e historial)
- Creación de Pull Request con integración GitHub CLI y Azure CLI (próximamente)

### CONFIG
- Configuración interactiva de dominios y responsables
- Importación/exportación de configuración del proyecto desde YAML
- Usuario activo y configuración persistentes

## Instalación

Agrega a tu `pubspec.yaml` para usar como paquete:

```yaml
dependencies:
  shepherd: ^0.4.0
```

O instala globalmente para usar la CLI:

```sh
dart pub global activate shepherd
```

## Uso (CLI - Recomendado)

La CLI es la forma principal y recomendada de usar Shepherd. Ofrece una experiencia robusta e interactiva para la gestión de proyectos, análisis y automatización.

### Inicializar un nuevo proyecto (configuración guiada)
```sh
shepherd init
```
Este comando realiza la configuración inicial de un proyecto gestionado por Shepherd y normalmente lo ejecuta la persona responsable de la configuración. Te guía en el registro de dominios, responsables, tipo de repositorio y todos los metadatos requeridos. Úsalo al iniciar un nuevo proyecto o repositorio.

> **Nota:** Si te unes a un proyecto existente (por ejemplo, después de un `git pull`), el proyecto ya estará configurado y tendrás todos los archivos YAML necesarios (como `devops/domains.yaml` y `shepherd_activity.yaml`). En este caso, **no** necesitas ejecutar `shepherd init`. Simplemente ejecuta:

### Importar configuración del proyecto
```sh
shepherd pull
```
Esto importará todos los dominios, responsables, historias de usuario y tareas de los archivos YAML a la base de datos local, y te pedirá seleccionar o registrar tu usuario activo. Este es el primer paso recomendado para cualquier desarrollador que se una a un proyecto Shepherd ya configurado.

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

### Agregar responsable a un dominio existente (solo para dominios existentes)
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

### Acerca de Shepherd
```sh
shepherd about
```
Muestra información del paquete, autor, página principal, repositorio, documentación y licencia en un formato visualmente mejorado. Los enlaces son clicables en terminales compatibles.

### Flujo híbrido: shepherd pull
```sh
shepherd pull
```
Sincroniza tu base de datos local (`shepherd.db`) con el último `devops/domains.yaml` y registro de actividades (`shepherd_activity.yaml`).
- Solicita el usuario activo y valida en el YAML
- Si el usuario no existe, permite agregar un nuevo responsable de forma interactiva y actualiza el YAML
- Importa todos los dominios, responsables, historias de usuario y tareas a la base local para una gestión robusta y versionada
- Garantiza que el usuario activo siempre se guarde en `user_active.yaml` en un formato consistente

### Realizar despliegue del proyecto
```sh
shepherd deploy
```
Ejecuta el flujo completo de despliegue: cambio de versión, generación automática del changelog, creación de Pull Request e integración con herramientas externas (GitHub CLI, Azure CLI).

## Ejemplo Completo

Consulta ejemplos completos y didácticos en la carpeta [`example/`](example/shepherd_example.dart).

## Exportación YAML

El comando `shepherd export-yaml` genera el archivo `devops/domains.yaml` con todos los dominios y responsables del proyecto, listo para versionado e integración CI/CD.

## Changelog & Historial Automático

El comando `shepherd changelog` actualiza automáticamente tu `CHANGELOG.md` con la versión y rama actuales. Cuando se detecta una nueva versión, las entradas anteriores se archivan en `dev_tools/changelog_history.md`, manteniendo tu changelog principal limpio y organizado.

- `CHANGELOG.md`: Siempre contiene la versión más reciente y los cambios actuales.
- `dev_tools/changelog_history.md`: Almacena todas las entradas anteriores para referencia histórica.

## Estructura de la base shepherd.db

Shepherd utiliza una base de datos SQLite local para almacenar información del proyecto. Las principales tablas son:

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
- **stories**: Historias de usuario
  - Columnas: `id`, `title`, `description`, `domains`, `status`, `created_by`, `created_at`
- **tasks**: Tareas vinculadas a historias
  - Columnas: `id`, `story_id`, `title`, `description`, `status`, `assignee`, `created_at`

> La base se crea automáticamente en la primera ejecución de cualquier comando Shepherd que requiera persistencia.

## Historias de Usuario & Tareas

Shepherd permite gestionar historias de usuario y tareas vía CLI, almacenando todo en el archivo `.shepherd/shepherd_activity.yaml`.

- Agrega, lista y vincula historias a uno o más dominios (separados por coma) o globalmente (deja en blanco)
- Cada historia puede contener varias tareas, con estado, responsable y descripción
- El menú de historias/tareas puede ser accedido desde el menú de dominios
- Al crear una historia, la CLI mostrará todos los dominios disponibles para seleccionar (o deja en blanco para TODOS)
- Impide vincular historias a dominios inexistentes

Ejemplo de estructura YAML generada:

```yaml
- type: "user_story"
  id: "1234"
  title: "Pausar contribuciones"
  description: "El objetivo es pausar contribuciones vía la app y el portal de RRHH."
  domains: ["RRHH"]
  status: "open"
  created_by: "joao"
  created_at: "2025-07-20T16:12:33.249557"
  tasks:
    - id: "2323"
      title: "Implementar botón de pausa"
      description: "Agregar botón en la pantalla principal."
      status: "open"
      assignee: "maria"
      created_at: "2025-07-20T16:21:53.617055"
```

> El archivo se crea automáticamente al agregar la primera historia o tarea.

## Soporte de Plataformas

**Nota:** Este paquete está destinado al uso en línea de comandos y escritorio/servidor. La plataforma web no es compatible debido al uso de `dart:io`.

---

### Mejoras recientes en la CLI/UX (0.0.6)

- Todos los menús y prompts ahora soportan cancelar/volver con '9' en cualquier paso
- Solo los dominios existentes pueden tener responsables o historias vinculadas
- Las historias pueden vincularse a uno o más dominios, o globalmente
- La opción 'Init' fue removida del menú principal (ahora solo vía `shepherd init`)
- El usuario activo ahora se muestra y persiste
- Mejoras en la validación, manejo de errores y experiencia de usuario en toda la CLI

---

## Uso como Paquete (No Recomendado, pero Posible)

> **Nota:** Shepherd está diseñado y mantenido principalmente como una herramienta CLI para gestión, análisis y automatización de proyectos. El uso directo como paquete Dart es posible, pero no recomendado y puede no ser soportado en versiones futuras. Para mejores resultados y soporte completo de funcionalidades, utiliza siempre la CLI de Shepherd.

Si aún quieres experimentar con la API del paquete, consulta el ejemplo a continuación (no oficialmente soportado):

```dart
// Ejemplo solo. El uso vía CLI es fuertemente recomendado.
import 'package:shepherd/shepherd.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'dart:io';

Future<void> main() async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final configService = ConfigService(DomainsDatabase(projectPath));
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

## Licencia

MIT © 2025 Vinicius Cruvinel
