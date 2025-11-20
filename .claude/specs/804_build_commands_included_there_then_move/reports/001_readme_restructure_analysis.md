# Commands README Restructure Analysis

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Commands README structure refactoring for workflow documentation
- **Report Type**: codebase analysis

## Executive Summary

Analysis of `/home/benjamin/.config/.claude/commands/README.md` reveals a well-structured document of 797 lines that needs restructuring to better highlight the core workflow commands (/research, /plan, /revise, /build). The current "Command Highlights" section focuses only on /build and /plan, missing /research and /revise. The "Integration Benefits" section can be merged into "Purpose" as "Features". Command dependency documentation needs expansion to include scripts, libraries, and templates. Box-drawing styling is already used consistently in the Command Architecture section.

## Findings

### 1. Current Structure Analysis (README.md)

**File**: `/home/benjamin/.config/.claude/commands/README.md`
- **Total Lines**: 797 lines
- **Location**: `/home/benjamin/.config/.claude/commands/README.md`

**Current Sections (in order)**:
1. Header with Command Count (lines 1-4)
2. Command Highlights (lines 6-26)
3. Purpose (lines 28-39)
4. Command Architecture (lines 41-66)
5. Available Commands (lines 68-265)
6. Common Flags (lines 267-389)
7. Command Definition Format (lines 391-428)
8. Command Types (lines 429-443)
9. Adaptive Plan Structures (lines 443-515)
10. Standards Discovery (lines 517-547)
11. Creating Custom Commands (lines 549-576)
12. Command Integration (lines 577-597)
13. Best Practices (lines 599-617)
14. Documentation Standards (lines 619-628)
15. Neovim Integration (lines 630-684)
16. Navigation (lines 686-704)
17. Examples (lines 706-796)

### 2. Current Command Highlights Section (lines 6-26)

```markdown
## Command Highlights

**/build** (Implementation Orchestrator):
- Execute existing implementation plans with wave-based parallel phases
- Automatic test execution and debugging loops
- Git commits for completed phases
- Supports progressive plan structures (Level 0/1/2)

**/plan** (Research-Driven Planning):
- Research phase creates persistent report files in `specs/reports/{topic}/`
- Planning phase cross-references research reports automatically
- Complexity-based depth adjustment (1-4)
- Topic-based organization for better discoverability
```

**Issues**:
- Missing /research and /revise commands
- No clear workflow sequence indication
- Lacks /research (the starting point) and /revise (the revision capability)

### 3. Current Integration Benefits and Purpose Sections

**Integration Benefits** (lines 21-26):
```markdown
**Integration Benefits**:
- Agents create files directly (no inline summaries)
- Topic-based organization for better discoverability
- Clear separation: specs/ (gitignored) vs debug/ (tracked)
- Full workflow automation from research through implementation
- Intelligent error recovery with persistent debugging artifacts
```

**Purpose** (lines 28-39):
```markdown
## Purpose

Commands provide structured, repeatable workflows for:

- **Implementation**: Systematic feature development with testing and commits (/build)
- **Planning**: Creating detailed implementation plans from requirements (/plan)
- **Research**: Investigating topics and generating comprehensive reports (/research)
- **Debugging**: Root cause analysis and bug fixing (/debug)
- **Revision**: Updating existing plans with new insights (/revise)
- **Orchestration**: Coordinating multi-agent workflows (/build)
- **Configuration**: Project setup and CLAUDE.md optimization (/setup)
```

**Observation**: Integration Benefits should be merged into Purpose to create a cohesive "Features" section.

### 4. Command Architecture Section (lines 41-66)

