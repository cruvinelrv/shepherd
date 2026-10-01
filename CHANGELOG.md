## 0.12.23 - 2026-10-01

### AI Telemetry, MCP Tool Execution & Reasoning Stream
- **Telemetry & Metrics Alignment**:
  - Extended AI telemetry events with `profile`, `isEstimated` indicator (for local heuristic token calculations), and `toolCallsCount`.
  - Added native `mcp_tool_call` telemetry events reporting tool usage, server identity, and execution status to Shepherd backend dashboard.
- **MCP Tool Integration**:
  - Added `AiMcpIntegrationService`, `AiMcpToolCallEntity`, and `AiMcpToolCallModel` to execute and track Model Context Protocol tools within interactive AI workflows.
- **Reasoning Stream Parsing**:
  - Added `AiReasoningStreamTransformer`, `AiReasoningChunkEntity`, and `AiReasoningChunkModel` for transparently capturing `<think>` reasoning blocks from modern reasoning models.
- **Context Budget & Vector Store**:
  - Added `AiContextBudgetService` to supervise prompt context limits.
  - Enhanced vector chunk deduplication using SHA256 hashes in `AiVectorDatabase`.

## 0.12.22 - 2026-09-30

### Dynamic Ollama Model Discovery & Multi-Model Selection
- **Automatic Ollama Model Auto-Discovery**:
  - The model switcher (`/model` and `shepherd ai model`) now queries the local Ollama instance (`/api/tags`) and automatically displays all models downloaded and installed locally (e.g. `qwen2.5-coder:7b`, `llama3.1`, `deepseek-r1:8b`, `codellama`, etc.) as numbered selectable options.
  - When Ollama is offline, gracefully falls back to cached/known models without blocking.
- **Direct Model Selection Syntax**:
  - Developers can type any Ollama model name directly in the prompt or command (e.g. `/model qwen2.5-coder:7b`, `/model ollama deepseek-r1`, or `shepherd ai model ollama <modelo>`).
  - Added persistence: newly selected models are dynamically registered in `known_models` in `.shepherd/ai_config.yaml`.
- **Improved Connection Error Guidance**:
  - Friendly actionable diagnostics when Ollama is offline or `Connection refused` occurs, advising developers to start `ollama serve` or switch models with `/model` or `medium`.

## 0.12.21 - 2026-09-30

### Interactive Shell Navigation (`cd`, `pwd`, `workspace`) & Smart Project Clean
- **Built-in Shell Navigation (`cd`, `pwd`)**:
  - Added native `cd` and `pwd` commands inside `shepherd shell` (REPL) to navigate directories without exiting the session.
  - Supports `~` home expansion, relative paths, `..`, `-` (previous directory), and absolute paths.
  - Automatically jumps to registered workspace projects by name: typing `cd <nome_do_projeto>` navigates straight to the project folder.
  - Automatically jumps to workspace root via `cd workspace`, `cd ws`, or `cd root`.
  - Re-evaluates workspace manifest and project context dynamically upon changing directories, updating the prompt and session in real time.
- **Workspace Project Listing (`workspace` / `ws`)**:
  - Lists all registered projects in `.shepherd/workspace.yaml` with their categories, paths, and indicator for the currently active project.
- **Smart Target Resolution in `shepherd clean`**:
  - `shepherd clean <alvo>` can now target a specific project by name, matching registered projects in `workspace.yaml` or any subpath.
  - Uses `manifest.rootDir` to accurately resolve project paths even when invoked from a nested subdirectory.

## 0.12.20 - 2026-09-30

### Resilient Safe Workspace Scanning in `shepherd clean`
- **Safe Directory Traversal & Permission Guard**:
  - Replaced unshielded recursive directory streams with a safe breadth-first scanner in `clean_command.dart`.
  - Automatically catches and silently skips `PathAccessException` / `FileSystemException` on macOS/Linux protected folders (e.g. `Photos Library.photoslibrary`, `Library`, etc.).
- **System and Media Directory Exclusions**:
  - Excluded OS system and media directories (`Pictures`, `Movies`, `Music`, `Library`, `Applications`, `System`, `.Trash`, `.cache`).
  - Added home directory (`~`) safeguard: prevents runaway scans across user disks if executed from the home directory root.
- **Smart Dart vs Flutter Detection**:
  - Differentiates pure Dart packages from Flutter projects, executing `dart pub get` for Dart and `flutter clean` + `flutter pub get` for Flutter.

## 0.12.19 - 2026-09-30

### Shepherd Shell Slash Command Interception & Dynamic Model Switching
- **Universal Slash Command Interception in `shepherd shell`**:
  - The Shepherd Shell REPL (`shepherd shell`) now intercepts commands starting with `/` (such as `/model`, `/modelo`, `/change-model`, `/help`, `/clear`, `/exit`, `/index`), preventing them from being mistakenly forwarded as natural language prompts to the LLM.
- **Dynamic Model Switching from REPL**:
  - Running `/model` or `model` in the shell opens the interactive model selection menu.
  - Running `/model <provedor_ou_modelo>` (e.g. `/model sonnet 5`, `/model chat_gpt`, `/model ollama`) immediately updates the active model and synchronizes the session state in real time.

## 0.12.18 - 2026-09-30

### Smart Model Alias Normalization & Provider-Level Default Persistence
- **Precise Model Name Normalization**:
  - Implemented `_normalizeModelName` to cleanly decouple provider aliases from specific model identifiers.
  - Commands like `shepherd ai model sonnet 5`, `shepherd ai model "sonnet 5"`, `sonnet-5`, and `sonnet 4.6` instantly resolve to `claude-sonnet-5` and `claude-sonnet-4-6`.
- **Automatic Provider-Level Default Model Persistence**:
  - When switching models via `shepherd ai model <modelo>` or interactive `/model`, Shepherd now updates both `active_model` and the provider's `default_model` in `.shepherd/ai_config.yaml`.
  - Future switches to that provider (e.g. `shepherd ai model claude`) automatically recall the user's latest chosen model for that provider.

## 0.12.17 - 2026-09-30

### Anthropic Claude Sonnet 5 Upgrade & Flexible Aliases
- **Claude Sonnet 5 by Default**:
  - Upgraded the primary Anthropic default model from legacy versions to **`claude-sonnet-5`**.
  - Added support for the Anthropic 4.6 family, including `claude-sonnet-4-6` and `claude-opus-4-6` in `AiModelCatalogService`.
- **Extended Sonnet Aliases & Prefix Resolution**:
  - Dynamic inference now recognizes `sonnet*` prefixes directly (e.g., `sonnet 5`, `sonnet-5`, `sonnet 4.6`, `sonnet-4.6`, `claude-5`, `claude 5`).
  - Typing `shepherd ai model sonnet 5` or `shepherd ai model claude` automatically points to `claude-sonnet-5`.

## 0.12.16 - 2026-09-30

### Provider-Agnostic Dynamic Model Switching & Neutral Provider Resolution
- **Universal Model Switching Subcommands (`shepherd ai model` / `modelo` / `change-model`)**:
  - Direct switching between models and providers from the command line: `shepherd ai model [nome_ou_provedor]`.
  - Interactive selection menu when executed without arguments: lists all configured providers with current active indicator (★).
- **Interactive Chat Dynamic Switching (`/model` / `/modelo`)**:
  - Instant in-session model switching during `shepherd ai` interactive chat without restarting the session.
- **Provider Neutrality & Parity**:
  - Completely balanced, provider-agnostic architecture giving equal treatment to Google Gemini, OpenAI (ChatGPT), Anthropic (Claude), and Ollama/LocalAI.
  - Symmetric menu rendering: 1 balanced slot per configured provider reflecting the user's specific configured model and credentials from `.shepherd/ai_config.yaml`.
  - Rich alias matching: `chat_gpt`, `chatgpt`, `openai`, `claude`, `anthropic`, `gemini`, `google`, `ollama`, `local`.
  - Dynamic model prefix inference without biased fallbacks: correctly routes `gpt-*`, `o1-*`, `o3-*`, `claude-*`, `gemini-*`, `llama*`, `deepseek*`, etc.
- **Balanced Adaptive RAG Policy**:
  - Local models (`ollama`, `local_ai`): RAG active by default ($0 cost, 100% private codebase retrieval).
  - Cloud paid models (`openai`, `anthropic`, `gemini`): RAG disabled by default to safeguard API token consumption, easily enabled via `--rag` or `/rag on`.
