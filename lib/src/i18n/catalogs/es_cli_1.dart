// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> esCli1 = {
  'init.repo_type': 'Tipo de repositorio (github/azure{back}): ',
  'init.back_hint': ' (9 para volver al menú principal)',
  'init.repo_type_retry': 'Por favor, escribe "github" o "azure".',
  'init.pr_ask': '¿Habilitar las opciones de Pull Request? (s/N): ',
  'init.pr_retry': 'Responde con "s" para sí o "n" para no.',
  'init.saved':
      'Tipo de repositorio "{type}" y pullRequestEnabled={pr} guardados en .shepherd/config.yaml',
  'install.homebrew': 'Homebrew (shepherd_cli)',
  'install.script': 'script de instalación (curl / PowerShell)',
  'install.studio': 'incluido en Shepherd Studio',
  'install.source': 'código fuente (dart run)',
  'install.unknown': 'no identificado',
  'model.gone':
      'Este modelo ya no está disponible para tu cuenta. Escribe "/model" (o `shepherd ai model`) y elige otro de la lista.',
  'sync.conflict': '❌ ¡Conflicto de sincronización!',
  'sync.newer':
      'La nube tiene información más reciente (nube: {server} > local: {local}).',
  'sync.pull':
      'Ejecuta `git pull` para obtener la última versión antes de volver a ejecutar `shepherd gen`.',
  'update.not_pub': 'esta instalación no es de pub.dev',
  'update.header': 'Shepherd CLI {version} — instalación: {method}',
  'update.no_check':
      'No pude consultar la última versión (¿sin internet?). Inténtalo de nuevo más tarde.',
  'update.up_to_date': '✅ Ya tienes la última versión ({version}).',
  'update.available': '📦 Nueva versión disponible: {current} → {newest}',
  'update.news': '   Novedades: {url}',
  'update.studio':
      'Este CLI viene dentro de Shepherd Studio: actualiza Studio para recibir la nueva versión.',
  'update.source':
      'Estás ejecutando desde el código fuente: actualiza el repositorio (git pull && dart pub get).',
  'update.unknown':
      'No sé cómo se instaló este CLI. Usa el comando que corresponda a tu caso:',
  'update.to_update': 'Para actualizar, ejecuta:',
  'update.brew_lag':
      'Si Homebrew dice que ya está actualizado, la fórmula aún no recibió la {newest}: inténtalo más tarde.',
  'update.running': '⏳ Actualizando...',
  'update.done': '✅ Listo. Abre una nueva terminal para usar la {newest}.',
  'update.failed':
      '❌ La actualización falló (código {code}). Ejecútala manualmente: {command}',
  'update.ask': '\n¿Actualizar ahora? [s/N]: ',
  'clean.home1': '⚠️ Estás en el directorio personal del usuario (~).',
  'clean.home2':
      '👉 Ve a la carpeta de tu proyecto/workspace antes de ejecutar clean (p. ej.: cd dev/mi_proyecto).\n',
  'pr.gh_missing':
      'GitHub CLI (gh) no encontrado. Instálalo desde el menú de herramientas de Shepherd.',
  'pr.az_login':
      'No has iniciado sesión en Azure CLI. El PR se guardará en la base de datos para enviarlo después.',
  'pr.az_saved':
      'PR guardado en la base de datos. Puedes reenviarlo cuando hayas iniciado sesión en Azure.',
  'toggle.exists': 'Ya existe un Feature Toggle con el nombre "{name}".',
  'toggle.not_found': 'Feature toggle no encontrado con id: {id}',
  'cl.start': '🧹 Iniciando Shepherd Clean...\n',
  'cl.ws_project': '📍 Proyecto del workspace detectado: "{name}"',
  'cl.target': '📍 Directorio de destino: {path}\n',
  'cl.target_missing':
      '❌ Directorio o proyecto de destino no encontrado: {arg}\n',
  'cl.current_only': '📍 Limpiando solo el proyecto actual ({path})...',
  'cl.no_pubspec_here':
      '❌ No se encontró ningún pubspec.yaml en el directorio actual ({path}).',
  'cl.manifest':
      '🏢 Manifiesto de workspace detectado: "{name}" ({n} proyectos registrados)',
  'cl.searching': '🔍 Buscando archivos pubspec.yaml de forma segura...',
  'cl.none_found': '❌ No se encontró ningún pubspec.yaml en "{path}".',
  'cl.found': '📦 {n} proyecto(s) para limpiar',
  'cl.cleaning': '--- 🧽 Limpiando: {name} ({path}) ---',
  'cl.rm_lock': '🗑️  pubspec.lock eliminado',
  'cl.rm_lock_fail': '⚠️  No se pudo eliminar pubspec.lock: {e}',
  'cl.rm_build': '🗑️  Directorio build/ eliminado',
  'cl.rm_build_fail': '⚠️  No se pudo eliminar build/: {e}',
  'cl.rm_dart_tool': '🗑️  Directorio .dart_tool/ eliminado',
  'cl.rm_dart_tool_fail': '⚠️  No se pudo eliminar .dart_tool/: {e}',
  'cl.flutter_clean': '🔧 Ejecutando flutter clean...',
  'cl.flutter_clean_ok': '✅ Flutter clean completado',
  'cl.flutter_clean_issues': '⚠️  Flutter clean tuvo problemas: {e}',
  'cl.flutter_clean_fail': '⚠️  No se pudo ejecutar flutter clean: {e}',
  'cl.flutter_get': '📥 Ejecutando flutter pub get...',
  'cl.dart_get': '📥 Ejecutando dart pub get...',
  'cl.deps_ok': '✅ Dependencias restauradas',
  'cl.get_issues': '⚠️  pub get tuvo problemas: {e}',
  'cl.flutter_get_fail': '⚠️  No se pudo ejecutar pub get: {e}',
  'cl.dart_get_fail': '⚠️  No se pudo ejecutar dart pub get: {e}',
  'cl.done': '🎉 ¡Limpieza completada para {n} proyecto(s)!',
  'mcp.none_global':
      'ℹ️  Ningún servidor MCP configurado en el workspace ni globalmente.',
  'mcp.edit': 'Edita el archivo {file} para añadir servidores MCP.',
  'mcp.example': 'Ejemplo:',
  'mcp.configured': '🔌 Servidores MCP configurados ({n}):',
  'mcp.command_label': 'comando',
  'mcp.connecting': '    Conectando y buscando herramientas... ',
  'mcp.ok_tools': '({ms}ms, {n} herramientas)',
  'mcp.failed': 'FALLÓ',
  'mcp.none_file': 'ℹ️  Ningún servidor MCP configurado en .shepherd/mcp.json',
  'mcp.check_title': '🔍 Verificación de conectividad MCP:',
  'mcp.handshake': '  [{name}] Probando el handshake JSON-RPC... ',
  'mcp.online': '({ms}ms | {n} tools disponibles)',
  'mcp.offline': 'OFFLINE / ERROR',
  'mcp.usage': 'Uso:',
  'mcp.usage_call':
      'shepherd mcp call <servidor> <herramienta> [argumentos_json]',
  'mcp.example_call': 'Ejemplo: shepherd mcp call git git_status "{}"',
  'mcp.bad_json': '❌ JSON inválido para los argumentos:',
  'mcp.not_found':
      '❌ Servidor MCP "{name}" no encontrado en .shepherd/mcp.json',
  'mcp.running': '⏳ Ejecutando',
  'mcp.result': 'Resultado:',
  'mcp.help_title': 'Comandos MCP (Model Context Protocol):',
  'mcp.help_list': 'o',
  'mcp.help_list_desc': 'Lista los servidores y herramientas activos',
  'mcp.help_status_desc': 'Prueba la conexión y la latencia de cada servidor',
  'mcp.help_call_desc': 'Ejecuta una herramienta MCP directamente',
};
