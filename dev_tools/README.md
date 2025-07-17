# Guia de Utilização dos Scripts Dart de Desenvolvimento

Este projeto possui scripts utilitários em Dart na pasta `dev_tools` para facilitar tarefas comuns de desenvolvimento.

obs: O ambiente da develop agora também será versionado para delimitarmos as mudanças feitas em cada versão.

## Scripts disponíveis

obs: Os scripts disponíveis são independentes, não é necessário executar um na sequência de outro. Cada um deles tem um propósito diferente.

### 1. Atualizar o changelog
Executa a automação do changelog do projeto.

**Uso:**

dart run dev_tools/update_changelog.dart


### 2. Limpar e atualizar dependências
Executa `flutter clean` e `flutter pub get` em todos os módulos principais.

**Uso:**
dart run dev_tools/clean_and_get.dart

## Dicas
- Execute os scripts a partir da raiz do repositório.
- Se precisar de permissões, rode com `dart` ou `flutter` instalado e configurado no PATH.

