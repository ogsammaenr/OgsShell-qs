---
name: obsidian-glossary
description: Rules and guidelines for reading, creating, and updating Obsidian markdown notes inside the ogsShell-qs_brain/ directory, including agent-autonomous thought logs and deep inter-note wikilinking.
---

# Skill: Obsidian Brain & Knowledge Base Management

## Purpose

This skill governs how the agent interacts with the `ogsShell-qs_brain/` directory (the Obsidian Vault). The agent MUST maintain a structured, interconnected, and up-to-date knowledge base regarding system architecture, services, UI components, development standards, and autonomous agent thought logs inside `ogsShell-qs_brain/`.

---

## 1. Vault Directory Structure

All documentation created or updated by the agent MUST strictly adhere to this layout:

```text
ogsShell-qs_brain/
├── 01-Architecture/      # High-level architecture, IPC schemas, config formats
├── 02-Services/          # System services (PipeWire, NetworkManager, BlueZ, Hyprland IPC)
├── 03-UI-Components/     # Quickshell & PySide6 QML UI standards, themes, design tokens
├── 04-Agent-Rules/       # Coding standards, git commit rules, agent workflows
└── 05-Agent-Thoughts/    # Agent scratchpad, autonomous ideas, refactoring proposals, reasoning logs
```

---

## 2. Inter-Note Linking Protocol (Obsidian Wikilinks)

To build a fully connected graph in Obsidian, the agent MUST explicitly link notes together using `[[Note-Name]]` syntax. Isolated (orphan) notes are **STRICTLY FORBIDDEN**.

1. **Format:** Always use standard Obsidian Wikilinks `[[Note-Name]]`. Do **not** use file extensions (e.g., use `[[Audio-Pipewire]]`, NOT `[[Audio-Pipewire.md]]`).
2. **Bi-Directional Tracing:**
   * Notes in `05-Agent-Thoughts/` MUST link to the relevant services in `02-Services/` or architecture specs in `01-Architecture/` that they are proposing to alter.
   * Notes in `02-Services/` MUST link back to related UI components in `03-UI-Components/` and configuration schemas in `01-Architecture/`.
3. **Contextual Anchors:** Use inline Wikilinks inside narrative text to build context.
   * *Example:* "This service communicates with `[[Hyprland-IPC]]` to adjust layout parameters defined in `[[Config-Schema]]`."

---

## 3. Note Formatting & Obsidian Standards

Every note generated or modified by the agent MUST follow these Obsidian-native standards:

### A. YAML Frontmatter (Metadata)

Every `.md` file must start with a valid YAML frontmatter block:

```yaml
---
title: "Document Title"
type: architecture | service | ui-component | rule | agent-thought
tags:
  - topic/subtopic
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: draft | active | deprecated | proposed
related_notes:
  - "[[Note-Name-1]]"
  - "[[Note-Name-2]]"
---
```

### B. Obsidian Callouts

Use callouts to highlight important contexts or warnings:

```markdown
> [!NOTE]
> General architectural observation or context.

> [!WARNING]
> Breaking change risk or D-Bus method deprecation.

> [!IDEA]
> Agent proposal for optimization or refactoring.
```

### C. Code Blocks & Diagrams

* Always specify language tags in code fences (`qml`, `python`, `bash`, `json`).
* Use **Mermaid.js** syntax for data flow or architecture diagrams when explaining complex interactions.

---

## 4. Usage Rules for `05-Agent-Thoughts/`

The `05-Agent-Thoughts/` directory is the agent's dedicated space for internal reasoning, multi-step task planning, architectural proposals, and post-mortems.

1. **When to Create a Thought Note:**
   * Before undertaking a major refactoring or complex feature implementation.
   * When discovering a potential system bottleneck or architectural flaw.
   * To outline a step-by-step execution plan for complex multi-file changes.
2. **Linking Obligation:** A thought note MUST link to all target notes it intends to modify or reference.
   * *Example:* A note `[[Refactoring-NetworkManager-Service]]` must explicitly link to `[[Network-Manager]]`, `[[NetworkSettings]]`, and `[[Config-Schema]]`.
3. **Lifecycle:** When a proposal in `05-Agent-Thoughts/` is implemented, update its frontmatter `status` to `implemented` and add a link to the commit or the updated official docs.

---

## 5. Agent Execution Protocol

When executing coding, refactoring, or feature tasks, the agent MUST follow this three-phase pipeline:

### Phase 1: Context Recall & Ideation (Read)

1. Inspect existing notes in `01-Architecture/`, `02-Services/`, and `04-Agent-Rules/`.
2. For complex tasks, draft a proposal note in `05-Agent-Thoughts/` (e.g., `[[Plan-Audio-Device-Selection]]`) and cross-link relevant components.

### Phase 2: Implementation (Write Code)

1. Implement or modify the required code in `shell/` or `settings-app/` following `[[Python-Coding-Style]]` and `[[QML-Best-Practices]]`.

### Phase 3: Brain Synchronization (Update Docs)

1. **Update Official Docs:** Create or update the relevant service/UI notes in `01-Architecture/`, `02-Services/`, or `03-UI-Components/`.
2. **Update Thought Logs:** Mark the corresponding note in `05-Agent-Thoughts/` as `status: implemented`.
3. **Update Metadata:** Refresh the `updated: YYYY-MM-DD` timestamp on all modified notes.

---

## 6. Standard Note Templates

### Template A: Agent Thought / Proposal Note (`05-Agent-Thoughts/`)

```markdown
---
title: "Proposal: Async NetworkManager D-Bus Scanner"
type: agent-thought
tags:
  - proposal/refactor
  - network/dbus
created: 2026-08-03
updated: 2026-08-03
status: proposed
related_notes:
  - "[[Network-Manager]]"
  - "[[Config-Schema]]"
---

# Proposal: Async NetworkManager D-Bus Scanner

> [!IDEA]
> Moving network scanning from synchronous subprocess calls to asynchronous D-Bus signals will prevent UI freezes in `[[NetworkSettings]]`.

## Problem Statement
Current implementation in `[[Network-Manager]]` blocks the main Python thread during Wi-Fi scans.

## Proposed Solution
1. Replace `nmcli` subprocess calls with `dbus-next` async event loops.
2. Update `[[NetworkSettings]]` QML component to bind to the new async signal.

## Affected Components
- `[[Network-Manager]]` - Service implementation
- `[[NetworkSettings]]` - UI component
- `[[Config-Schema]]` - Target storage for saved APNs
```

### Template B: System Service Note (`02-Services/`)

```markdown
---
title: "PipeWire Audio Service"
type: service
tags:
  - audio/pipewire
  - python/pyside6
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Config-Schema]]"
  - "[[AudioSettings]]"
  - "[[Refactoring-Audio-Pipeline]]"
---

# PipeWire Audio Service

Brief description of what this service does and its role in the desktop shell.

## Dependencies & External Tools
- `wpctl` (WirePlumber CLI)
- PipeWire Audio Daemon

## Python Implementation Details
- **Module:** `settings-app/services/audio_service.py`
- **QML Expose Name:** `AudioService`

### Signals & Properties
| Property / Signal | Type | Direction | Description |
| :--- | :--- | :--- | :--- |
| `volume` | `int` | Read/Write | Main sink volume percentage (0-100) |
| `isMuted` | `bool` | Read/Write | Main sink mute state |
| `volumeChanged` | Signal | Python -> QML | Emitted when system volume changes |

## Related Documentation & History
- Implemented based on proposal: `[[Refactoring-Audio-Pipeline]]`
- Configuration schema: `[[Config-Schema]]`
- UI Implementation: `[[AudioSettings]]`
```