Currently uses box-drawing styling:
```
┌─────────────────────────────────────────────────────────────┐
│ User Input: /command [args]                                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Command Definition (.claude/commands/command.md)            │
├─────────────────────────────────────────────────────────────┤
│ • Metadata: tools, arguments, dependencies                  │
│ • Instructions: workflow steps and logic                    │
│ • Standards discovery: CLAUDE.md integration                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Execution                                                   │
├─────────────────────────────────────────────────────────────┤
│ • Read relevant files                                       │
│ • Apply project standards                                   │
│ • Invoke agents if needed                                   │
│ • Execute workflow steps                                    │
│ • Report results                                            │
└─────────────────────────────────────────────────────────────┘
```

**Enhancement needed**: More detailed architecture showing workflow vs execution stages.

### 5. Command Dependencies Inventory

#### /build (lines 72-88)
**Current Documentation**:
- Dependent Agents: implementer-coordinator, debug-analyst

**Actual Dependencies** (from build.md):
- **Agents**: implementer-coordinator, debug-analyst, spec-updater
- **Libraries**:
  - workflow-state-machine.sh (>=2.0.0)
  - state-persistence.sh (>=1.5.0)
  - library-version-check.sh
  - error-handling.sh
  - checkpoint-utils.sh
  - checkbox-utils.sh
- **Scripts**: None
- **Templates**: None

#### /plan (lines 123-138)
**Current Documentation**:
- Dependent Agents: research-specialist, research-sub-supervisor, plan-architect

**Actual Dependencies** (from plan.md):
- **Agents**: research-specialist, research-sub-supervisor, plan-architect
- **Libraries**:
  - workflow-state-machine.sh (>=2.0.0)
  - state-persistence.sh (>=1.5.0)
  - library-version-check.sh
  - error-handling.sh
  - unified-location-detection.sh
  - workflow-initialization.sh
- **Scripts**: None
- **Templates**: None

#### /research (lines 142-157)
**Current Documentation**:
- Dependent Agents: research-specialist, research-sub-supervisor

**Actual Dependencies** (from research.md):
- **Agents**: research-specialist, research-sub-supervisor
- **Libraries**:
  - workflow-state-machine.sh (>=2.0.0)
  - state-persistence.sh (>=1.5.0)
  - library-version-check.sh
  - error-handling.sh
  - unified-location-detection.sh
  - workflow-initialization.sh
- **Scripts**: None
- **Templates**: None

#### /revise (lines 161-176)
**Current Documentation**:
- Dependent Agents: research-specialist, research-sub-supervisor, plan-architect

**Actual Dependencies** (from revise.md):
- **Agents**: research-specialist, research-sub-supervisor, plan-architect
- **Libraries**:
  - workflow-state-machine.sh (>=2.0.0)
  - state-persistence.sh (>=1.5.0)
  - library-version-check.sh
  - error-handling.sh
- **Scripts**: None
- **Templates**: None

#### /debug (lines 104-119)
**Current Documentation**:
- Dependent Agents: research-specialist, plan-architect, debug-analyst

**Actual Dependencies** (from debug.md):
- **Agents**: research-specialist, plan-architect, debug-analyst, workflow-classifier
- **Libraries**:
  - workflow-state-machine.sh (>=2.0.0)
  - state-persistence.sh (>=1.5.0)
  - library-version-check.sh
  - error-handling.sh
  - unified-location-detection.sh
  - workflow-initialization.sh
- **Scripts**: None
- **Templates**: None

#### /setup (lines 180-194)
**Current Documentation**:
- No agent dependencies listed

**Actual Dependencies** (from setup.md):
- **Agents**: None (invokes /orchestrate for enhance mode)
- **Libraries**:
  - detect-testing.sh
  - generate-testing-protocols.sh
  - optimize-claude-md.sh
- **Dependent Commands**: orchestrate (for enhance mode)
- **Scripts**: None
- **Templates**: None

#### /expand (lines 200-213)
**Current Documentation**:
- No dependencies listed

**Actual Dependencies** (from expand.md):
- **Agents**: complexity-estimator
- **Libraries**:
  - plan-core-bundle.sh
  - auto-analysis-utils.sh
  - parse-adaptive-plan.sh
- **Scripts**: None
- **Templates**: None

