# shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Una herramienta y paquete para gestionar proyectos DDD (Domain Driven Design) en Dart/Flutter, con análisis de salud de dominios, automatización de limpieza, exportación YAML e integración CLI.

## Características

- CLI para análisis de salud de los dominios del proyecto
- Comando de limpieza automática para múltiples microfrontends (multi-paquetes)
- Exportación de resultados e historial local
- Exportación de dominios y responsables a YAML versionable
- Gestión de responsables (owners) por dominio
- Gestión de user stories y tasks, con soporte para vincular historias a uno o más dominios (o global)
- CLI interactiva robusta con colores, ASCII art y usuario activo persistente
- Impide agregar owners a dominios inexistentes
- Puede usarse como package para análisis programático

## Instalación

Agrega a tu `pubspec.yaml` para usar como package:

```yaml
dependencies:
  shepherd: ^0.0.8
```

O instala globalmente para usar la CLI:

```sh
dart pub global activate shepherd
```

## Uso por CLI

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

### Agregar responsable a un dominio existente
```sh
shepherd add-owner <dominio>
```
*Solo para dominios ya registrados*
### Inicializar un nuevo proyecto (setup guiado)
```sh
shepherd init
```
Este comando te guía por la configuración inicial del proyecto, permitiendo:
- Registrar dominios (con validación y prevención de duplicados)
- Agregar responsables (con email y usuario de GitHub)
- Definir el tipo de repositorio (GitHub o Azure)
- Configurar metadatos iniciales del proyecto
- Preparar todos los archivos y base de datos necesarios para usar Shepherd
- Cancelar/volver al menú principal en cualquier prompt digitando 9

### Exportar dominios y responsables a YAML versionable
```sh
shepherd export-yaml
# Genera el archivo devops/domains.yaml
```

### Actualizar el changelog automáticamente
```sh
shepherd changelog
```

### Ayuda
```sh
shepherd help
```

## Uso como Package

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

El comando `shepherd export-yaml` genera un archivo `devops/domains.yaml` con todos los dominios y responsables del proyecto, listo para versionar e integrar con CI/CD.

## Changelog Automático & Histórico

El comando `shepherd changelog` actualiza automáticamente tu `CHANGELOG.md` con la versión y rama actual. Cuando se detecta una nueva versión, las entradas anteriores del changelog se archivan en `dev_tools/changelog_history.md`, manteniendo el changelog principal limpio y organizado.

- `CHANGELOG.md`: Siempre contiene la versión más reciente y los cambios actuales.
- `dev_tools/changelog_history.md`: Guarda todas las entradas antiguas del changelog para referencia histórica.

## User Stories y Tasks
Shepherd permite gestionar user stories y sus tasks por la CLI, guardando todo en el archivo `dev_tools/shepherd/shepherd_activity.yaml`.

- Agrega, lista y vincula user stories a uno o más dominios (separados por coma) o de forma global (deja en blanco).
- Cada user story puede contener varias tasks, con estado, responsable y descripción.
- El menú de historias/tasks se puede acceder desde el menú de dominios.
- Al crear una user story, la CLI muestra todos los dominios disponibles y permite seleccionar a cuáles vincular (o dejar en blanco para TODOS).
- Impide vincular historias a dominios inexistentes.

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
      title: "Implementar botón de pausa"
      description: "Agregar botón en la pantalla principal."
      status: "open"
      assignee: "maria"
      created_at: "2025-07-20T16:21:53.617055"
```

> El archivo se crea automáticamente al agregar la primera user story o task.

## Licencia

MIT © 2025 Vinicius Cruvinel

## Soporte de Plataformas

**Atención:** Este paquete está destinado para uso en línea de comandos y escritorio/servidor. No hay soporte para Web debido al uso de `dart:io`.

---

### Mejoras recientes de CLI/UX (0.0.6)

- Todos los menús y prompts ahora soportan cancelar/volver con '9' en cualquier paso.
- Solo es posible agregar owners o user stories a dominios existentes.
- Las user stories pueden vincularse a uno o más dominios, o globalmente.
- La opción 'Init' fue removida del menú principal (ahora solo vía `shepherd init`).
- El usuario activo ahora se muestra y persiste.
- Mejoras de validación, manejo de errores y experiencia de usuario en toda la CLI.
