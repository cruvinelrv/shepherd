// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> esAi1 = {
  'cfg.syncing': '🔄 Sincronizando el catálogo de modelos en línea...',
  'cfg.synced': '✅ ¡Catálogo sincronizado con éxito!',
  'cfg.title': '🤖 Shepherd AI — Configuración multimodelo',
  'cfg.active_line': 'Proveedor activo: {provider} | Modelo: {model}',
  'cfg.p_opencode': 'OpenCode Zen (opencode.ai - una clave, muchos modelos)',
  'cfg.p_local_ai':
      'Servidor local / Red local (LM Studio, vLLM, Jan, LocalAI)',
  'cfg.not_configured': '[Sin configurar]',
  'cfg.configured': '[Configurado: {key}]',
  'cfg.menu_profiles':
      '  [P] 🎯 Perfiles de modelos / Slots (Advanced, Medium, Local)',
  'cfg.menu_sync':
      '  [S] 🔄 Sincronizar el catálogo de modelos de todos los proveedores',
  'cfg.menu_save': '  [0] Guardar y salir',
  'cfg.choose_main': '\nElige una opción [1-{n}, P, S, 0]: ',
  'cfg.saved': '\n✅ Configuración guardada en .shepherd/ai_config.yaml\n',
  'cfg.models_synced': '✅ ¡Modelos sincronizados y guardados!',
  'cfg.invalid': 'Opción no válida.',
  'cfg.setup': '\n⚙️  Configurando {name}',
  'cfg.opencode_url': 'URL de OpenCode Zen [{url}]: ',
  'cfg.key_keep': 'API Key (Enter para mantener {key}): ',
  'cfg.key_opencode':
      'API Key de OpenCode Zen (consíguela en https://opencode.ai/zen): ',
  'cfg.where_runs': '\n¿Dónde se está ejecutando el motor {name}?',
  'cfg.where_here': '  [1] En mi propio equipo (localhost)',
  'cfg.where_lan': '  [2] En otro equipo de la red local (LAN / IP)',
  'cfg.where_choose': 'Elige [1 o 2, Enter para mantener {url}]: ',
  'cfg.set_localhost': 'Dirección configurada como localhost: {url}',
  'cfg.ask_host':
      'Escribe la IP o el nombre de host de la otra máquina (p. ej.: http://192.168.1.50:{port}) [{url}]: ',
  'cfg.key_local_keep':
      'API Key (Enter para mantener {key} o déjala en blanco si no la necesita): ',
  'cfg.key_local_new':
      'API Key (opcional para servidores locales/LAN, pulsa Enter para omitir): ',
  'cfg.pick_default': '\nElige el modelo predeterminado para {name}:',
  'cfg.selected_badge': '(Seleccionado)',
  'cfg.add_manual': '  [+] Añadir un modelo nuevo manualmente',
  'cfg.fetch_online':
      '  [R] 🔄 Buscar los modelos disponibles en línea en esta cuenta/servidor',
  'cfg.finish': '  [C] Terminar la selección de modelo',
  'cfg.choose_model_menu': '\nElige una opción [1-{n}, +, R, C]: ',
  'cfg.ask_model_id':
      '\nEscribe el identificador exacto del modelo (p. ej.: gemini-3.8-flash): ',
  'cfg.model_added': '¡Modelo "{model}" añadido y seleccionado!',
  'cfg.querying': '\nConsultando los modelos disponibles por la API...',
  'cfg.found_online': '¡Se encontraron {n} modelos en línea!',
  'cfg.none_online': 'Ningún modelo devuelto o no fue posible conectar.',
  'cfg.model_selected': 'Modelo "{model}" seleccionado.',
  'cfg.make_active':
      '\n¿Definir {name} ({model}) como el proveedor activo de Shepherd? [S/n]: ',
  'cfg.provider_done': '✅ ¡Proveedor {name} configurado con éxito!',
  'prof.title': '\n🎯 Perfiles de modelos',
  'prof.advanced': '  [1] 🧠 Avanzado:',
  'prof.medium': '  [2] ⚡ Medio:   ',
  'prof.local': '  [3] 🏡 Local:   ',
  'prof.default_star': '★ (Predeterminado)',
  'prof.use_advanced':
      'Uso: shepherd ai --advanced "..." o /advanced en el shell',
  'prof.use_medium': 'Uso: shepherd ai --medium "..." o /medium en el shell',
  'prof.use_local':
      'Uso: shepherd ai --local "..." o /local en el shell (costo cero)',
  'prof.set_default':
      '  [D] Definir el perfil activo predeterminado (actual: {profile})',
  'prof.back': '  [0] Volver al menú principal',
  'prof.pick_option': '\nElige una opción [1-3, D, 0]: ',
  'prof.pick_default':
      'Elige el perfil predeterminado [1: Advanced, 2: Medium, 3: Local]: ',
  'prof.default_changed': '✅ Perfil predeterminado cambiado a: {profile}!',
  'prof.pick_provider': '\nElige el proveedor para el perfil {slot}:',
  'prof.pick_provider_n': 'Elige un proveedor [1-{n}]: ',
  'prof.pick_model': '\nElige el modelo para el perfil {slot} ({provider}):',
  'prof.pick_model_n': 'Elige un modelo [1-{n}] o escribe su nombre: ',
  'prof.slot_done': '✅ Perfil {slot} configurado con: {provider} ({model})!',
  'chat.whole_workspace': 'todo el workspace',
  'chat.mode_where': 'modo {mode} | {where}',
  'chat.offline_notice':
      '⚠️  Sin conexión con Shepherd Union: usando la última validación de tu sesión.',
  'chat.commands_line':
      'Comandos: /plan /auto /fast · /model · /projects a,b · /help · "salir"\n',
  'chat.bye': '\n¡Hasta luego!',
  'chat.interrupted': '⏹ interrumpido',
  'chat.footer':
      '{model} · {provider} · modo {mode} · {ms} ms · {prompt}+{completion} tokens ({kind})',
  'chat.kind_local': 'Local / Gratuito',
  'chat.kind_cloud': 'Nube',
  'chat.unsaved':
      '⚠️  {n} archivo(s) propuesto(s) y no escrito(s): usa --auto para escribir sin preguntar.',
  'chat.proposed_change': '📝 Cambio propuesto por la IA:',
  'chat.apply_prompt': '¿Aplicar en {path}? [S/n]: ',
  'chat.applied': '✅ {path} escrito\n',
  'chat.write_failed': '❌ no se pudo escribir {path}\n',
  'chat.skipped': '⏭️  {path} omitido\n',
  'chat.mode_set': '✅ Modo {mode}',
  'chat.mode_current': 'Modo actual: {mode}. Usa /mode fast|plan|auto.',
  'chat.scope_set': '✅ Alcance: {scope}',
  'chat.rag_note':
      'El RAG se define al iniciar: usa --rag o --no-rag en `shepherd ai`.',
  'chat.unknown_command': 'Comando desconocido. Escribe /help.',
  'chat.switch_cancelled': 'ℹ️  Cambio cancelado. Se mantiene: {model}.',
  'chat.model_unknown':
      '❌ Opción o modelo no reconocido. Escribe "/model" para ver la lista.',
  'chat.model_changed': '✅ Modelo cambiado a: {model} ({provider})',
  'chat.help':
      '  /plan | /auto | /fast       cambia el modo (con texto después, pregunta de una vez)\n  /model [nombre]             cambia el modelo o el proveedor\n  /projects a,b               limita el contexto y los archivos a estos proyectos\n  salir                       termina\nCtrl+C durante una respuesta interrumpe solo la respuesta.',
  'chat.hint_full':
      '/plan solo planifica · /auto escribe ya · /fast pregunta antes · /model cambia el modelo · /projects limita el alcance · /help todos los comandos · salir',
  'chat.hint_short': '/plan /auto /fast · /model · /projects · /help · salir',
  'chat.help_mode_cmd': '/mode [fast|plan|auto]',
  'installer.env_missing': '{env} apunta a un archivo que no existe: {path}',
  'installer.download_failed':
      'No se pudo descargar el motor de IA ({e}). Conéctate a internet e inténtalo de nuevo.',
  'installer.no_package':
      'Aún no hay un motor de IA publicado para este equipo ({platform}).',
  'installer.unknown_platform': 'plataforma desconocida',
};