- **Model State Management**:
  - Implemented `copyWith` on `AiConfigModel` for clean, immutable persistence to `.shepherd/ai_config.yaml`.

## 0.12.15 - 2026-09-30

### Adaptive Smart RAG & Multi-Language Cost-Saving Optimization
- **Local-First Adaptive RAG Architecture**:
  - RAG vector context injection is now **active by default for local models** (`ollama`, `local_ai`, `--local`), providing unlimited, 100% private, and zero-cost codebase retrieval.
  - Automatically **disabled by default for remote/paid cloud providers** (Google Gemini, OpenAI, Anthropic) to prevent accidental and excessive API token consumption.
- **Explicit Opt-in / Opt-out Flags (`--rag` / `--no-rag`)**:
  - Developers can pass `--rag` to enable vector context on cloud models, or `--no-rag` to completely disable it for any provider.
- **Trilingual Friendly Tips (PT / EN / ES)**:
  - Clear, actionable tips displayed when executing cloud queries without `--rag`, informing users that local models offer free RAG by default.
  - Handled cleanly via `AiI18nHelper` (`ragCloudTip`, `ragIndexTip`, `ragStatusLabel`).
- **Interactive Chat Slash Commands**:
  - In `shepherd ai` interactive chat, users can now toggle RAG in real time with `/rag on`, `/rag off`, or check current status with `/rag`.
  - Header displays exact status label: `RAG: Local (Active / Free)`, `RAG: Cloud (Active via --rag)`, or `RAG: Disabled (use --rag)`.

## 0.12.14 - 2026-09-27

### Azure DevOps (Azure Connect) & GitHub Dual Remote Integration
- **GitRemoteHelper & Auto-Detection**: Added robust parser in `git_remote_utils.dart` that automatically detects whether the active repository is hosted on Azure DevOps (`dev.azure.com`, `visualstudio.com`, `ssh.dev.azure.com`) or GitHub (`github.com`), extracting organization, project, repository name, and web base URLs.
- **Clean Architecture Models**: Introduced `GitRemoteRepoEntity` and `GitRemoteRepoModel` adhering to Domain-Driven Design patterns.
- **Workspace Configuration Alignment**: Enhanced `config_utils.dart` to read `repoType` and `pullRequestEnabled` from `.shepherd/config.yaml`, ensuring 100% interoperability with Shepherd Studio Engine workspace configurations.
- **Multi-Platform PR Creation in Shepherd Flow**:
  - **Azure DevOps REST API**: Automatic Pull Request creation using Azure DevOps REST API v7.1 when `AZURE_DEVOPS_EXT_PAT` or `AZURE_TOKEN` environment variables are configured.
  - **Azure CLI Support**: Seamlessly falls back to `az repos pr create` if the Azure CLI is installed.
  - **Interactive Fallback**: Directly opens the Azure DevOps `/pullrequestcreate` web URL if CLI or tokens are not available.
  - **GitHub Continuity**: Full backward compatibility with `gh pr create` and GitHub web comparison URLs.
- **Deploy Menu Overhaul**: Updated `deploy_menu.dart` to recognize Azure DevOps repositories and dynamically tailor release and PR options.

## 0.12.13 - 2026-09-27

### Shepherd Flow Interactive Menu Integration & Direct Release Support
- **Main Menu Integration**: Added option `[F] Shepherd Flow (TBD Release Automation) 🚀` to the main interactive menu (`general_menu.dart`), making the Trunk-Based Development release flow accessible with a single keystroke.
- **Deploy Menu Overhaul**: Promoted `shepherd flow` to option `1. 🚀 Execute Automated Release Flow` in `deploy_menu.dart`, seamlessly connecting the automated pipeline with manual changelog and PR management options.
- **Direct Release & Auto-Tagging (`--no-pr`)**: Enhanced `runFlowCommand` when Pull Requests are skipped (`--no-pr`), automatically offering to merge the release branch into the principal branch and create/push the git tag `vX.Y.Z` immediately.
- **Automatic `lib/src/version.dart` Sync**: `_updateAppVersion` now automatically detects and updates Dart version constant files in sync with `pubspec.yaml`, eliminating version drift in Dart packages.

## 0.12.12 - 2026-09-27

### Local SQLite Vector Store & Semantic RAG Indexer
- **Decentralized Local Vector Database**: Implemented a 100% local, private vector database stored in `.shepherd/vectors/embeddings.db` powered by `sqflite_common_ffi`. Excluded from git repositories via `.shepherd/.gitignore`.
- **Trilingual Indexing Commands (`shepherd ai index` / `indexar`)**:
  - Full multilingual support in English, Portuguese, and Spanish: `shepherd ai index` / `shepherd ai indexar`.
  - Flags for complete control: `--force` / `--forcar` / `--forzar`, `--status` / `--estado`, `--clear` / `--limpar` / `--limpiar`, and `--project` / `--projeto`.
  - Incremental indexing: skips unchanged files in milliseconds using modification timestamps.
- **Hybrid Embedding Engine (`AiEmbeddingService`)**:
  - Supports deep neural embeddings via Ollama/LAN AI (`nomic-embed-text`), Google Gemini (`text-embedding-004`), and OpenAI (`text-embedding-3-small`).
  - Built-in zero-latency local dense vectorizer (128 dimensions, L2-normalized) for 100% offline indexing and search without external services.
- **Smart Workspace Scanner & Overlapping Chunking**:
  - Automatic detection of multi-repo workspaces (`.shepherd/workspace.yaml`) or standalone project directories.
  - Chunks code with line overlap to preserve function/class context.
- **Automatic RAG Integration in AI Invocations**:
  - Prompts in `shepherd ai` automatically query the local vector store and attach the most relevant code chunks.
  - Interactive Shell REPL (`ShepherdShell`) includes vector retrieval per message and direct `/index` slash command.
  - Inference footers display exact vector chunk count: `RAG: local-vector (N chunks)`.

## 0.12.11 - 2026-09-27

### Localized Shell Welcome Banner & Local/LAN AI Session Resolution
- **Localized Shell Welcome Banner**: Automatically renders welcome status, offline tool notices, and help guidance in the developer's language (EN / PT / ES) based on `AiI18nHelper.detectSystemLanguage()`.
- **Local/LAN AI Session Resolution Fix**: Updated `ShellSessionModel.loadFromWorkspace()` to detect configured local AI engines (Ollama, local_ai, LAN servers) even when `apiKey` is empty, properly showing active provider, model, and local status in the shell banner.

## 0.12.10 - 2026-09-27

### Multilingual 3-Profile AI System (EN / PT / ES) & Guided LAN Setup
- **Multilingual Command & Flag Support**: Full polyglot recognition across English, Portuguese, and Spanish simultaneously:
  - **Advanced Model Profile**: `--advanced` (EN), `--avancado` (PT), `--avanzado` (ES), or `--deep`.
  - **Medium Model Profile**: `--medium` (EN), `--medio` (PT / ES), or `--fast`.
  - **Local Zero-Cost Profile**: `--local` (EN / PT / ES).
- **Shepherd Shell Trilingual Commands**: Direct slash commands `/advanced`, `/avancado`, `/avanzado`, `/medium`, `/medio`, `/local`, and `/help`, `/ajuda`, `/ayuda` in interactive chat.
- **Dedicated Profile Slots (`AiModelSlotEntity` & `AiModelSlotModel`)**: Configurable in `.shepherd/ai_config.yaml` to bind preferred engines to Advanced, Medium, and Local profiles, with easy switching of the active default.
- **Frictionless Local vs. LAN Setup**: Interactive guided configuration in `shepherd ai config` prompts whether local AI runs on `[1] This machine (localhost)` (instant zero-URL connection) or `[2] Another machine on LAN (IP address)`.

## 0.12.9 - 2026-09-27

