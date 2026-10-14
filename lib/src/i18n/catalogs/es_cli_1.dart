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
  'imp.title': '🔄 Importación: Terraform DynamoDB → Shepherd',
  'imp.no_config': '❌ No se encontró ninguna configuración de importación.',
  'imp.run_first': '💡 Ejecuta primero: Configure Import Fields (opción 5)',
  'imp.using_config': '📋 Usando la configuración: {name} (v{version})',
  'imp.fields_n': '📊 {n} campos configurados\n',
  'imp.ask_path': 'Ruta del archivo Terraform (.tf): ',
  'imp.path_required': '❌ La ruta del archivo es obligatoria',
  'imp.not_found': '❌ Archivo no encontrado: {path}',
  'imp.parsing': '\n🔍 Analizando el archivo Terraform (.tf)...',
  'imp.using_yaml':
      '📋 Usando la configuración YAML guardada para mapear los campos...',
  'imp.no_items': '❌ No se encontró ningún item de DynamoDB en el archivo',
  'imp.found': '✅ {n} feature toggles encontrados',
  'imp.confirm': '\n❓ ¿Importar estos {n} feature toggles? (s/n): ',
  'imp.cancelled': '❌ Importación cancelada',
  'imp.importing': '\n📦 Importando feature toggles...',
  'imp.progress': '   📊 {done}/{total} importados...',
  'imp.item_error': '   ⚠️  Error al importar {name}: {error}',
  'imp.result': '\n📊 Resultado de la importación:',
  'imp.ok_count': '✅ Importados con éxito: {n}',
  'imp.err_count': '❌ Errores: {n}',
  'imp.ask_yaml': '\n❓ ¿Exportar a YAML? (s/n): ',
  'imp.exporting': '\n📄 Exportando a YAML...',
  'imp.yaml_updated': '✅ ¡Archivo YAML actualizado!',
  'imp.failed': '❌ Error durante la importación: {error}',
  'imp.config_error': '⚠️  Error al cargar la configuración: {error}',
  'imp.item_proc_error': '⚠️  Error al procesar el item: {error}',
  'imp.required_missing':
      '⚠️  Campo obligatorio "{field}" no encontrado en {resource}',
  'imp.convert_error': '⚠️  Error al convertir {resource}: {error}',
};
