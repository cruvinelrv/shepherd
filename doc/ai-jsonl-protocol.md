# `shepherd ai --jsonl` protocol

A machine interface for hosts such as Shepherd Studio. The CLI runs one
long-lived conversation; the host sends **requests** on stdin and reads
**events** from stdout. Both are JSON objects, **one per line** (UTF-8). Nothing
else is ever written to stdout: human-readable output goes to stderr.

```
shepherd ai --jsonl [--projects a,b] [-p provider] [-m model] [--plan|--auto] [--no-rag]
```

- The **working directory is the workspace root**. Workspace files
  (`.shepherd/*.yaml`) and the RAG index (`.shepherd/vectors/`) live there.
- Provider, model and credentials come from `ai_config.yaml` (local, else
  `~/.shepherd/`), the profile, or the flags above.
- Protocol version: `1` (reported in `ready`).

## Requests (host → CLI)

| `type` | Fields | Effect |
|---|---|---|
| `user_message` | `text` | Ask a question. One at a time; a second one while answering gets `error: busy`. |
| `confirm` | `id`, `approved` | Apply (`true`) or discard a proposed file. Answered with `file_result`. |
| `cancel` | – | Stop the current answer (a `done` still follows). Takes effect at once, even while the provider has said nothing yet. |
| `set_projects` | `projects` (list) | Change the selected project folders; history is kept. Empty = whole workspace. |
| `set_model` | `provider`, `model` and/or `profile` | Switch model. Answered with `model_changed`. |
| `set_mode` | `mode`: `fast` \| `plan` \| `auto` | `plan` answers without proposing files. Answered with `mode_changed`; anything else is `error: bad_request`. |
| `shutdown` | – | Exit. Closing stdin also ends the session once the current answer finishes. |

Blank and non-JSON lines are ignored.

## Events (CLI → host)

| `type` | Fields | Meaning |
|---|---|---|
| `ready` | `protocol`, `provider`, `model`, `mode`, `projects` | The session is up. |
| `index_progress` | `project`, `phase` (`start`\|`done`), `indexed_files`? | RAG indexing is running for a project. |
| `index_done` | `source`, `projects` | Indexing finished; `source` is the embedding backend (`ollama`, `gemini`, `openai`, `local`). |
| `rag_context` | `chunks`, `files` | Snippets added to the prompt (`project/file` paths). |
| `rag_unavailable` | `message` | RAG could not run; the conversation continues without it. |
| `text_delta` | `text` | Part of the answer for the user. File blocks are **not** included. |
| `reasoning_delta` | `text` | Part of the model's reasoning (`<think>`), when the model emits it. |
| `file_started` | `path` | The model began writing a file (path relative to the workspace root). |
| `file_proposal` | `id`, `path`, `content`, `is_new` | A complete file awaiting `confirm`. **Nothing is written yet.** |
| `file_blocked` | `path`, `reason` | A proposal dropped: outside the workspace or the selected projects. |
| `file_result` | `id`, `path`, `applied` | Outcome of a `confirm`. |
| `projects_changed` / `model_changed` | new values | Acknowledge `set_projects` / `set_model`. |
| `status` | `phase`, `idle_seconds` | **Sign of life** while a step produces no output of its own, every 5 s of quiet. `phase`: `indexing` \| `searching` \| `waiting_model` \| `thinking` \| `writing`. A host that sees no event *and* no `status` for much longer than that can treat the CLI as stuck. |
| `mode_changed` | `mode` | Acknowledges `set_mode`. |
| `usage` | `prompt_tokens`, `completion_tokens`, `is_local` | Token usage of the answer. |
| `done` | – | The answer is complete. |
| `error` | `code`, `message` | `not_configured`, `ollama_offline`, `invalid_key`, `busy`, `bad_request`, `unknown`. Before `ready`, `not_configured` means the session did not start. |

## Example

```jsonl
→ {"type":"user_message","text":"Crie um index.html com o título Olá"}
← {"type":"ready","protocol":1,"provider":"ollama","model":"qwen2.5-coder:7b","mode":"fast","projects":["meu-site"]}
← {"type":"index_done","source":"local","projects":1}
← {"type":"text_delta","text":"Vou criar a página.\n"}
← {"type":"file_started","path":"meu-site/index.html"}
← {"type":"file_proposal","id":"p0","path":"meu-site/index.html","content":"<h1>Olá</h1>\n","is_new":true}
← {"type":"done"}
→ {"type":"confirm","id":"p0","approved":true}
← {"type":"file_result","id":"p0","path":"meu-site/index.html","applied":true}
```

## File paths

A `// FILE:` path is placed relative to the workspace root, with one convenience:
when **exactly one project is selected**, a path that does not start with that
project (`lib/main.dart`) is taken as relative to the project and reported as
`project/lib/main.dart`. A path into another existing folder of the workspace is
`file_blocked`. With **several** projects selected, the path must start with one
of them, and the `file_blocked` reason says so.

## Safety

- Files are only proposed. The CLI writes one only after `confirm` with
  `approved: true`.
- A proposed path must stay inside the workspace root and, when projects are
  selected, inside one of them. Absolute paths and `..` are blocked.

## RAG and projects

Projects are the entries of `.shepherd/workspace.yaml`; the **host registers
them** (the CLI only reads it). Without registered projects the workspace is
indexed as one. The index is tagged per project, so a selection of projects is
searched. Search needs an embedding backend: Ollama (`nomic-embed-text`),
Gemini or OpenAI keys, otherwise a weaker offline vectorizer. A backend change
rebuilds the index. Files over `rag_max_file_kb` (default 256 KB) and common
non-text/secret files are not indexed.