### Universal Local & LAN AI Server Support (LM Studio, vLLM, Jan, LocalAI, Ollama)
- **Support for Any AI Software on Local Network**: Introduced first-class support for any self-hosted or LAN-accessible AI server (`local_ai`), including LM Studio, vLLM, Jan, LocalAI, llama.cpp, and Text Generation WebUI via standard OpenAI-compatible endpoints (`/v1/chat/completions` and `/v1/models`).
- **Smart LAN Subnet & Zero-Cost Detection**: Automatically detects LAN and loopback addresses (`localhost`, `127.0.0.1`, `0.0.0.0`, `192.168.x.x`, `10.x.x.x`, `172.16-31.x.x`, `*.local`), treating any connected local machine as zero cost:
  - Terminal markers display `[Local / Gratuito]`.
  - Shepherd Union governance telemetry reports `providerCategory: "local"`.
  - API keys are made optional for local endpoints (no mandatory tokens or cloud accounts required).
- **Interactive Multi-Provider Configuration**: Added `[5] Servidor Local / Rede Local` to `shepherd ai config` with custom base URL prompts, optional key input, and instant model catalog queries (`/models`) over the local network.

## 0.12.8 - 2026-09-27

### Asynchronous AI Telemetry to Union & Remote LAN Ollama Support
- **Union AI Telemetry Integration (`sendAITelemetry`)**: Ships non-intrusive, privacy-preserving governance telemetry (`llm_call` and `memory_op` for RAG) directly to Shepherd Union / BFF in the background without exposing user prompts or code.
- **Local Network / LAN Ollama Support**: Ollama configuration now fully supports remote LAN IP addresses, hostnames, and custom ports (e.g. `http://192.168.1.50:11434`, `my-gpu.local:11434`), as well as automatic fallback to `OLLAMA_HOST` / `OLLAMA_BASE_URL` environment variables.

## 0.12.7 - 2026-09-27

### Token Telemetry & Local Free vs. Paid API Classification
- **Token Economy Marker**: Implemented real-time token tracking in inference footers, mirroring Shepherd Studio Engine / `shepherd_intelligence`.
- **Transparent Usage Classification**: Distinguishes between local free tokens (e.g. Ollama daemon, marked as `[Local / Gratuito]`) and cloud billing tokens (e.g. Gemini, OpenAI, Claude, marked as `[API / Pago]`).
- **Prompt + Completion Breakdown**: Displays exact prompt (`p`) and completion (`c`) token counts (e.g., `Tokens: 193 [158p+35c] (API / Pago)`).

## 0.12.6 - 2026-09-27

### Local RAG Usage Status & Visual Markers
- **Transparent Context/RAG Status**: Added dynamic RAG usage indicators to LLM response footers, showing exactly when local project files and workspace context are utilized (`RAG: Local (Workspace)` or `RAG: Local (X arqs)`).
- **Shepherd Shell RAG Integration**: Added RAG status badges to the Shepherd Shell welcome box, interactive prompt headers, and `status` command.

## 0.12.5 - 2026-09-27

### Multi-Model BYOK Architecture & Dynamic Model Sync
- **Direct Multi-Provider Inference**: Re-architected `shepherd ai` to talk directly from the developer's machine to the configured AI provider (Google Gemini, OpenAI, Anthropic Claude, or local Ollama). Eliminates central proxy latency, network errors, and cross-tenant billing risks.
- **Simultaneous Multi-Model Configuration**: Developers can now configure and store API keys and endpoints for multiple providers at the same time in `.shepherd/ai_config.yaml` or global `~/.shepherd/ai_config.yaml`, easily choosing or switching active models without losing other keys.
- **Dynamic Online Model Sync**: Interactive model selector in `shepherd ai config` fetches up-to-date models directly from provider APIs (Gemini, OpenAI, Anthropic, and local Ollama daemon) with quick selection numbers.
- **Persistent Manual Model Addition**: Custom or newly released models can be added manually on the fly and are immediately saved into the persistent local catalog.

## 0.12.4 - 2026-09-27

### Shepherd Platform AI Gateway Route Standardization
- **Unified AI Gateway Host**: Standardized `ShepherdPlatformAiService` gateway URL to point directly to `union.shepherdplatform.com` (`union-uat.shepherdplatform.com` for UAT), eliminating the requirement for a separate `ai.shepherdplatform.com` subdomain.

## 0.12.3 - 2026-09-26

### Fix Environment Syncing with Shepherd Union
- **Robust Environment Parsing**: Fixed a bug where `.shepherd/environments.yaml` with `environments: []` or nested structures mistakenly sent `environments` as an environment name, causing a 404 `Global environment not registered: environments` error during project linking and sync.
- **Safe Fallback**: Added `parseLocalEnvironments` supporting both flat mappings (`dev: develop`) and structured lists/maps, properly filtering out invalid or placeholder names.

## 0.12.2 - 2026-09-26

### Shell UX Polish & Banner Border Alignment
- **Workspace-Centric Display**: Removed redundant `Projeto` display from the REPL welcome banner and status view; now prominently showcases the active Workspace name.
- **Pixel-Perfect Banner Borders**: Solved terminal border overflow by implementing unicode-aware display width calculation (`_visualWidth`) for emojis and wide glyphs with dynamic padding.
- **Removed Startup Update Notification**: Eliminated intrusive and conflicting "Update available" startup banner.

## 0.12.1 - 2026-09-26

### Shepherd Tag Unification & Test Generation Refactor
- **Shepherd Tag Standardization**: Replaced all legacy Maestro references with Shepherd Tag across CLI commands, help documentation, and automated flow generation.
- **Normalized Flow Directory**: Automated test flows generated by `shepherd test gen` are now placed in `.shepherd/flows/`.
- **CI / Distribution Build Fixes**: Cleaned release packaging rules and resolved package exclusions in `.pubignore` and `.gitignore`.

## 0.12.0 - 2026-09-26

### MCP (Model Context Protocol) Native Client Integration
- **Shepherd Studio & Intelligence Interoperability**: Full compatibility with Shepherd Studio Engine (`pkg/mcpclient`) and registry format (`~/.shepherd/mcp_servers.json` and `.shepherd/mcp_servers.json`), as well as standard `.shepherd/mcp.json`.
- **Dual Transport Support**: Connect to MCP servers via standard I/O child processes (`stdio`) or streamable HTTP/SSE endpoints (`http`).
- **MCP CLI & Shell Commands**: Added `shepherd mcp [list|status|call]` and interactive shell integration to discover tools, check handshake latency, and execute MCP tool calls directly.
- **AI Prompt Context Injection**: Enabled MCP tools are automatically discovered and summarized into the AI context for `shepherd ai`, empowering LLM agents with local environment tools.

### Multi-Platform Standalone Binary Distribution (Universal CLI)
- **Zero-Dependency Native Binaries**: GitHub Actions automated pipeline (`release_binaries.yml`) compiling standalone AOT native executables for macOS (Apple Silicon arm64 + Intel x64), Linux (x64), and Windows (x64) attached to GitHub Releases.
- **Universal Install Scripts**:
  - `scripts/install.sh`: One-liner installer for macOS and Linux (`curl -fsSL https://... | bash`) with auto-architecture detection.
  - `scripts/install.ps1`: One-liner installer for Windows PowerShell (`irm https://... | iex`).

## 0.11.2 - 2026-09-26

### Workspace & Project Architecture Alignment
- **Workspace-Level `skills.yaml`**: Introduced `.shepherd/skills.yaml` to configure organization/workspace AI skills and workflows, automatically ingested by `shepherd ai` as context for the Shepherd Platform Gateway & Orchestrator.
- **Project-Level `specs.yaml`**: Introduced `.shepherd/specs.yaml` containing architectural guidelines, DDD patterns, and project requirements, injected into AI context for localized code generation.
- **Automatic Scaffolding on Startup (`WorkspaceScaffoldService`)**: When launching `shepherd` or entering `shepherd shell`, all missing canonical Shepherd Platform YAML files (`workspace.yaml`, `skills.yaml`, `domains.yaml`, `sync_config.yaml`, `project.yaml`, `specs.yaml`, `environments.yaml`, `feature_toggles.yaml`, `config.yaml`, `microfrontends.yaml`, `shepherd_activity.yaml`) are automatically created without overwriting existing configurations.
- **Workspace & Project Hierarchy in Shell**: Display both active Workspace name and Project name across the REPL prompt (`shepherd [Workspace > Projeto] (fast) > `), status command, and welcome banner.
- **Secret Protection**: Automatically maintains `.shepherd/.gitignore` to keep credentials and local cache (`session.yaml`, `ai_config.yaml`, `shepherd.db`, `update_cache.yaml`, `environment_variables.yaml`) safely out of version control.

