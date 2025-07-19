# shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Una herramienta y paquete para gestionar proyectos DDD (Domain Driven Design) en Dart/Flutter, con análisis de salud de dominios, automatización de limpieza, exportación YAML e integración CLI.

## Características

- CLI para análisis de salud de los dominios del proyecto
- Comando de limpieza automática para múltiples microfrontends (multi-paquetes)
- Exportación de resultados e historial local
- Exportación de dominios y responsables a YAML versionable
- Gestión de responsables (owners) por dominio
- Puede usarse como package para análisis programático

## Instalación

Agrega a tu `pubspec.yaml` para usar como package:

```yaml
dependencies:
  shepherd: ^0.0.5
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

## Licencia

MIT © 2025 Vinicius Cruvinel

## Soporte de Plataformas

**Atención:** Este paquete está destinado para uso en línea de comandos y escritorio/servidor. No hay soporte para Web debido al uso de `dart:io`.
