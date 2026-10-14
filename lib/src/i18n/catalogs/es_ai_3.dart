// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> esAi3 = {
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
  'render.phase_indexing': 'indexando el workspace',
  'render.phase_searching': 'buscando contexto',
  'render.phase_writing': 'escribiendo',
  'render.phase_thinking': 'pensando',
  'render.phase_waiting': 'esperando al modelo',
  'render.trimmed':
      '✂️  {n} mensaje(s) antiguo(s) quedaron fuera del contexto para caber en la ventana del modelo.',
  'render.preparing': '📄 preparando {path}...',
  'render.written': '✅ {path} escrito',
  'render.write_failed': '❌ no se pudo escribir {path}',
  'render.blocked': '🚫 {path} no se propuso: {reason}',
  'render.indexed': '🧠 {project}: {n} archivo(s) en el índice',
  'render.context_ready': '🧠 Contexto listo ({backend})',
  'render.pruned': ' · {n} índice(s) antiguo(s) eliminado(s)',
  'render.context_chunks': '📎 {n} fragmento(s) del workspace en el contexto',
  'render.rag_unavailable':
      '⚠️  Contexto del workspace no disponible: {message}',
  'err.session_expired':
      'Tu sesión expiró. Ejecuta `shepherd login` e inténtalo de nuevo.',
  'err.login_required':
      'Inicia sesión para usar Shepherd AI: `shepherd login`.',
  'err.not_configured':
      'Ningún proveedor de IA configurado. Ejecuta `shepherd ai config`. ({detail})',
  'err.ollama_offline':
      'El servidor de Ollama no respondió. Abre Ollama (o ajusta su dirección con `shepherd ai config`).',
  'err.invalid_key':
      'El proveedor rechazó la clave de API. Actualízala con `shepherd ai config`.',
  'err.model_unavailable':
      'El modelo {model} no está disponible para tu cuenta. Elige otro con /model (o `shepherd ai model`).',
  'err.rate_limited':
      'Se alcanzó el límite de uso del proveedor. Espera un momento e inténtalo de nuevo.',
  'err.busy': 'El motor sigue respondiendo a la pregunta anterior.',
};