## 0.11.1 - 2026-09-26

### LLM Engine Clarity & Transparency
- **Active Engine Indicators**: Visible model name (e.g. `gemini-2.5-flash`, `gemini-1.5-pro`), provider, tier, tokens, and latency displayed in `shepherd shell` banners, `status` command, and in response footers of `shepherd ai`.
- **`model` / `engine` Shell Command**: Inspect provider, model, tier, and execution mode directly in the REPL.

### Local File Reading & Safe File Modifications (Coding Agent Capabilities)
- **Local Context Injection (`@arquivo` & `-f/--file`)**: Mention any local file with `@path/to/file` in prompts or pass `-f <path>` to automatically read and attach file contents into AI prompt context.
- **Diff Preview & Confirmation (`[S/n]`)**: AI-proposed code modifications and file creations are rendered as unified colored diffs for review before applying.
- **Auto-Execution in `--auto`**: Files are modified automatically with workspace safety checks preventing path traversal.

### Shell as Default CLI Experience
- **Interactive Shell by Default**: Running `shepherd` without arguments now immediately launches `ShepherdShell` instead of the legacy numbered menus.
- **Auto-Routing in Shell**: Prompts typed directly into the shell without command prefixes are automatically forwarded to `shepherd ai`.

## 0.11.0 - 2026-09-26

### Shepherd Interactive Shell (REPL)
- **`shepherd shell`**: Added persistent interactive shell environment. Keeps project context in memory, allows running commands directly (`ai`, `clean`, `flow`, `changelog`, `status`, etc.) without shell re-initialization overhead.
- **Configurable Modes & Tiers**: Manage execution modes (`fast`, `plan`, `auto`) and model tiers (`fast`, `deep`) via `mode <fast|plan|auto>` and `tier <fast|deep>`.

### Shepherd Platform AI Gateway
- **Multi-Model & Enterprise RAG Integration**: Integrated `shepherd ai` with the Shepherd Platform AI Gateway, utilizing private RAG knowledge bases, contextual embeddings, and autonomous execution pipelines from `shepherd_intelligence`.
- **Plan Review & Autonomous Execution**: Added `--plan` and `--auto` execution modes with interactive step-by-step confirmation and direct action execution.
- **Graceful Local Fallback**: When offline or unauthenticated, `shepherd ai` gracefully suggests creating a free platform account at `https://shepherdplatform.com` or falls back to local direct Gemini keys.

