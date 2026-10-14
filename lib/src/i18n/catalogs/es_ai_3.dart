// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> esAi3 = {
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
