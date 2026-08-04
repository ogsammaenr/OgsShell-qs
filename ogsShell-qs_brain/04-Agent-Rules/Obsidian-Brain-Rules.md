---
title: "Obsidian Brain & Knowledge Management Rules"
type: rule
tags:
  - rules/obsidian
  - rules/documentation
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[Development-Rules]]"
---

# Obsidian Brain & Knowledge Management Rules

> [!IMPORTANT]
> Governs how AI agents create, update, and link notes inside the `ogsShell-qs_brain/` Obsidian vault.

## Directory Structure Enforcement

All notes created or updated by agents MUST strictly adhere to this layout inside `ogsShell-qs_brain/`:

- `01-Architecture/`: Architecture overview, IPC specs, theme specs.
- `02-Services/`: System services and C daemon specifications.
- `03-UI-Components/`: Quickshell & PySide6 UI component docs.
- `04-Agent-Rules/`: Development rules and workflow guidelines.
- `05-Agent-Thoughts/`: Autonomous reasoning, refactoring proposals, and post-mortems.

## Wikilink Protocol (`[[Note-Name]]`)

- Every note MUST link to other relevant notes using `[[Note-Name]]` syntax.
- Orphan (unlinked) notes are **STRICTLY FORBIDDEN**.
- Do not include `.md` extensions inside Wikilinks (e.g. use `[[SystemStats-Service]]`, NOT `[[SystemStats-Service.md]]`).

## YAML Frontmatter & Callouts

- Every `.md` file MUST start with a valid YAML frontmatter block containing `title`, `type`, `tags`, `created`, `updated`, `status`, `related_notes`.
- Use GitHub/Obsidian callouts (`> [!NOTE]`, `> [!WARNING]`, `> [!IDEA]`, `> [!IMPORTANT]`).

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- Development Rules: `[[Development-Rules]]`
