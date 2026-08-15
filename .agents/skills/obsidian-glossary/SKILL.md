---
name: obsidian-glossary
description: Rules and guidelines for reading, creating, and updating Obsidian markdown notes inside the ogsShell-qs_brain/ directory, including agent-autonomous thought logs and deep inter-note wikilinking.
---

# Skill: Obsidian Brain & Knowledge Base Management

## Purpose

This skill governs how any agent interacts with the `ogsShell-qs_brain/` directory (the Obsidian Vault). The agent MUST maintain a structured, interconnected, and up-to-date knowledge base regarding system architecture, Go daemon services, Unix Domain Socket IPC schemas, Quickshell UI components, development standards, and autonomous agent thought logs inside `ogsShell-qs_brain/`.

---

## 1. Vault Directory Structure

All documentation created or updated by the agent MUST strictly adhere to this layout:

```text
ogsShell-qs_brain/
├── 01-Architecture/      # High-level architecture, IPC JSON schemas, config formats
├── 02-Services/          # Go Daemon services (PipeWire, NetworkManager, BlueZ, Hyprland IPC, SysMetrics)
├── 03-UI-Components/     # Quickshell QML & PySide6 UI standards, themes, Dynamic Island widgets
├── 04-Agent-Rules/       # Coding standards (Go, QML, Python), git commit rules, agent workflows
└── 05-Agent-Thoughts/    # Agent scratchpad, autonomous ideas, refactoring proposals, reasoning logs
```

---

## 2. Inter-Note Linking Protocol (Obsidian Wikilinks)

To build a fully connected graph in Obsidian, the agent MUST explicitly link notes together using `[[Note-Name]]` syntax. Isolated (orphan) notes are **STRICTLY FORBIDDEN**.

1. **Format:** Always use standard Obsidian Wikilinks `[[Note-Name]]`. Do **not** use file extensions (e.g., use `[[Audio-Pipewire]]`, NOT `[[Audio-Pipewire.md]]`).
2. **Bi-Directional Tracing:**
   * Notes in `05-Agent-Thoughts/` MUST link to the relevant services in `02-Services/` or architecture specs in `01-Architecture/` that they are proposing to alter.
   * Notes in `02-Services/` MUST link back to related UI components in `03-UI-Components/` and IPC schemas in `01-Architecture/`.
3. **Contextual Anchors:** Use inline Wikilinks inside narrative text to build context.
   * *Example:* "This Go service communicates with `[[Hyprland-IPC]]` and broadcasts JSON events over `[[IPC-Socket-Schema]]`."

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
status: draft | active | deprecated | proposed | implemented
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

* Always specify language tags in code fences (`go`, `qml`, `python`, `bash`, `json`).
* Use **Mermaid.js** syntax for data flow or architecture diagrams when explaining complex interactions.

---

## 4. Usage Rules for `05-Agent-Thoughts/`

The `05-Agent-Thoughts/` directory is the agent's dedicated space for internal reasoning, multi-step task planning, architectural proposals, and post-mortems.

1. **When to Create a Thought Note:**
   * Before undertaking a major refactoring or complex feature implementation.
   * When discovering a potential system bottleneck or architectural flaw.
   * To outline a step-by-step execution plan for complex multi-file changes.
2. **Linking Obligation:** A thought note MUST link to all target notes it intends to modify or reference.
   * *Example:* A note `[[Refactoring-NetworkManager-Service]]` must explicitly link to `[[Network-Manager]]`, `[[NetworkSettings]]`, and `[[IPC-Socket-Schema]]`.
3. **Lifecycle:** When a proposal in `05-Agent-Thoughts/` is implemented, update its frontmatter `status` to `implemented` and add a link to the commit or the updated official docs.

---

## 5. Agent Execution Protocol

When executing coding, refactoring, or feature tasks, the agent MUST follow this three-phase pipeline:

### Phase 1: Context Recall & Ideation (Read)

1. Inspect existing notes in `01-Architecture/`, `02-Services/`, and `04-Agent-Rules/`.
2. For complex tasks, draft a proposal note in `05-Agent-Thoughts/` (e.g., `[[Plan-Audio-Device-Selection]]`) and cross-link relevant components.

### Phase 2: Implementation (Write Code)

1. Implement or modify the required code in `core/` (Go), `shell/` (QML), or `settings_app/` (PySide6) following `[[Go-Coding-Style]]`, `[[QML-Best-Practices]]`, and `[[PySide6-Standards]]`.

### Phase 3: Brain Synchronization (Update Docs)

1. **Update Official Docs:** Create or update the relevant service/UI notes in `01-Architecture/`, `02-Services/`, or `03-UI-Components/`.
2. **Update Thought Logs:** Mark the corresponding note in `05-Agent-Thoughts/` as `status: implemented`.
3. **Update Metadata:** Refresh the `updated: YYYY-MM-DD` timestamp on all modified notes.

---

## 6. Standard Note Templates

### Template A: Agent Thought / Proposal Note (`05-Agent-Thoughts/`)

```markdown
---
title: "Proposal: Async NetworkManager D-Bus Scanner in Go"
type: agent-thought
tags:
  - proposal/refactor
  - network/dbus
  - go/daemon
created: 2026-08-09
updated: 2026-08-09
status: proposed
related_notes:
  - "[[Network-Manager]]"
  - "[[IPC-Socket-Schema]]"
---

# Proposal: Async NetworkManager D-Bus Scanner in Go

> [!IDEA]
> Moving network scanning from polling to asynchronous D-Bus signals in the Go daemon will reduce idle CPU usage.

## Problem Statement
Current polling routine in `[[Network-Manager]]` queries D-Bus every 2 seconds, generating unnecessary CPU interrupts.

## Proposed Solution
1. Use `godbus/dbus` signal subscriptions inside a dedicated Go goroutine.
2. Broadcast `net_update` JSON events via Unix Domain Socket only when state changes occur.
3. Update `[[NetworkSettings]]` and `[[NetworkWidget]]` to react to new socket events.

## Affected Components
- `[[Network-Manager]]` - Go service implementation (`core/internal/services/net.go`)
- `[[IPC-Socket-Schema]]` - JSON broadcast message specification
- `[[NetworkWidget]]` - Quickshell QML component
```

### Template B: System Service Note (`02-Services/`)

```markdown
---
title: "PipeWire Audio Service (Go Daemon)"
type: service
tags:
  - audio/pipewire
  - go/daemon
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[IPC-Socket-Schema]]"
  - "[[AudioWidget]]"
  - "[[AudioSettings]]"
---

# PipeWire Audio Service

Go daemon subsystem responsible for monitoring system volume, default sinks, and mute states via WirePlumber/PipeWire D-Bus APIs.

## Dependencies & Core Packages
* `godbus/dbus` - Native Go D-Bus bindings
* PipeWire / WirePlumber Daemon

## Go Implementation Details
* **Source Path:** `core/internal/services/audio.go`
* **Execution Model:** Long-running Goroutine with D-Bus Signal Listener Loop

### Socket Event Broadcast Schema
When audio state changes, the service broadcasts the following JSON structure over `ogs_shell.sock`:

```json
{
  "type": "audio_update",
  "payload": {
    "volume": 75,
    "is_muted": false,
    "active_sink": "alsa_output.pci-0000_00_1f.3.analog-stereo"
  }
}
```

## Related Documentation & History

* Socket IPC specification: `[[IPC-Socket-Schema]]`
* QML Dynamic Island Widget: `[[AudioWidget]]`
* PySide6 Control Panel: `[[AudioSettings]]`

```
