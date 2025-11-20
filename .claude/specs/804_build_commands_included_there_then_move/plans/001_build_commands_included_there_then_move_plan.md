# Commands README Restructure Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Restructure commands/README.md for workflow documentation
- **Scope**: Reorganize sections, add dependency documentation, enhance architecture diagram
- **Estimated Phases**: 4
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 15.5
- **Research Reports**:
  - [README Restructure Analysis](/home/benjamin/.config/.claude/specs/804_build_commands_included_there_then_move/reports/001_readme_restructure_analysis.md)

## Overview

This plan restructures `/home/benjamin/.config/.claude/commands/README.md` to better highlight the core workflow commands (/research, /plan, /revise, /build) and improve documentation of command dependencies. The restructuring involves replacing the "Command Highlights" section with a "Workflow" section, merging "Integration Benefits" into a refactored "Features" section, enhancing the architecture diagram, adding comprehensive dependency documentation to all commands, and reorganizing command placement.

## Research Summary

Key findings from research report:
- Current README is 797 lines with 17 major sections
- "Command Highlights" (lines 6-26) only shows /build and /plan, missing /research and /revise
- "Integration Benefits" and "Purpose" sections contain overlapping content that should be consolidated
- Command Architecture section uses box-drawing styling consistently, can be enhanced
- Command dependency documentation is incomplete - only lists agents, missing libraries, scripts, templates
- /revise is in "Primary Commands" but should be in "Workflow Commands"
- /setup is in "Primary Commands" but should be in "Utility Commands"

Recommended approach: Execute edits in logical sequence - section replacement first, then section merging, then enhancements, then reorganization.

## Success Criteria
- [ ] "Command Highlights" replaced with "Workflow" section showing /research → /plan → /revise → /build sequence
- [ ] "Integration Benefits" merged into "Purpose" section, renamed to "Features"
- [ ] "Command Architecture" enhanced with detailed multi-layer box diagram
- [ ] All commands in "Available Commands" include complete dependency documentation (agents, libraries, scripts, templates)
- [ ] /revise moved from "Primary Commands" to "Workflow Commands"
- [ ] /setup moved from "Primary Commands" to "Utility Commands"
- [ ] README maintains consistent formatting and navigation

## Technical Design

### Section Restructuring Strategy

The restructuring maintains backward compatibility with existing navigation links while improving content organization:

1. **Workflow Section**: Replaces lines 7-26 (Command Highlights and Integration Benefits)
   - New section shows workflow sequence with bullet points for each command
   - Clear visual flow: /research → /plan → /revise → /build

2. **Features Section**: Replaces lines 28-39 (Purpose)
   - Combines workflow capabilities with technical advantages
   - Two subsections: "Workflow Capabilities" and "Technical Advantages"

3. **Architecture Enhancement**: Enhances lines 41-66
   - Five-layer diagram: User Input → Command Definition → Library → Agent → Output
   - Maintains existing box-drawing style

4. **Dependency Documentation**: Extends each command entry in Available Commands
   - Standard format: Agents, Libraries, Scripts (if any), External Tools (if any)

### Edit Sequence

Edits proceed from top to bottom of file to avoid line number shifts affecting subsequent edits:
1. Replace "Command Highlights" with "Workflow" (lines 7-26)
2. Replace "Purpose" with "Features" (lines 28-39)
3. Enhance "Command Architecture" (lines 41-66)
4. Add dependencies to commands (lines 72-265)
5. Move /revise and /setup to appropriate sections

## Implementation Phases

### Phase 1: Create Workflow Section [COMPLETE]
dependencies: []

**Objective**: Replace "Command Highlights" section with comprehensive "Workflow" section

**Complexity**: Low

Tasks:
- [x] Read current "Command Highlights" section content (lines 7-26)
- [x] Replace lines 7-26 with new "Workflow" section containing:
  - Workflow sequence header: /research → /plan → /revise → /build
  - /research bullet points (research-only workflow, complexity levels, topic organization)
  - /plan bullet points (research + planning, persistent reports, complexity adjustment)
  - /revise bullet points (plan revision, backup creation, research integration)
  - /build bullet points (wave-based execution, testing, commits, progressive structures)

Testing:
```bash
# Verify section replaced
grep -n "## Workflow" /home/benjamin/.config/.claude/commands/README.md
grep -n "Command Highlights" /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Create Features Section [COMPLETE]
dependencies: [1]

**Objective**: Merge "Integration Benefits" into "Purpose" section and rename to "Features"

**Complexity**: Low

Tasks:
- [x] Read current "Purpose" section content (lines 28-39)
- [x] Replace "Purpose" section with new "Features" section containing:
  - "Workflow Capabilities" subsection (research, planning, revision, implementation, debugging)
  - "Technical Advantages" subsection (agent-based execution, topic organization, artifact separation, full automation, error recovery, standards compliance)
- [x] Verify "Integration Benefits" content (from old lines 21-26) is incorporated into "Technical Advantages"

Testing:
```bash
# Verify section replaced
grep -n "## Features" /home/benjamin/.config/.claude/commands/README.md
grep -n "## Purpose" /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 0.5 hours

---

### Phase 3: Enhance Command Architecture [COMPLETE]
dependencies: [2]

**Objective**: Improve "Command Architecture" section with detailed multi-layer box diagram

**Complexity**: Medium

Tasks:
- [x] Read current "Command Architecture" section (lines 41-66)
- [x] Replace with enhanced five-layer architecture diagram:
  - User Input Layer (command invocation)
  - Command Definition Layer (file, frontmatter, instructions, agent references)
  - Library Layer (.claude/lib/ with state machine, persistence, utilities)
  - Agent Layer (.claude/agents/ with research, planning, implementation, debugging)
  - Output Layer (artifacts, state, logs)
