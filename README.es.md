# Shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Motor avanzado de automatización y productividad CLI para Flutter/Dart. Simplifica los flujos de trabajo de desarrollo (clean, deploy, changelog) y une el Design System con las pruebas mediante Atomic Design y Maestro.

## Instalación

O instala globalmente para usar la CLI (Recomendado):

```sh
dart pub global activate shepherd
```

Agrega a tu `pubspec.yaml` para usar como paquete:

```yaml
dependencies:
  shepherd: ^0.8.0
```

## Contribuyendo & Arquitectura

-   [**Guía de Contribución**](CONTRIBUTING.md): Flujo de trabajo, estándares de código y configuración.
-   [**Guía de Arquitectura**](doc/ARCHITECTURE.md): DDD, Clean Architecture y estructura del proyecto.

---

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

---

## Inicio Rápido

Comenzar con Shepherd es fácil, ya sea iniciando un nuevo proyecto o uniéndote a uno existente.

### Inicio Rápido
```sh
# Simplemente ejecuta Shepherd - te guiará a través de la configuración
shepherd
```

Cuando ejecutas Shepherd por primera vez en un proyecto, detecta automáticamente que falta la configuración y presenta opciones:

1.  **Inicializar un nuevo proyecto** - Configurar Shepherd desde cero
2.  **Importar desde proyecto existente** - Importar configuración de un repositorio del equipo

### Modos de Configuración

Si eliges inicializar, seleccionarás un **modo de configuración**:

1.  **Solo Automatización**: Configuración ligera para automatización CI/CD.
    -   Configura: Información del proyecto, ambientes, detalles del usuario
    -   Habilita: comandos `clean`, `changelog`, `deploy`
    -   Omite: Modelado de dominio y gestión de equipo
    
2.  **Configuración Completa**: Gestión completa de proyecto DDD.
    -   Todo del modo Automatización, más:
    -   Registro de dominio y seguimiento de salud
    -   Mapeo de propiedad y responsabilidad del equipo
    -   Menú interactivo para gestión continua

**Resultado**: Genera archivos de configuración (`.shepherd/project.yaml`, `.shepherd/environments.yaml`, etc.)

### Alternativa: Init Directo
```sh
# También puedes ejecutar init directamente
shepherd init
```
**Recomendado para nuevos miembros del equipo.** Este comando sincroniza tu base de datos local con el archivo `devops/domains.yaml` del proyecto, importando todos los dominios y responsables para que estés listo para trabajar inmediatamente.

---

## 1. Automatización & CI/CD

### Limpieza de Proyecto
```sh
# Limpiar todos los proyectos y microfrontends a la vez
shepherd clean

# Limpiar solo el proyecto actual
shepherd clean project
```
Útil para mono-repos donde necesitas ejecutar `flutter clean` en múltiples paquetes.

> **Nota**: Este comando depende de la configuración del proyecto (generada por `shepherd init`) para localizar todos los microfrontends registrados en `microfrontends.yaml`.

### Changelog Automático
```sh
shepherd changelog
```
Gestiona automáticamente tu `CHANGELOG.md` usando dos modos distintos basados en tu rama actual:

1.  **Modo de Generación** (Ramas de Feature):
    -   **Contexto**: Estás trabajando en una feature (ej: `feature/new-login`).
    -   **Acción**: Escanea tus commits que están adelante de `develop`.
    -   **Resultado**: Agrega nuevas entradas a `CHANGELOG.md` bajo una sección "No Lanzado".

2.  **Modo de Actualización** (Ramas de Release/Main):
    -   **Contexto**: Estás en `release` o `main`.
    -   **Acción**: Copia el changelog de la rama de referencia (ej: `develop`).
    -   **Resultado**: Actualiza el encabezado con la versión y fecha actuales.

> **Nota**: El versionado es gestionado por el comando `shepherd deploy`, no por `changelog`.

### Generación de Pruebas Automatizadas
```sh
shepherd test gen
```
Escanea su proyecto en busca de anotaciones `@ShepherdTag` e `ShepherdPageTag` y genera automáticamente flujos de prueba para **Maestro**.
- **Enriquecimiento**: Utiliza datos de `.shepherd/shepherd_activity.yaml` para añadir contexto a los flujos.
- **Resultado**: Os flows se guardan en `.shepherd/maestro/flows/`.

### Generación de Tags
```sh
# Genera clases wrapper de tags a partir de anotaciones
shepherd tag gen
```
Escanea su código en busca de `@ShepherdPageTag` y `@ShepherdTag` para generar clases wrapper tipadas. Asegura que sus claves de UI coincidan con el contrato de interacción definido en las historias de usuario.

### Gestión de Historias y Atomic Design
```sh
# Gestionar Historias de Usuario
shepherd story add <id> <título> <dominio> <descripción>
shepherd story list

# Gestionar Elementos de Diseño (Átomos, Moléculas, etc.)
shepherd element add <storyId> <elementId> <título> <tipo>
shepherd element list

# Gestionar Tareas Ágiles
shepherd task add <storyId> <título>
```
Organice su ciclo de desarrollo con principios de **Atomic Design**. Categorice elementos como `atom`, `molecule`, `organism` o `token` para guiar la generación inteligente de pruebas.

### Pipeline de Deploy
```sh
shepherd deploy
```
Automatiza el flujo completo de release:
-   Actualiza la versión en `pubspec.yaml`
-   Finaliza el `CHANGELOG.md`
-   Crea Pull Requests (con GitHub CLI o Azure CLI)

> **Comportamiento por Rama**:
> -   **develop**: Crea PR para `release`.
> -   **release**: Crea PR para `main`.
> -   **main**: Producción (sin PR).

---

## 3. DDD & Gestión de Proyectos 🚧 _Desarrollo Alpha_

Shepherd te ayuda a mantener una arquitectura limpia gestionando dominios, responsables y verificaciones de salud.

### Análisis de Salud de Dominio
```sh
shepherd analyze
```
Verifica tu proyecto en busca de violaciones arquitecturales, responsables ausentes o problemas de estructura.

### Gestión de Dominio
```sh
# Configurar dominios y responsables interactivamente
shepherd config

# Agregar un responsable a un dominio específico
shepherd add-owner <dominio>
```

### Persistencia
```sh
shepherd export-yaml
```
Exporta todos los dominios y responsables registrados a `devops/domains.yaml`, permitiéndote versionar las configuraciones de estructura de tu proyecto.

---

## Documentación

-   [**Guía de Contribución**](CONTRIBUTING.md): Flujo de trabajo, estándares de código y configuración.
-   [**Guía de Arquitectura**](doc/ARCHITECTURE.md): DDD, Clean Architecture y estructura del proyecto.

## Licencia

MIT © 2026 Vinicius Cruvinel
