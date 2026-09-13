---
name: obsidian-glossary
description: Rules and guidelines for reading, creating, and updating Obsidian markdown notes inside the ogsShell-qs_brain/ directory with deep inter-note wikilinking.
---

# Skill: Obsidian Brain & Knowledge Base Management

## Purpose

This skill governs how any agent interacts with the `ogsShell-qs_brain/` directory (the Obsidian Vault). The agent MUST maintain a structured, interconnected, and living knowledge base regarding system architecture, Go daemon services, Unix Domain Socket IPC schemas, Quickshell UI components, and development standards inside `ogsShell-qs_brain/`.

---

## 1. Vault Directory Structure

All documentation created or updated by the agent MUST strictly adhere to this lean 4-pillar layout:

```text
ogsShell-qs_brain/
├── 01-Architecture/      # High-level architecture, IPC JSON schemas, config formats, HIG specs
├── 02-Services/          # Go Daemon services (PipeWire, NetworkManager, BlueZ, Hyprland IPC, SysMetrics)
├── 03-UI-Components/      # Quickshell QML UI standards, themes, Dynamic Island widgets, settings
└── 04-Agent-Rules/       # Coding standards (Go, QML, Python), git rules, agent workflow directives
```

> [!NOTE]
> Ephemeral task planning and scratchpad thoughts happen dynamically within the agent-user conversation session. Persistent notes are strictly reserved for living architecture, concrete services, and active UI components. Do not create transient scratchpad or proposal markdown files in the vault.

---

## 2. Inter-Note Linking Protocol (Obsidian Wikilinks)

To build a fully connected graph in Obsidian, the agent MUST explicitly link notes together using `[[Note-Name]]` syntax. Isolated (orphan) notes are **STRICTLY FORBIDDEN**.

1. **Format:** Always use standard Obsidian Wikilinks `[[Note-Name]]`. Do **not** use file extensions (e.g., use `[[Audio-Pipewire]]`, NOT `[[Audio-Pipewire.md]]`).
2. **Bi-Directional Tracing:**
   * Notes in `02-Services/` MUST link to related UI components in `03-UI-Components/` and IPC schemas in `01-Architecture/`.
   * Notes in `03-UI-Components/` MUST link to relevant backend services in `02-Services/` and design specifications in `01-Architecture/`.
3. **Contextual Anchors:** Use inline Wikilinks inside narrative text to build context.
   * *Example:* "This Go service communicates with `[[Hyprland-IPC]]` and broadcasts JSON events over `[[IPC-Socket-Schema]]`."

---

## 3. Note Formatting & Obsidian Standards

Every note generated or modified by the agent MUST follow these Obsidian-native standards:

### A. YAML Frontmatter (Metadata)

Every `.md` file must start with a valid, minimal YAML frontmatter block (do not track timestamps or duplicate wikilinks here):

```yaml
---
title: "Document Title"
type: architecture | service | ui-component | rule
tags:
  - topic/subtopic
status: active | deprecated
---
```

### B. Obsidian Callouts

Use callouts to highlight important contexts or warnings:

```markdown
> [!NOTE]
> General architectural observation or context.

> [!WARNING]
> Breaking change risk or D-Bus method deprecation.

> [!TIP]
> Implementation tip or recommended practice.
```

### C. Code Blocks & Diagrams

* Always specify language tags in code fences (`go`, `qml`, `python`, `bash`, `json`).
* Use **Mermaid.js** diagrams strictly for complex state machines or asynchronous socket IPC flows. Keep nodes and labels minimal to conserve context tokens.

---

## 4. Agent Execution Protocol

When executing coding, refactoring, or feature tasks, the agent follows this streamlined three-phase pipeline:

### Phase 1: Context Recall (Read)

1. Inspect relevant specs in `01-Architecture/`, `02-Services/`, and `03-UI-Components/`.
2. Inspect `.agents/BACKEND_ENDPOINTS.md` for socket actions and broadcast event schemas.
3. Discuss or present the plan directly in conversation with the user (no temporary proposal files).

### Phase 2: Implementation (Write Code)

1. Implement or modify the required code in `shell/` (QML) or `core/` (Go) following `[[Go-Coding-Style]]` and `[[QML-Best-Practices]]`.

### Phase 3: Brain Synchronization (Update Living Docs)

1. **Update Living Docs:** If a new widget, configuration key, or IPC endpoint was added/changed, update the corresponding documentation in `01-Architecture/`, `02-Services/`, or `03-UI-Components/`.

---

## 5. Standard Note Templates

### Template A: System Service Note (`02-Services/`)

```markdown
---
title: "PipeWire Audio Service (Go Daemon)"
type: service
tags:
  - audio/pipewire
  - go/daemon
status: active
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
* Settings View: `[[AudioSettings]]`

```

### Template B: UI Component Note (`03-UI-Components/`)

```markdown
---
title: "Dynamic Island Component"
type: ui-component
tags:
  - quickshell/qml
  - dynamic-island
  - ui/widgets
status: active
---

# Dynamic Island Component

Houses the primary status bar, morphing spring animations, and state machines for Island and Notch presentations.

## File Location
* `shell/components/island/DynamicIsland.qml`

## Properties & Reactive Bindings
* `stateMode`: `"IDLE"` | `"HOVER"` | `"EXPANDED"` | `"TRANSIENT"`
* `formFactor`: Bound dynamically to `Config.formFactor` (`"island"` vs `"notch"`)

## Connected Services & Specs
* Socket IPC specification: `[[IPC-Socket-Schema]]`
* System architecture: `[[System-Architecture]]`
* Design tokens: `[[Style-Design-Tokens]]`
```