#### /collapse (lines 218-229)
**Current Documentation**:
- No dependencies listed

**Actual Dependencies** (from collapse.md):
- **Agents**: complexity-estimator
- **Libraries**:
  - plan-core-bundle.sh
  - auto-analysis-utils.sh
- **Scripts**: None
- **Templates**: None

#### /convert-docs (lines 235-249)
**Current Documentation**:
- Dependent Agents: doc-converter

**Actual Dependencies** (from convert-docs.md):
- **Agents**: doc-converter
- **Libraries**:
  - convert-core.sh
- **External Tools**: MarkItDown, Pandoc, PyMuPDF4LLM
- **Scripts**: None
- **Templates**: None

#### /optimize-claude (lines 252-264)
**Current Documentation**:
- No dependencies listed

**Actual Dependencies** (from optimize-claude.md):
- **Agents**: claude-md-analyzer, docs-structure-analyzer, docs-bloat-analyzer, docs-accuracy-analyzer, cleanup-plan-architect
- **Libraries**:
  - unified-location-detection.sh
  - optimize-claude-md.sh
- **Scripts**: None
- **Templates**: None

### 6. Current Placement of /revise and /setup

**/revise** (lines 161-176):
- Currently in "Primary Commands" section
- Should remain in "Workflow Commands" to group with workflow cycle

**/setup** (lines 180-194):
- Currently in "Primary Commands" section
- Should move to "Utility Commands" as it's a configuration tool

### 7. Box-Drawing Styling Usage

Box-drawing is consistently used across 38 documentation files in the project. The pattern uses:
- `┌`, `┐`, `└`, `┘` for corners
- `─` for horizontal lines
- `│` for vertical lines
- `├`, `┤` for T-junctions
- `▼`, `▲` for arrows/flow indicators

This style is used for:
- Architecture diagrams
- Flow charts
- Process overviews
- Command structure diagrams

## Recommendations

### 1. Replace "Command Highlights" with "Workflow"

Create a new "Workflow" section showing the four core workflow commands in sequence:
```markdown
## Workflow

The core development workflow follows this sequence:

**/research** → **/plan** → **/revise** → **/build**

**1. /research** - Research-only workflow
- Creates comprehensive research reports without planning or implementation
- Supports complexity levels 1-4 for investigation depth
- Topic-based organization in specs/NNN_topic/reports/

**2. /plan** - Research and create implementation plan
- Combines research phase with plan generation
- Creates persistent reports cross-referenced by plans
- Complexity-based depth adjustment (default: 3)

**3. /revise** - Research and revise existing plan
- Updates existing plans based on new insights
- Creates backup of original plan before modification
- Integrates new research findings

**4. /build** - Build from plan
- Execute implementation plans with wave-based parallel phases
- Automatic test execution and debugging loops
- Git commits for completed phases
```

### 2. Create "Features" Section from Purpose and Integration Benefits

Merge lines 21-26 (Integration Benefits) into lines 28-39 (Purpose), renaming to "Features":
```markdown
## Features

### Workflow Capabilities
- **Research**: Investigate topics and generate comprehensive reports
- **Planning**: Create detailed implementation plans from requirements
- **Revision**: Update existing plans with new insights
- **Implementation**: Execute plans with testing and commits
- **Debugging**: Root cause analysis and bug fixing

### Technical Advantages
- **Agent-based execution**: Agents create files directly (no inline summaries)
- **Topic organization**: Structured specs/{NNN_topic}/ directories
- **Artifact separation**: specs/ (gitignored) vs debug/ (tracked)
- **Full automation**: Research through implementation workflow
- **Error recovery**: Persistent debugging artifacts for intelligent recovery
- **Standard compliance**: CLAUDE.md integration and validation
```

### 3. Enhance Command Architecture Section