- [x] Maintain consistent box-drawing styling (┌┐└┘─│├┤▼)

Testing:
```bash
# Verify architecture section enhanced
grep -c "│" /home/benjamin/.config/.claude/commands/README.md | head -1
grep -n "LIBRARY LAYER\|AGENT LAYER\|OUTPUT LAYER" /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 0.75 hours

---

### Phase 4: Add Dependencies and Reorganize Commands [COMPLETE]
dependencies: [3]

**Objective**: Add complete dependency documentation to all commands and move /revise and /setup to correct sections

**Complexity**: High

Tasks:
- [x] Add dependency documentation to /build entry:
  - Agents: implementer-coordinator, debug-analyst, spec-updater
  - Libraries: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh, checkpoint-utils.sh, checkbox-utils.sh
- [x] Add dependency documentation to /debug entry:
  - Agents: research-specialist, plan-architect, debug-analyst, workflow-classifier
  - Libraries: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh, unified-location-detection.sh, workflow-initialization.sh
- [x] Add dependency documentation to /plan entry:
  - Agents: research-specialist, research-sub-supervisor, plan-architect
  - Libraries: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh, unified-location-detection.sh, workflow-initialization.sh
- [x] Add dependency documentation to /research entry:
  - Agents: research-specialist, research-sub-supervisor
  - Libraries: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh, unified-location-detection.sh, workflow-initialization.sh
- [x] Add dependency documentation to /revise entry:
  - Agents: research-specialist, research-sub-supervisor, plan-architect
  - Libraries: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh
- [x] Add dependency documentation to /setup entry:
  - Dependent Commands: orchestrate (for enhance mode)
  - Libraries: detect-testing.sh, generate-testing-protocols.sh, optimize-claude-md.sh
- [x] Add dependency documentation to /expand entry:
  - Agents: complexity-estimator
  - Libraries: plan-core-bundle.sh, auto-analysis-utils.sh, parse-adaptive-plan.sh
- [x] Add dependency documentation to /collapse entry:
  - Agents: complexity-estimator
  - Libraries: plan-core-bundle.sh, auto-analysis-utils.sh
- [x] Add dependency documentation to /convert-docs entry:
  - Agents: doc-converter
  - Libraries: convert-core.sh
  - External Tools: MarkItDown, Pandoc, PyMuPDF4LLM
- [x] Add dependency documentation to /optimize-claude entry:
  - Agents: claude-md-analyzer, docs-structure-analyzer, docs-bloat-analyzer, docs-accuracy-analyzer, cleanup-plan-architect
  - Libraries: unified-location-detection.sh, optimize-claude-md.sh
- [x] Move /revise from "Primary Commands" to "Workflow Commands" section (after /collapse)
- [x] Move /setup from "Primary Commands" to "Utility Commands" section (before /optimize-claude)
- [x] Update "Command Types" section to reflect new command placements

Testing:
```bash
# Verify dependencies added
grep -c "**Dependencies**:" /home/benjamin/.config/.claude/commands/README.md

# Verify /revise in Workflow Commands
grep -B5 "/revise" /home/benjamin/.config/.claude/commands/README.md | grep "Workflow Commands"

# Verify /setup in Utility Commands
grep -B5 "/setup" /home/benjamin/.config/.claude/commands/README.md | grep "Utility Commands"

# Verify all commands have dependency sections
for cmd in build debug plan research revise setup expand collapse convert-docs optimize-claude; do
  grep -A20 "#### /$cmd" /home/benjamin/.config/.claude/commands/README.md | grep -q "**Dependencies**:" && echo "$cmd: OK" || echo "$cmd: MISSING"
done
```

**Expected Duration**: 1.25 hours

## Testing Strategy

### Validation Approach
1. **Section Structure**: Verify all new sections exist and old sections removed
2. **Content Completeness**: Check all workflow commands documented in Workflow section
3. **Dependency Coverage**: Verify all 10 commands have complete dependency documentation
4. **Command Placement**: Confirm /revise in Workflow Commands, /setup in Utility Commands
5. **Formatting Consistency**: Validate box-drawing characters render correctly

### Test Commands
```bash
# Full validation suite
cd /home/benjamin/.config/.claude/commands

# 1. Section existence
grep -n "## Workflow" README.md
grep -n "## Features" README.md
grep -n "## Command Architecture" README.md

# 2. Old sections removed
! grep -n "## Command Highlights" README.md
! grep -n "## Purpose" README.md

# 3. Workflow commands present
grep -c "/research\|/plan\|/revise\|/build" README.md

# 4. Dependencies documented (should be 10)
grep -c "**Dependencies**:" README.md

# 5. Architecture layers present
grep -c "LAYER" README.md
```

## Documentation Requirements

- Update commands README itself (this is the target document)
- No additional documentation files needed
- Ensure all internal links remain valid after reorganization

## Dependencies

### Prerequisites
- Read access to /home/benjamin/.config/.claude/commands/README.md
- Research report: /home/benjamin/.config/.claude/specs/804_build_commands_included_there_then_move/reports/001_readme_restructure_analysis.md

### External Dependencies
- None (pure documentation refactoring)

## Risk Mitigation

1. **Line Number Shifts**: Execute edits top-to-bottom to minimize line number recalculation
2. **Navigation Link Breakage**: Verify all internal links after reorganization
3. **Content Loss**: Ensure all "Integration Benefits" content incorporated into "Features"
