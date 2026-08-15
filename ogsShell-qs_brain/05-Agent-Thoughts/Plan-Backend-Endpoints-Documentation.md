---
title: "Plan: Comprehensive Backend Endpoints Documentation & AGENTS.md Directive"
type: agent-thought
tags:
  - plan/documentation
  - backend/ipc
  - architecture/endpoints
created: 2026-08-11
updated: 2026-08-11
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[IPC-Server-Service]]"
  - "[[Go-Daemon-Core]]"
  - "[[Agent-Workflow-Directives]]"
---

# Plan: Backend Endpoints Documentation & Agent Workflow Directive

> [!IDEA]
> Formalizing a single, authoritative reference for all Unix Domain Socket NDJSON RPC actions and broadcast events will eliminate guessing for frontend AI agents and developers. Adding an explicit pre-task check step to `AGENTS.md` guarantees that all future agents cross-check backend capabilities before building UI widgets.

## Problem Statement
The Go backend daemon (`core/`) exposes a wide range of RPC actions and real-time events across Wi-Fi, Bluetooth, Alarms, Calendar/Holidays, and System Metrics. However, agents working on the Quickshell QML frontend (`shell/`) need a clear, centralized, and standardized reference document detailing every endpoint, payload signature, data type, and event channel. Additionally, `.agents/AGENTS.md` needs an explicit lifecycle step requiring agents to review backend endpoints before undertaking frontend integrations.

## Proposed Solution
1. **Analyze Codebase**: Exhaustively catalog all IPC handlers (`core/main.go`, `core/ipc/`, `core/monitors/`, `core/services/`).
2. **Author Master Reference Document**: Create `.agents/BACKEND_ENDPOINTS.md` with complete schemas, payload structures, argument types, and QML integration snippets.
3. **Synchronize Obsidian Vault**: Create `ogsShell-qs_brain/01-Architecture/Backend-Endpoints-Reference.md` adhering to `[[obsidian-glossary]]` rules, with full wikilinks and YAML metadata.
4. **Update Agent Directives**: Update `.agents/AGENTS.md` Pre-Task Lifecycle to mandate inspecting `.agents/BACKEND_ENDPOINTS.md` before implementing or refactoring UI components or IPC handlers.
5. **Update Architectural Indices**: Update `.agents/ARCHITECTURE.md` and `ogsShell-qs_brain/04-Agent-Rules/Agent-Workflow-Directives.md` to reference the new document.

## Affected Components
- `.agents/BACKEND_ENDPOINTS.md` (New master file)
- `.agents/AGENTS.md` (Updated pre-task lifecycle)
- `.agents/ARCHITECTURE.md` (Reference index update)
- `ogsShell-qs_brain/01-Architecture/Backend-Endpoints-Reference.md` (New brain note)
- `ogsShell-qs_brain/04-Agent-Rules/Agent-Workflow-Directives.md` (Lifecycle diagram & directives update)