Expand the box-drawing diagram to show more detail:
```markdown
## Command Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     USER INPUT LAYER                        │
├─────────────────────────────────────────────────────────────┤
│ /command [arguments] [--flags]                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   COMMAND DEFINITION LAYER                  │
├─────────────────────────────────────────────────────────────┤
│ File: .claude/commands/command.md                           │
├──────────────────┬──────────────────────────────────────────┤
│ Frontmatter      │ tools, arguments, dependencies           │
│ Instructions     │ workflow steps, state machine logic      │
│ Agent References │ behavioral guidelines paths              │
└──────────────────┴───────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    LIBRARY LAYER                            │
├─────────────────────────────────────────────────────────────┤
│ .claude/lib/                                                │
├──────────────────┬──────────────────────────────────────────┤
│ State Machine    │ workflow-state-machine.sh               │
│ Persistence      │ state-persistence.sh                    │
│ Utilities        │ unified-location-detection.sh           │
└──────────────────┴───────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     AGENT LAYER                             │
├─────────────────────────────────────────────────────────────┤
│ .claude/agents/                                             │
├──────────────────┬──────────────────────────────────────────┤
│ Research         │ research-specialist, research-sub-super │
│ Planning         │ plan-architect                          │
│ Implementation   │ implementer-coordinator                 │
│ Debugging        │ debug-analyst                           │
└──────────────────┴───────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    OUTPUT LAYER                             │
├─────────────────────────────────────────────────────────────┤
│ Artifacts: specs/{NNN_topic}/{plans|reports|debug|summaries}│
│ State:     ~/.claude/data/{state|checkpoints}               │
│ Logs:      ~/.claude/tmp/ (temporary debug logs)            │
└─────────────────────────────────────────────────────────────┘
```
```

### 4. Add Dependency Documentation to All Commands

For each command in "Available Commands", add a new "Dependencies" subsection:

```markdown
**Dependencies**:
- **Agents**: [agent1, agent2]
- **Libraries**: [lib1.sh, lib2.sh]
- **Scripts**: [script1.sh] (if any)
- **External Tools**: [tool1, tool2] (if any)
```

### 5. Move Commands to Correct Sections

- Move `/revise` from "Primary Commands" to "Workflow Commands"
- Move `/setup` from "Primary Commands" to "Utility Commands"

This creates clearer groupings:
- **Workflow Commands**: /research, /plan, /revise, /build (workflow cycle)
- **Primary Commands**: /debug, /convert-docs (specialized)
- **Structure Commands**: /expand, /collapse (plan structure)
- **Utility Commands**: /setup, /optimize-claude (configuration)

## References

- `/home/benjamin/.config/.claude/commands/README.md` (lines 1-797): Main document being refactored
- `/home/benjamin/.config/.claude/commands/build.md` (lines 1-928): Build command with full dependencies
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-419): Plan command with full dependencies
- `/home/benjamin/.config/.claude/commands/research.md` (lines 1-302): Research command with full dependencies
- `/home/benjamin/.config/.claude/commands/revise.md` (lines 1-613): Revise command with full dependencies
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-736): Debug command with full dependencies
- `/home/benjamin/.config/.claude/commands/setup.md` (lines 1-312): Setup command with full dependencies
- `/home/benjamin/.config/.claude/commands/expand.md` (lines 1-1124): Expand command with full dependencies
- `/home/benjamin/.config/.claude/commands/collapse.md` (lines 1-739): Collapse command with full dependencies
- `/home/benjamin/.config/.claude/commands/convert-docs.md` (lines 1-418): Convert-docs command with full dependencies
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (lines 1-330): Optimize-claude command with full dependencies
- `/home/benjamin/.config/.claude/lib/*.sh`: 57 library files referenced by commands
- `/home/benjamin/.config/.claude/agents/*.md`: 17 agent files referenced by commands

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_build_commands_included_there_then_move_plan.md](../plans/001_build_commands_included_there_then_move_plan.md)
- **Implementation**: [Will be updated by build command]
- **Date**: 2025-11-19
