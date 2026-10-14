// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> esAi2 = {
  'installer.downloading': 'Descargando el motor de IA {version}...',
  'installer.feed_status': 'El servidor de actualizaciones respondió {status}.',
  'installer.bad_signature':
      'La firma de la lista de versiones del motor no coincide. No se instaló nada.',
  'installer.bad_feed': 'Lista de versiones no válida: {detail}',
  'installer.download_status': 'No se pudo descargar el motor ({status}).',
  'installer.bad_hash':
      'El archivo descargado no coincide con el hash de la lista firmada. No se instaló nada.',
  'installer.server_status': 'El servidor respondió {status}.',
  'installer.retrying': 'Conexión inestable, reintentando ({i}/{max})...',
  'installer.no_binary': 'El paquete del motor no incluye {exe}.',
  'rpc.engine_exited': 'El motor de IA se detuvo inesperadamente.',
  'help.projects':
      'Limita el contexto (y los archivos que la IA puede cambiar) a estos proyectos, carpetas en la raíz del workspace. Vacío = todo el workspace.',
  'help.model': 'Modelo de IA (p. ej.: gemini-3.8-flash, gpt-4o, llama3.1).',
  'help.provider': 'Proveedor de IA: gemini, openai, anthropic u ollama.',
  'help.mode':
      'fast (pregunta antes de escribir), plan (solo planifica) o auto (escribe directamente).',
  'help.plan': 'Atajo de --mode plan.',
  'help.auto': 'Atajo de --mode auto.',
  'help.rag':
      'Activa o desactiva el contexto del workspace (activado por defecto).',
  'help.file': 'Adjunta el contenido de archivos locales a la pregunta.',
  'help.profile': 'Perfil de modelo: advanced, medium o local.',
  'help.local': 'Usa el perfil de modelo local.',
  'help.engine_path':
      'Muestra dónde está el motor de IA (instalándolo si falta).',
  'help.update_engine': 'Busca ahora una versión nueva del motor de IA.',
  'help.config_sync': 'Sincroniza el catálogo de modelos en línea.',
  'launcher.usage':
      'Uso: shepherd ai ["tu pregunta"] [-m modelo] [-p proveedor] [--plan|--auto] [--projects a,b] [-f archivo]\n     shepherd ai config [--sync]\n     shepherd ai model [nombre_del_modelo]\n     shepherd ai --engine-path | --update-engine',
  'launcher.bad_args': '❌ Error: {e}\n{usage}',
  'launcher.login_required':
      '❌ Inicia sesión para usar Shepherd AI: `shepherd login`.',
  'launcher.file_not_found': '⚠️  Archivo no encontrado: {path}',
  'opt.name_local': 'Local (Ollama)',
  'opt.local':
      'Elegir modelo de Ollama [RAG activo / Costo cero] (Actual: {model}{lan})',
  'opt.openai': '{model} [Económico / Nube]',
  'opt.anthropic': '{model} [Razonamiento / Nube]',
  'opt.gemini': '{model} [Rápido / Nube]',
  'opt.opencode':
      'Elegir modelo [qwen, deepseek, claude, gpt...] (Actual: {model})',
  'opt.name_lan': 'Servidor local (LAN)',
  'opt.lan': '{model} [RAG activo / LAN] ({url})',
  'dn.gemini': 'Google Gemini (Directo)',
  'dn.openai': 'OpenAI (Directo)',
  'dn.anthropic': 'Anthropic Claude (Directo)',
  'dn.opencode': 'OpenCode Zen (opencode.ai)',
  'dn.ollama': 'Ollama (Local / Red local)',
  'dn.lan': 'Servidor local / Red local',
  'models.menu_prompt':
      'Elige una opción [1-{n}] o escribe el nombre del modelo (o Enter para cancelar): ',
  'models.title': '🤖 Shepherd AI — Cambiar de modelo / proveedor',
  'models.current': 'Modelo actual: {model} ({provider})\n',
  'models.options': 'Opciones disponibles:',
  'models.active': '★ (Activo)',
  'models.cancelled': 'ℹ️  Operación cancelada.\n',
  'models.unknown':
      '❌ Opción o modelo no reconocido. Escribe "shepherd ai model" para ver la lista.\n',
  'models.default_set':
      '✅ Modelo predeterminado actualizado a: {model} ({provider})\n',
  'picker.fetching': '🔍 Buscando modelos en {provider}... ',
  'picker.default_list': 'usando la lista predeterminada.',
  'picker.n_models': '{n} modelo(s).',
  'picker.no_key':
      'ℹ️  Sin clave de API para {provider} (usa `shepherd ai config`); se muestra la lista predeterminada.\n',
  'picker.title': 'Modelos de {provider}:',
  'picker.type_name': '  [m] ✍️ Escribir el nombre de otro modelo',
  'picker.choose': 'Elige [1-{n}] o [m] (Enter para mantener "{model}"): ',
  'picker.model_name': 'Nombre del modelo: ',
  'picker.no_option': 'ℹ️  La opción {n} no existe; se mantiene: {model}.',
  'notice.usage':
      'ℹ️  Informe de uso: Shepherd AI envía a la cuenta Shepherd de tu empresa números de uso (proveedor, modelo, tokens y duración) para que pueda seguir cómo se usa la IA. Nunca se envían preguntas, respuestas, nombres de archivo ni código. Para desactivarlo, usa `telemetry: false` en .shepherd/ai_config.yaml. Este aviso aparece una sola vez.',
  'diff.new_file': '(archivo nuevo)',
  'diff.modification': '(modificación)',
  'diff.more_lines': '  ... {n} líneas más',
  'diff.too_big':
      '  (archivo demasiado grande para comparar línea a línea: {old} → {new} líneas)',
  'diff.no_changes': '  (sin diferencias)',
  'diff.continues': '  ... (la diferencia continúa)',
  'ollama.fetching':
      '\n🔍 Buscando los modelos disponibles en Ollama ({url})... ',
  'ollama.detected': '¡{n} modelo(s) detectado(s)!',
  'ollama.offline': 'Ollama está sin conexión o inaccesible en {url}.',
  'ollama.lan_tip':
      '💡 ¿Está en otra máquina de la red? Escribe {key} para definir IP/puerto.\n',
  'ollama.models_title': 'Modelos disponibles en tu Ollama:',
  'ollama.change_url':
      '  [u] 🌐 Cambiar la IP / URL de Ollama en la red (actual: {url})',
  'ollama.choose':
      'Elige un modelo [1-{n}], [u] para IP/URL (Enter para mantener "{model}"): ',
  'ollama.ask_url':
      '\nEscribe la IP o el nombre de host de Ollama en la red (p. ej.: http://192.168.1.50:11434) [{url}]: ',
  'ollama.url_updated': '✅ Dirección de Ollama actualizada a: {url}',
  'opencode.setup_title': 'Configuración de OpenCode Zen (opencode.ai)',
  'opencode.intro':
      'OpenCode Zen da acceso a muchos modelos de primer nivel con una sola clave de API.',
  'opencode.get_key':
      'Obtén tu clave en: https://opencode.ai o https://opencode.ai/zen\n',
  'opencode.ask_key':
      'Escribe tu clave de API de OpenCode (o Enter para cancelar): ',
  'opencode.cancelled': 'ℹ️  Configuración cancelada.\n',
  'opencode.key_saved':
      '✅ Clave de API de OpenCode guardada en .shepherd/ai_config.yaml!\n',
  'opencode.fetching':
      '🔍 Buscando el catálogo de modelos en OpenCode Zen ({url})... ',
  'opencode.n_models': '¡{n} modelo(s) disponible(s)!\n',
  'opencode.default_catalog':
      'Usando el catálogo predeterminado de OpenCode Zen.\n',
  'opencode.models_title': 'Modelos disponibles en OpenCode Zen:',
  'opencode.update_key': '  [k] 🔑 Actualizar la clave de API de OpenCode',
  'opencode.type_model': '  [m] ✍️ Escribir a mano otro nombre de modelo',
  'opencode.choose':
      'Elige una opción [1-{n}], [k] clave, [m] otro (Enter para mantener "{model}"): ',
  'opencode.new_key': '\nEscribe la nueva clave de API de OpenCode: ',
  'opencode.key_updated': '✅ ¡Clave de API actualizada con éxito!\n',
  'opencode.ask_model':
      '\nEscribe el ID del modelo en OpenCode (p. ej.: deepseek-v4-pro, qwen3.8-max): ',
};
