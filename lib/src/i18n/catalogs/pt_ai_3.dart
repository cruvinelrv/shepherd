// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> ptAi3 = {
  'render.phase_indexing': 'indexando o workspace',
  'render.phase_searching': 'buscando contexto',
  'render.phase_writing': 'escrevendo',
  'render.phase_thinking': 'pensando',
  'render.phase_waiting': 'aguardando o modelo',
  'render.trimmed':
      '✂️  {n} mensagem(ns) antiga(s) ficaram de fora do contexto para caber na janela do modelo.',
  'render.preparing': '📄 preparando {path}...',
  'render.written': '✅ {path} gravado',
  'render.write_failed': '❌ não foi possível gravar {path}',
  'render.blocked': '🚫 {path} não foi proposto: {reason}',
  'render.indexed': '🧠 {project}: {n} arquivo(s) no índice',
  'render.context_ready': '🧠 Contexto pronto ({backend})',
  'render.pruned': ' · {n} índice(s) antigo(s) removido(s)',
  'render.context_chunks': '📎 {n} trecho(s) do workspace no contexto',
  'render.rag_unavailable': '⚠️  Contexto do workspace indisponível: {message}',
  'err.session_expired':
      'Sua sessão expirou. Execute `shepherd login` e tente de novo.',
  'err.login_required': 'Faça login para usar o Shepherd AI: `shepherd login`.',
  'err.not_configured':
      'Nenhum provedor de IA configurado. Execute `shepherd ai config`. ({detail})',
  'err.ollama_offline':
      'O servidor do Ollama não respondeu. Abra o Ollama (ou ajuste o endereço com `shepherd ai config`).',
  'err.invalid_key':
      'O provedor recusou a chave de API. Atualize-a com `shepherd ai config`.',
  'err.model_unavailable':
      'O modelo {model} não está disponível para a sua conta. Escolha outro com /model (ou `shepherd ai model`).',
  'err.rate_limited':
      'Limite de uso do provedor atingido. Aguarde um pouco e tente de novo.',
  'err.busy': 'O motor ainda está respondendo à pergunta anterior.',
};