### Productivity Tools Guarantee & Branding
- **100% Offline Local Productivity**: Clarified and ensured all core developer commands (`shepherd clean`, `shepherd flow`, `shepherd changelog`, `shepherd analyze`, `shepherd test`) remain completely functional offline without requiring an account or network access.
- **Marmelotech Official Attribution**: Added official credits and links to [Marmelotech](https://marmelotech.com.br) and the free Shepherd Platform tier across all menus, shell banners, and CLI informational displays.

## 0.10.4 - 2026-09-24

### Fixes
- **Default Gemini model deprecated**: `gemini-2.5-flash` is no longer available to new users ("This model models/gemini-2.5-flash is no longer available to new users..."). Changed the default used by `shepherd ai` and `shepherd ai config` to `gemini-3.8-flash`.

## 0.10.3 - 2026-09-24

### Fixes
- **`shepherd login` crashing with `NoSuchMethodError: The method '[]' was called on null` during environment sync**: root cause was server-side (shepherd_bff's `syncProjectEnvironments` was returning `environment: null` for every result — fixed separately) — this CLI-side change makes the sync defensive against a malformed/partial response either way: a result with no `environment` is now skipped instead of crashing the whole `shepherd login` flow.

## 0.10.2 - 2026-09-24

### Fixes
- **Error messages showing the literal text `$e` instead of the actual error**: `\$e`/`\${...}` inside regular (non-raw) Dart strings escapes interpolation — copied from the GraphQL query strings just above them, where that escaping is required, into the plain error-printing statements right after, where it isn't. Affected `shepherd login`'s connection/project-fetch/environment-sync error messages and `shepherd changelog`'s telemetry sync error messages. This is what was hiding the real cause behind "Could not sync environments: $e" after a successful login.

## 0.10.1 - 2026-09-24

### Fixes
- **`shepherd login` fetch-projects step failing with "Sessão inválida ou expirada"**: the CLI was sending the session token as `Authorization: Bearer <token>`, but shepherd_bff only ever read `X-Auth-Token`. This mismatch existed for a long time with no visible effect because the affected resolvers had no auth check at all until a recent backend security fix started enforcing it, which is what surfaced this bug. Fixed in `shepherd login` (both the projects fetch and the environments sync) and in `shepherd changelog`'s telemetry sync, all now sending `X-Auth-Token`. Two of those call sites (`_fetchServerRevision`, `_syncEnvironments`) had a second, independent bug where the token was interpolated as `\$token` inside a non-raw string, sending the literal text `$token` instead of the actual value — also fixed.

## 0.10.0 - 2026-09-24

### Shepherd AI
- **`shepherd ai`**: New command that sends a prompt (CLI argument and/or stdin pipe) to Gemini and streams the response. Requires an authenticated `shepherd login` session and automatically includes local project context (`.shepherd/project.yaml`, `.shepherd/environments.yaml`, `devops/domains.yaml`) in every prompt.
- **`shepherd ai config`**: New interactive command to set the model and API key used by `ai`, stored in `.shepherd/ai_config.yaml`. Falls back to the `GEMINI_API_KEY` environment variable when no config exists.
- **`--scope project|workspace`**: New option on `shepherd ai` (default `project`) — `workspace` also includes a summary of every project registered in `.shepherd/workspace.yaml` (the multi-repo catalog generated by Shepherd Studio or `shepherd init`), so the AI can be scoped to just the current project or the whole workspace at runtime.
- **Interactive chat mode**: Running `shepherd ai` with no prompt in a real terminal now starts a REPL-style conversation, keeping history between turns, instead of printing a usage message.

### Fixes & Housekeeping
- `session.yaml` and `ai_config.yaml` now live in `.shepherd/` (same directory as `project.yaml`/`workspace.yaml`) instead of a separate global directory, and are automatically added to `.shepherd/.gitignore` so a login token or API key can never end up committed.

## 0.9.8 - 2026-08-06

- **Workspace Governance & DDD Specification**: Added support for `.shepherd/workspace.yaml` and elevated hierarchical domain catalog matching.
- **Squads & Team Members Support**: Integrated `squads` with member email lists and domain ownership mapping compliant with Shepherd Studio Engine.

## 0.9.7 - 2026-07-08

- **Corporation Scope Filtering**: Fixed an issue where `shepherd login` and `shepherd sync` did not send the `X-Corporation-Id` header, causing project listings and syncs to bypass corporation filtering.

## 0.9.6 - 2026-07-05

- **OCC (Optimistic Concurrency Control) for Telemetry Sync**: Implemented revision
  checks during shepherd gen syncing to prevent overwriting cloud data when local
  repository is outdated (Missing Git Pull).
- **Interactive Multi-Environment Login**: shepherd login now supports an
  interactive menu to choose between Production and UAT environments,
  persisting the selection globally.

## 0.9.5 - 2026-06-05

- **Pure Dart CLI compilation**: Removed `shepherd_tag` from `pubspec.yaml` dependencies. Since the CLI only generates the tag files dynamically using text/regex manipulation, it does not require `shepherd_tag` as a compiled dependency. This eliminates transitive Flutter SDK requirements, allowing the CLI to be globally activated and updated on any machine using standard `dart pub global activate shepherd` without needing the Flutter SDK.

## 0.9.4 - 2026-05-29
- update new site Shepherd Platform information
## 0.9.3 - 2026-05-29
- **Pull Request automation**: Added automatic PR creation after release flow, with interactive PR title prompt and changelog body fallback. Option `--no-pr` disables PR creation. Supports GitHub token or gh CLI.
- **Version bump enhancements**: Updated flow to prompt for PR title and use changelog as PR body.

## 0.9.2 - 2026-05-29

- **Git base reference validation**: Fixed a bug where comparing against a tag (e.g. `vX.Y.Z`) failed due to prepend of `origin/`. It now dynamically checks if the remote reference exists before using it.
- **Interactive Version Input**: Modified `shepherd flow` to show calculated suggestions (patch/minor/major) and accept any custom version string directly.

## 0.9.0 - 2026-05-29

### Trunk Based Development Release Flow
- **shepherd flow**: Added a release flow automation command (`shepherd flow`) that creates a release branch, bumps versions, updates/archives the changelog, and opens a Pull Request on GitHub using `gh`.
- **Global argument parser**: Registered options and flags for the `flow` subcommand in the routing engine.

## 0.8.3 - 2026-02-27

- **pub.dev compliance**: Shortened package description in `pubspec.yaml` to meet the 60-180 character limit requirement.

## 0.8.2 - 2026-02-27

### Enhanced Shepherd Tag Web Identification & Abstraction Support

- **Transparent Web Selectors**: Updated `TestGenerationService` to prioritize explicit `label` selectors for all interaction steps (`tapOn`, `assertVisible`) when targeting Web.
- **ShepherdKey Detection**: Added support for discovering widgets wrapped with the new `ShepherdKey` abstraction, ensuring seamless Shepherd Tag integration without explicit `Semantics` widgets in UI code.
- **Dependency Update**: Bumped `shepherd_tag` to `^0.0.5`.

## 0.8.1 - 2026-02-27

### Shepherd Tag Web Compatibility & Selector Optimization

- **Optimized Selectors**: Updated `TestGenerationService` to generate direct string selectors (`- assertVisible: "shepherd:ID"`) for improved reliability on Flutter Web.
- **Web Visibility Fix**: Adjusted generation logic to ensure elements can be found via `aria-label` (mapped from `ShepherdPageTag` label) even when using CanvasKit renderer.
- **Dependency Update**: Bumped `shepherd_tag` to `0.0.4`.

## 0.8.0 - 2026-02-26

### Atomic Design Integration & Standardized Automation

- **Atomic Design Schema**: Unified `shepherd_activity.yaml` to include an `elements` section with `typeDesignElement` categorization (Atom, Molecule, Organism, Token).
- **Intelligent Flow Generation**: `shepherd test gen` is now semantically aware; generating automated `tapOn` and `inputText` steps for Atoms, and `assertVisible` for complex Molecules/Organisms from Shepherd Tag.
- **Design Element CLI**: Added `shepherd element <add|list>` commands to manage design interaction points directly from the terminal.
- **Strict Tag Naming**: Enforced a consistent `WidgetName + Tags` naming convention for all generated wrapper classes and files, improving project scalability.
- **Enhanced Command Discovery**: Updated CLI help menus and documentation for `story`, `task`, `element`, and `tag` command groups.
- **Robust YAML Core**: Deep YAML-to-Dart conversion in `TestGenerationService` to handle complex nested metadata and avoid type casting errors.

## 0.7.5 - 2026-02-26

### Automated Test Generation & Tagging System

- **Shepherd Tag Test Generation**: Introduced `shepherd test gen` command to automatically generate Shepherd Tag YAML flows from tagged Flutter code.
- **Smart Activity Integration**: Test flows are now enriched with real User Story context from `shepherd_activity.yaml` (titles, descriptions, and task lists).
- **Shepherd Tag System**: Official support for the `shepherd_tag` package, allowing lightweight annotation-based tagging of widgets and classes.
- **Improved YAML Parsing**: Enhanced regex engine in `ShepherdRegex` for discovering `@ShepherdTag` and `ShepherdPageTag` annotations.
- **Automatic Step Discovery**: CLI now parses static members within tagged classes to automatically generate interaction steps like `tapOn` and `inputText`.
- **Clean Structure**: Generated test flows are now centralized within `.shepherd/flows/` to keep project roots organized.

## 0.7.4 - 2026-01-09

### Onboarding & User Experience Improvements

- **Modular Initialization**: Introduced two setup modes during `shepherd init`:
  - **Automation Only**: Lightweight setup for CI/CD (clean, changelog, deploy commands)
  - **Full Setup**: Complete DDD project management with domains and team ownership
- **Automatic Onboarding**: Running `shepherd` without arguments now automatically detects missing configuration and guides users through setup
- **Interactive First-Run Prompt**: When configuration is missing, users can choose between:
  - Initialize a new project
  - Pull from existing project
  - Exit
- **Auto-Directory Creation**: `.shepherd` and `devops` directories are now created automatically during init
- **Database Initialization Fix**: Fixed "no such table: persons" error by ensuring core tables are created before insert operations
- **Environment Setup UX**: Improved environment configuration with clear examples (DEV→develop, UAT→release, PRD→main)
- **Mode-Aware Menu**: Automation mode projects skip the interactive menu and show CLI usage guide instead
- **Customized Help**: `shepherd help` now shows different content based on project mode:
  - Automation mode: Shows only automation commands and information
  - Full mode: Shows complete command reference
- **Documentation Updates**: README restructured to reflect automatic onboarding flow

### Technical Improvements

- Init mode is now persisted in `project.yaml` as `init_mode` field
- Added `ensureCoreTables` call to `ConfigDatabase` for proper schema initialization
- Created `printAutomationHelp()` method for mode-specific help display
- Improved error handling and user feedback throughout onboarding flows

## 0.7.3 - 2025-12-22

- Fixed unnecessary archiving to `changelog_history.md` when version hasn't changed - archiving now only happens when version changes.
- Fixed header duplication issue where new commits were creating duplicate headers - new commits are now cleanly inserted into existing changelog structure.

## 0.7.2 - 2025-12-22

- Fixed `shepherd changelog` command to no longer require version changes for updating the changelog.
- The changelog now updates based on semantic commits only, allowing users to document commits incrementally before changing versions.
- This fix also improves the `shepherd deploy` command when using "change" mode for changelog generation.

## 0.7.1 - 2025-12-16

- Improved `shepherd changelog` command UX by properly prompting for both base branch and changelog type at the handler level.

## 0.7.0 - 2025-12-16

- Fixed `shepherd pull` command that was not working due to missing registration in the CLI runner.
- The pull command now correctly imports YAML configuration into the shepherd.db database.

## 0.6.9 - 2025-12-16

- Implemented automatic update notification banner in the main interactive menu to alert users when a new version is available.
- Update notifications now appear even when no users are registered (before `shepherd init`), ensuring first-time users are aware of available updates.

## 0.6.8 - 2025-12-16

- Introduced `shepherd auto-update` as a direct command for configuring update modes (`notify`, `prompt`, `silent`).
- This command allows configuration via arguments (e.g., `shepherd auto-update --mode=prompt`) or through an interactive menu.
- Removed auto-update configuration from the general Config menu to favor the direct command approach.

## 0.6.7 - 2025-12-16

- Improved `shepherd help` command with better organization: commands are now clearly separated into four categories (Direct Commands, Automation & Maintenance, Interactive Menus, and Information).
- Enhanced user experience: easier to understand the difference between commands that execute immediately versus those that open interactive menus.
- Added practical examples and tips for getting more details on any command with `--help` flag.

## 0.6.6 - 2025-12-15

- Added configurable auto-update modes via `.shepherd/config.yaml`.
- New update modes: `notify` (default, shows notification), `prompt` (asks user to update), `silent` (disables checks).
- Implemented interactive update prompt that can automatically execute `dart pub global activate shepherd` if user confirms.

## 0.6.5 - 2025-12-15

- Fixed a bug where the previous `CHANGELOG.md` content was not being archived to `dev_tools/changelog_history.md` when using the "update" mode in deploy or changelog commands.
- Refactored `deploy` command to use the unified `ChangelogService` logic, ensuring consistent behavior and proper history preservation across all changelog operations.

## 0.6.4 - 2025-11-19

- Centralized and improved the version detection logic: Shepherd now always tries the root pubspec.yaml first, then automatically falls back to the first microfrontend if needed, for all update flows.
- All related comments and documentation are now in English for better maintainability.

## 0.6.3 - 2025-11-19

- Fixed the update command to correctly fallback to the first microfrontend's pubspec.yaml when the root pubspec.yaml is missing, preventing errors in microfrontends environments.
- Now the changelog version is always set, as long as a pubspec.yaml exists in the root or in the first microfrontend.

## 0.6.2 - 2025-11-19

- Improved version detection for microfrontends: if there is no pubspec.yaml in the root, Shepherd now automatically uses the version from the first registered microfrontend.
- Ensured changelog versioning works correctly in microfrontends environments.

## 0.6.1 - 2025-11-18

- Fixed a bug where the CLI version was not displayed version correctly in some scenarios.

## 0.6.0 - 2025-11-18

- Improved the changelog type selection prompt: now provides clear English explanations, automatic suggestions based on branch name, and a help option for user guidance.
- Enhanced user experience for changelog and deploy commands, reducing confusion between "update" and "change" options.
- Fixed path/case issues when copying the changelog from a reference branch, ensuring robust operation in all environments.
- General code cleanups and minor bug fixes.

## 0.5.9 - 2025-11-18

- Shepherd version command now always displays the CLI version from a constant, regardless of the current project.
- Improved internal code organization and fixed minor issues with command registration.

## 0.5.8 - 2025-11-18

- Refactored changelog copy logic to always use `git show` instead of `git checkout`, ensuring compatibility and reliability across all project structures.
- Fixed issues where changelog operations could fail in microfrontends due to file existence discrepancies between branches.
- Improved error handling and user feedback when copying the changelog from the reference branch.
- General code cleanups and documentation updates.


## 0.5.7 - 2025-11-18

- Ensured that `CHANGELOG.md` is managed only at the project root, even in microfrontends contexts.
- Fully reviewed and standardized the logic for changelog update and copy in both `deploy` and `changelog` commands.
- Improved robustness and clarity of the deploy and changelog flows.
- Minor fixes and message adjustments for better predictability and maintainability.


## 0.5.6 - 2025-11-18

- Standardized the method for copying CHANGELOG.md from the reference branch using git checkout in both deploy and changelog commands.
- Improved code consistency and maintainability across CLI commands.
- Minor bug fixes and usability improvements.

## 0.5.5 - 2025-11-12

- Bugs general fixes

## 0.5.4 - 2025-11-12

- Added gitrecover command: interactive interface, branch and date selection, commit summary, confirmation, and automatic changelog saving.
- User experience improvements for deploy and changelog commands.
- Bug fixes in changelog generation.

## 0.5.3 - 2025-11-12

- **Changelog update reliability:** Improved the update option in the deploy process to ensure the changelog is copied from the reference branch and the header is updated correctly, without fetching commits.
- **Microfrontends safety:** Added safeguards to prevent changelog overwrites or errors in microfrontends environments during deploy update.
- **Internationalization:** Standardized all code comments to English for better maintainability and collaboration.
- **Bug fixes and refactoring:** General code cleanups and minor bug fixes to improve stability and code quality.

## 0.5.2 - 2025-11-12

**Improved deploy process:** Deploy now allows choosing between "change" or "update" options for the changelog, making the workflow more flexible and automated.
**Changelog header update guarantee:** The changelog header is automatically updated after the file is copied when choosing the update option in the deploy process.
**General fixes:** Code adjustments and cleanups for better organization and standardization.

## 0.5.1 - 2025-10-10
- **Fixed Shepherd changelog and deploy process**: Implemented comprehensive improvements to the changelog system including history preservation, version detection, enhanced formatting with hash/author/date, microfrontends support, and deploy workflow optimization with direct step-by-step execution.

## 0.5.0 - 2025-10-07
- **Fixed Init Command**: Restored full functionality to `shepherd init` command that was broken due to missing routing in CLI runner.
- **Fixed Deploy Command**: Restored full functionality to `shepherd deploy` command that was broken due to missing routing in CLI runner.
- **Enhanced Deploy Implementation**: Complete overhaul of deploy command to execute step-by-step deployment process directly without interactive menus.
- **Streamlined Deploy Workflow**: Deploy command now runs automatic step-by-step process including version updates, changelog generation, and PR creation prompts.
- **Improved CLI Routing**: Fixed systematic CLI routing issues affecting multiple commands (init, deploy, clean) by adding proper switch cases in shepherd_runner.dart.
- **Command Standardization**: Implemented consistent command wrapper pattern for all CLI commands with standardized argument handling.
- **Direct Deploy Execution**: `shepherd deploy` now executes deployment workflow directly instead of showing interactive menu, making it more efficient for CI/CD usage.
- **Better User Experience**: Simplified deployment process with streamlined prompts and automatic progression through deployment steps.

## 0.4.9 - 2025-10-07
- **Fixed Clean Command**: Restored full functionality to `shepherd clean` command that was broken due to missing routing in CLI runner.
- **Enhanced Clean Implementation**: Complete rewrite of clean command with robust project detection, recursive cleaning, and comprehensive cleanup operations.
- **Improved Clean Features**: Added support for both global cleaning (`shepherd clean`) and project-specific cleaning (`shepherd clean project`) with enhanced visual feedback.
- **Better Error Handling**: Improved error handling and user feedback during clean operations with detailed status reporting and emoji indicators.
- **Comprehensive Cleanup**: Clean command now removes `pubspec.lock`, `build/`, `.dart_tool/` directories and runs `flutter clean` + `flutter pub get` automatically.
- **Multi-Project Support**: Enhanced support for cleaning multiple projects and microfrontends in a single command execution.

## 0.4.8 - 2025-10-07
- **Complete DDD Architecture Implementation**: Implemented comprehensive Domain-Driven Design architecture for changelog service with proper separation of domain, data, and presentation layers.
- **Enhanced Feature Toggle System**: Complete refactoring of feature toggle commands to use clean DDD patterns with enhanced database support and enterprise fields (team, activity, prototype, versions).
- **Full English Internationalization**: Translated all Portuguese user-facing text to English across feature toggle commands, menus, and user prompts for international compatibility.
- **Improved CLI Routing**: Fixed command routing system in shepherd_runner.dart to properly handle `dart run shepherd changelog` and other commands.
- **Professional User Interface**: Standardized all user interactions with consistent English messaging, field labels, and status indicators.
- **Enterprise Field Support**: Added comprehensive support for enterprise-level feature toggle fields including team assignments, activity tracking, and prototype management.
- **Enhanced Import/Export**: Improved DynamoDB Terraform import/export functionality with configurable field mapping and validation.
- **Database Architecture**: Implemented robust enhanced feature toggle database with full CRUD operations and migration support from legacy systems.
- **Configuration Management**: Added advanced import field configuration system with predefined templates and custom mapping capabilities.
- **Backward Compatibility**: Maintained full compatibility with existing feature toggle data while providing migration paths to enhanced system.

## 0.4.7 - 2025-09-03
- Automatic synchronization: now, whenever any essential YAML file contains data, `shepherd pull` is executed automatically to ensure `shepherd.db` is always up-to-date with YAML sources.
- Improved logic for database and YAML sync: prevents outdated information by always prioritizing YAML content when present.
- The `user_active.yaml` file is now generated automatically based on the selection of owners in `domains.yaml`.
- Minor bug fixes and code cleanups.

## 0.4.6 - 2025-09-03
- Improved user registration flow in `shepherd pull` (separate prompts for first name and last name).
- When running the shepherd command, if the user_active.yaml file does not exist, suggest creating a default user or registering a new one from scratch.

## 0.4.5 (2025-09-01)

- Refactored changelog update flow to use a single prompt for the base branch, regardless of project type.
- Minor bug fixes and code cleanup.

## 0.4.4 - 2025-09-01
- Improved changelog flow: base branch is now requested only once for both simple projects and microfrontends, preventing duplicate prompts and errors.
- Unified logic for changelog updates, ensuring a smoother experience in all project types.
- Minor bug fixes and code cleanups.

## 0.4.3 - 2025-09-01
- Improved the shepherd pull flow: now the database is created and populated from YAML files if missing, without triggering project initialization.
- Enhanced validation: shepherd pull no longer requires shepherd.db to exist beforehand, making onboarding and sync more robust.
- Minor bug fixes and code cleanups for a smoother CLI experience.

## 0.4.2 - 2025-08-29
- Restored branch name registration in the changelog before each group of commits.
- Commits are now listed with a dash (`- `) for improved readability.
- Minor code and documentation cleanups.

## 0.4.1 - 2025-08-28
- Refactored changelog service: removed all debug prints and ensured clean output for production use.
- Centralized environment branch validation logic in a dedicated function (`validateEnvironmentBranch`), improving maintainability and clarity.
- The changelog update flow now blocks updates on environment branches, with clear messaging and no duplicate success messages.
- Translated all code comments and user-facing messages to English for internationalization and consistency.
- Improved modularization: separated logic for simple projects and microfrontends, making the codebase easier to extend and maintain.
- Minor bug fixes and code cleanup for robustness.

## 0.4.0 - 2025-08-28
- The changelog now prompts the user to specify the base branch (e.g., main, develop) when updating, making the workflow flexible for any team or context.
- Commit filtering improved: only direct semantic commits (refactor:, feat:, fix:) exclusive to the current branch (compared to the specified base) are registered.
- Removed dependency on shepherd.yaml for base branch configuration; the entire flow is now handled via user input.
- Ensured the base branch prompt is integrated into all Shepherd commands that update the changelog, including deploy.
- Refactored and centralized commit regex for greater clarity and maintainability.

## 0.3.9 - 2025-08-28
- Changelog service now strictly registers only direct semantic commits (refactor:, feat:, fix:) authored by the user, excluding all merges—even those with semantic messages.
- The release history is now fully aligned with the Conventional Commits standard and avoids noise from merged PRs.

## 0.3.8 - 2025-08-28
- Changelog service now only registers semantic commits (refactor:, feat:, fix:, tests:) authored by the current user and excludes merges.
- Release notes are now cleaner and focused on meaningful changes, following the Conventional Commits standard.

## 0.3.7 - 2025-08-28
- Centralized all commit-related regular expressions in shepherd_regex.dart for maintainability and clarity.
- Changelog service now uses ShepherdRegex for author and parent hash extraction, making commit filtering more robust and easier to maintain.

## 0.3.6 - 2025-08-28
- Changelog logic updated: now all commits are listed from the current branch, independent of any base branch (like main).
- This makes the changelog compatible with any workflow or branch naming convention, ensuring all your direct commits are captured.

## 0.3.5 - 2025-08-28
- Changelog filter improved: now uses Git commit parent hashes to technically exclude all merge commits, regardless of message content.
- Only direct commits authored by the current user are listed, making the changelog even more precise and robust.

## 0.3.4 - 2025-08-28
- Changelog commit filtering improved: now only shows commits authored by the current user in their branch.
- All merge commits (including PR merges and branch merges) are excluded from the changelog.
- Commits of type docs, chore, and style continue to be excluded for clarity.
- This ensures the changelog reflects only your direct contributions, making release notes more precise and personalized.

## 0.3.3 - 2025-08-28
- Refactored runner to act only as orchestrator, delegating validation and initialization to services.
- Centralized essential file validation and initialization in PathValidatorService.
- Fixed YAML file creation: all essential files are now created inside the .shepherd folder.
- Improved pull command: now always creates/synchronizes YAML files in .shepherd and updates the database accordingly.
- Enhanced SQLite inspection: CLI now allows viewing structure and data of all tables in shepherd.db.
- Modularized and cleaned up code for better maintainability and robustness.
- Improved error handling and feedback for missing essential files.
- Updated documentation and changelog logic for clarity and consistency.

## 0.3.2 - 2025-08-28
- Centralized active user logic in SyncController; removed all runner references to hasUser.
- New feature: CLI now checks for an active user and prompts to create a new user by entering details, or initializes with default values if preferred.
- Cleaned up runner logic: removed legacy variables and conditions, now only calls SyncController for user setup.
- Enhanced YAML and database consistency checks.
- Minor bug fixes and documentation updates.

## 0.3.1 - 2025-08-28
- Fixed the path for reading the .shepherd/domains.yaml file to ensure correct operation across multiple projects.

## 0.3.0 - 2025-08-27
- Shepherd now creates and uses the shepherd.db database and YAML files exclusively inside the .shepherd folder.
- The initialization flow has been improved: the interactive menu only shows the "project already initialized" warning if project.yaml contains valid id and name.
- Improvements in validation and consistency of YAML files and the database.
- Adjustments and refactoring for greater robustness, clarity, and user experience.
- Created a new registration for squad management.
- ShepherdCLI prepare code structure for display an interactive and visual Dashboard.
- The changelog.md now includes user commits, excluding docs, style, and chore commits, following the semantic commit standard.
## 0.2.9 - 2025-08-08
- The root CHANGELOG.md now always prioritizes the version from the root pubspec.yaml. If it does not exist, it uses the version from the first microfrontend listed in microfrontends.yaml.
- Improved consistency between deploy and changelog flows for multi-microfrontend projects.
- Code cleanup and improved logic for version and changelog management.
## 0.2.8 - 2025-08-08
- The root CHANGELOG.md is now always updated using the version from the specified microfrontend's pubspec.yaml, even if there is no pubspec.yaml in the root directory.
- Improved deploy and changelog flows for multi-microfrontend projects: version and changelog logic now work seamlessly for any microfrontend.
- Updated documentation and version references for 0.2.8.
- Minor bug fixes and code cleanup for reliability.
## 0.2.7 - 2025-08-08
- Fix changelog logic: now only the root or first microfrontend's changelog is updated, with clearer archiving of previous entries.
- Updated documentation and README files to reflect the new version and features.
- Minor bug fixes and code cleanup for a more robust and professional CLI experience.
## 0.2.6 - 2025-08-08
- Improved multi-microfrontend versioning: Shepherd now updates the version in all microfrontends' `pubspec.yaml` files.
- Enhanced changelog management: The changelog is now updated for all microfrontends, not just the first one.
- Environment branch logic: Changelog updates are now correctly blocked only for branches listed in `environments.yaml`.
- Accurate CLI feedback: The CLI now displays clear and correct messages about changelog updates.
- Removed debug print statements from changelog logic.
- Documentation updates and minor bug fixes.

## 0.2.5 - 2025-08-06
  - shepherd pull now works even if user_active.yaml does not exist, as long as the project is already configured.
  - Fixed user/owner selection and creation flow to avoid duplication and scoping errors.
  - Code reorganized to ensure robustness and clarity in initialization and onboarding.
  - Minor consistency improvements and error messages.
## 0.2.4 - 2025-08-05
  - Now domains.yaml is updated automatically whenever an owner is added to a domain (no need to manually export anymore).
  - Improves workflow and consistency for domain/owner management.
  - Minor code improvements and error handling for YAML export.

## 0.2.3 - 2025-08-05
  - Fixed: changelog update now works even if there is no pubspec.yaml in the root directory; Shepherd will use the first microfrontend's pubspec.yaml automatically.
  - Prevents PathNotFoundException and improves deploy/versioning flow for microfrontend-based projects.
  - Minor code improvements and error handling for changelog logic.

## 0.2.2 - 2025-08-05
  - Restored the prompt asking whether to update the root pubspec.yaml when it exists, for safer and more flexible versioning flows.
  - If the root pubspec.yaml does not exist, Shepherd updates the first microfrontend's pubspec.yaml automatically.
  - Improved UX: clearer feedback when updating versions, and more control for the user in multi-project setups.
  - Minor code and documentation improvements.

## 0.2.1 - 2025-08-05
  - All user-facing messages, prompts, and comments standardized to English across the CLI and codebase.
  - Microfrontends prompt in shepherd init now only accepts yes/no answers in English, with validation and reprompting.
  - Improved help/about commands: now always available, even without project initialization.
  - Translated and improved all CLI feedback, error messages, and onboarding flows for internationalization and clarity.
  - Bug fixes and code cleanup for a more consistent and professional user experience.
## 0.2.0 - 2025-08-05
  - Context-aware versioning: deploy and menu flows now prompt to update only the correct pubspec.yaml files, with an option to also update the root pubspec.yaml when microfrontends exist.
  - Pull Request (PR) enable/disable: shepherd init now prompts for PR support and saves the setting in config.yaml, controlling PR options in deploy flows.
  - Improved feedback: clear messages indicate which microfrontends and pubspec.yaml files are updated during deploy/versioning.
  - Consistent UX: both interactive menu and automatic deploy flows now offer the same control over versioning and PR logic.
  - Documentation and example updates: README files and shepherd_example.dart updated to reflect new best practices and features.
  - Bug fixes and code cleanup for a more robust CLI experience.
## 0.1.9 - 2025-08-04
  - shepherd clean and shepherd project are now fully independent from shepherd.db and YAML files. Both commands are routed before any initialization or onboarding logic, ensuring they work in any directory, even without project initialization.
  - Fixed command routing and parser registration for shepherd project, making it a true alias for cleaning only the current project.
  - Minor code cleanup and improved command documentation.
## 0.1.8 - 2025-08-04
  - sync_config.yaml generation now always includes dev_tools/shepherd/domains.yaml as a required file, ensuring robust onboarding and sync flows.
  - Fixed type conversion bug when listing tasks from YAML, preventing runtime errors.
  - Updated all YAML export/import logic (domains.yaml, feature_toggles.yaml, etc.) to reflect the new dev_tools/shepherd/ structure.
  - Documentation (README and translations) updated to reflect new paths, onboarding, and sync flows.
  - Minor bug fixes, UX improvements, and code cleanup.
## 0.1.7 - 2025-08-04
  - domains.yaml migration: now exported and read from dev_tools/shepherd/domains.yaml instead of devops/domains.yaml.
  - Feature Toggles for domains: improved support and synchronization between feature_toggles.yaml and the database, with robust consistency checks and regeneration logic.
  - Updated all CLI commands (export, pull, init) to use the new path for domains.yaml.
  - Improved onboarding and sync flows to reflect the new YAML location and feature toggle management.
  - Documentation and help messages updated to reference the new paths and features.
  - Code cleanup and minor bug fixes related to the migration and YAML sync.
## 0.1.6 - 2025-07-30
- Major refactor: modularized all CLI commands and domain logic for maintainability.
- All configuration and domain logic migrated to YAML and new domain folders.
- Updated all documentation (README, translations) to reflect new structure and features.
- Fixed all import and build errors after folder restructuring.
- Improved onboarding, error handling, and CLI UX.
- Added .pubignore and changelog compliance for pub.dev publication.
- Bug fixes and code cleanup for a stable release.

## 0.1.5 - 2025-07-24
  - shepherd deploy: improved changelog step to avoid duplicate entries by checking the full branch description, not just the branch number.

## 0.1.4 - 2025-07-23
  - Environment management improved: now each environment is linked to a single branch.
  - Added environments management to the Config menu for easier access and editing.
  - shepherd init now prompts for both environment name and its branch, saving in the correct format.
  - All onboarding, deploy, and changelog flows updated to use the new environment-branch structure.
  - Bug fixes and code cleanup for a more robust and user-friendly CLI.

## 0.1.3 - 2025-07-23
  - Environment management: environments are now empty by default and must be configured interactively during shepherd init. No default environments are added automatically.
  - Improved deploy and changelog flows: changelog updates are blocked on environment branches, and the message is only shown once.
  - Deploy menu: removed unnecessary 'Version not changed.' message when exiting the menu.
  - CLI onboarding and error handling further improved for clarity and user experience.
  - Code cleanup and bug fixes for robust, professional CLI workflows.

## 0.1.2 - 2025-07-22
  - shepherd pull: onboarding flow improved. Now creates the devops directory interactively if missing, and if domains.yaml is missing, prompts to run shepherd init and launches it automatically if user agrees.
  - All onboarding and error flows are now more robust and user-friendly, with clear English-only messages.
  - Modularization and code cleanup: CLI protections and onboarding logic separated for maintainability.
  - README and translations updated to reflect new version and onboarding flow.
  - Minor bug fixes and improvements.

## 0.1.1 - 2025-07-22
  - Features in the README are now grouped by DOMAIN, TOOLS, DEPLOY, and CONFIG for better clarity.
  - Added a note in the DEPLOY section about Pull Request creation with GitHub CLI and Azure CLI integration (coming soon).
  - Minor documentation improvements and consistency fixes.
  
## 0.1.0 - 2025-07-21
  - Fixed and unified the format for `user_active.yaml` across all flows (init, pull, etc): now always writes the full user object (id, first_name, last_name, email, type, github_username) for consistent CLI experience.
  - Shepherd pull now uses the same user writing logic as shepherd init, preventing display bugs and ensuring correct active user info.
  - Refactored and cleaned up code in `pull_command.dart`, `edit_person_controller.dart`, `config_menu.dart`, and `shepherd_database.dart` for maintainability and internationalization.
  - Minor bug fixes and code cleanup.

## 0.0.9 - 2025-07-20
  - About command: now displays author, homepage, repository, and docs as clickable links (OSC 8 hyperlinks) and uses centralized ANSI color constants for a visually improved output.
  - All CLI colors and styles are now managed via `AnsiColors` for consistency.
  - Version updated to 0.0.9 in all READMEs.
  - Improved about command layout and border for a more professional look.
  - Removed deprecated `author`/`authors` fields from pubspec.yaml, author is now hardcoded in about.
  - README, README.pt-br.md, and README.es.md updated to reference version 0.0.9.
  - Minor bug fixes and code cleanup.
  
## 0.0.8 - 2025-07-20
  - Visual improvements to the Analyze domains command: clearer layout, domain information shown first, better separation and readability.
  - Fixed a bug in Shepherd init where the domain was not created before owner registration, causing "Domain does not exist" errors when adding owners during initialization. Now the domain is created immediately after entering its name.

## 0.0.7 - 2025-07-20
  - `dart format` on the entire project.
  - change the changelog display format

## 0.0.6 - 2025-07-20
- Data layer refactor:
  - Moved `ShepherdDatabase` to `lib/src/data/datasources/local/shepherd_database.dart` to follow Clean Architecture conventions for local datasources.
  - Updated all imports across the project to use the new path for `ShepherdDatabase`.
- CLI and menu improvements:
  - Modularized the project initialization flow (`shepherd init`) into smaller files: domain prompt, owner prompt, repo type prompt, GitHub username prompt, and summary.
  - Improved code organization in the presentation layer for easier maintenance and testing.
  - Main menu and all submenus now follow Dart CLI standards, with improved color and ASCII art.
  - The 'Init' option was removed from the main menu (now only available via `shepherd init`).
  - All submenus now support both '0. Exit' and '9. Back to main menu'.
  - The active user is now displayed and persisted.
  - Domains menu: now lists available domains for user story/task management, and prevents adding owners to non-existent domains.
  - User stories/tasks: when creating a user story, the user can select one or more domains (comma separated) or leave blank for ALL; prompt is only shown at the right moment.
  - Removed redundant prompts for domain selection in user story flow.
- Bug fixes and polish:
  - Fixed type safety in repo type prompt to ensure non-nullable return.
  - Removed unused imports and improved error handling in prompts.
  - All comments and user-facing strings are now in English for pub.dev compliance.
  - Prevented adding owners to non-existent domains.
  - Improved validation and user experience in all prompts (cancel/return, empty input, etc).
- Documentation:
  - Updated code comments and documentation for clarity and maintainability.
  - Added guidance on folder structure for datasources (local/remote) in Clean Architecture.
  - Updated changelog to reflect all recent CLI and UX improvements.


## 0.0.5 - 2025-07-18
- Refactored command structure:
  - All CLI commands are now centralized in `lib/src/presentation/commands/commands.dart` for easier import and maintenance.
  - Removed the `cli_helpers.dart` file, making the structure cleaner.
  - Updated command imports in `bin/shepherd.dart` to use only `commands.dart`.
- Export file updates:
  - The `lib/shepherd.dart` file now exports only `commands.dart` to centralize command access, while keeping entity and service exports.
- README updates:
  - Package usage example updated in English, Portuguese, and Spanish READMEs to reflect the new command export centralization.
  - Imports in examples are now simplified and aligned with the new structure.
- Improved code organization and modularization, following Clean Architecture and best practices for pub.dev publication.

## 0.0.4 - 2025-07-18
- Added platform support section to README in English, Portuguese, and Spanish, clarifying that the package is intended for CLI/desktop/server use and does not support Web or WASM (due to dart:io).
- Updated dependencies in pubspec.yaml.

## 0.0.3 - 2025-07-18
- Dart format applied

## 0.0.2 - 2025-07-18
- Provide home page and documentation

## 0.0.1 - 2025-07-18
- Initial release: CLI and package for DDD project management in Dart/Flutter
- Uses a local SQLite database (via sqflite_ffi) for persistent storage of domains, owners, and related data. No external server required.
- Domain health analysis, owner management, YAML export, and cleaning automation
- Interactive CLI and programmatic API
- Owner type field is now standardized across all flows (domain config and add-owner) using a single allowed list: administrator, developer, lead_domain. Prevents inconsistent or duplicate owner types.
