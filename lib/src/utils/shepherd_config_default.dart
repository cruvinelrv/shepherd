/// List of commands that require Shepherd config validation.
const List<String> configRequiredCommands = [
  'init',
  'pull',
  'domains',
  'config',
  'deploy',
  'tools',
];

/// List of essential Shepherd configuration files (relative to .shepherd/).
const List<String> essentialShepherdFiles = [
  '.shepherd/domains.yaml',
  '.shepherd/config.yaml',
  '.shepherd/feature_toggles.yaml',
  '.shepherd/environments.yaml',
  '.shepherd/project.yaml',
  '.shepherd/sync_config.yaml',
  '.shepherd/user_active.yaml',
];
