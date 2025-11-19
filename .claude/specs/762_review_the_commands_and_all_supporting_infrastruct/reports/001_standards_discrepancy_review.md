# Standards Discrepancy Review Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Review commands and supporting infrastructure for discrepancies with .claude/docs/ standards
- **Report Type**: codebase analysis

## Executive Summary

Critical discrepancies exist between the .claude/ infrastructure and documented standards. The most severe issues are: (1) agent-registry.json references 6 behavioral files that don't exist, causing runtime failures; (2) commands/README.md references archived commands (/implement, /plan, /debug, /research, /revise) as active; (3) multiple command and agent files exceed the documented size limits (<250 lines for commands, <400 lines for agents); and (4) 56 documentation files contain broken links to the non-existent `command-development-guide.md`. These discrepancies create confusion and potential execution failures.

## Findings

### 1. Agent Registry Misalignment (CRITICAL)

**Location**: `/home/benjamin/.config/.claude/agents/agent-registry.json`

The agent registry references behavioral files that do not exist:

| Agent Name | Expected File | Status |
|------------|---------------|--------|
| code-reviewer | .claude/agents/code-reviewer.md | **MISSING** |
| code-writer | .claude/agents/code-writer.md | **MISSING** |
| doc-writer | .claude/agents/doc-writer.md | **MISSING** |
| test-specialist | .claude/agents/test-specialist.md | **MISSING** |
| implementation-executor | .claude/agents/implementation-executor.md | **MISSING** |
| doc-converter-usage | .claude/agents/doc-converter-usage.md | **MISSING** (documentation, not agent) |

**Evidence**:
- agent-registry.json lines 48-67 (code-reviewer), 68-88 (code-writer), 148-168 (doc-writer), 292-310 (test-specialist), 326-346 (implementation-executor), 311-325 (doc-converter-usage)
- Actual agents directory contains only 24 agents (excluding README)

**Impact**: Commands attempting to invoke these agents will fail.

### 2. Command File Size Violations

**Standard**: Commands <250 lines, Agents <400 lines (code-standards.md lines 36-37)

**Commands Exceeding Limit** (>250 lines):
- `coordinate.md`: 2,513 lines (10x over limit)
- `expand.md`: 1,123 lines (4x over limit)
- `collapse.md`: 738 lines (3x over limit)
- `build.md`: 715 lines (3x over limit)
- `fix.md`: 608 lines (2x over limit)
- `research-plan.md`: 497 lines (2x over limit)
- `research-revise.md`: 491 lines (2x over limit)
- `convert-docs.md`: 417 lines (1.7x over limit)
- `research-report.md`: 362 lines (1.4x over limit)
- `optimize-claude.md`: 329 lines (1.3x over limit)
- `setup.md`: 311 lines (1.2x over limit)

**Agents Exceeding Limit** (>400 lines):
- `spec-updater.md`: 1,075 lines (2.7x over limit)
- `plan-structure-manager.md`: 1,070 lines (2.7x over limit)
- `debug-specialist.md`: 1,054 lines (2.6x over limit)
- `doc-converter.md`: 952 lines (2.4x over limit)
- `plan-architect.md`: 894 lines (2.2x over limit)
- `research-specialist.md`: 670 lines (1.7x over limit)
- `cleanup-plan-architect.md`: 623 lines (1.6x over limit)
- `implementation-sub-supervisor.md`: 579 lines (1.4x over limit)
- `testing-sub-supervisor.md`: 573 lines (1.4x over limit)
- `github-specialist.md`: 573 lines (1.4x over limit)
- `revision-specialist.md`: 551 lines (1.4x over limit)
- `metrics-specialist.md`: 540 lines (1.4x over limit)
- `workflow-classifier.md`: 538 lines (1.3x over limit)
- `plan-complexity-classifier.md`: 531 lines (1.3x over limit)
- `docs-structure-analyzer.md`: 492 lines (1.2x over limit)
- `research-sub-supervisor.md`: 491 lines (1.2x over limit)
- `implementer-coordinator.md`: 478 lines (1.2x over limit)
- `debug-analyst.md`: 462 lines (1.2x over limit)
- `claude-md-analyzer.md`: 456 lines (1.1x over limit)
- `complexity-estimator.md`: 425 lines (1.1x over limit)
- `docs-accuracy-analyzer.md`: 419 lines (1.05x over limit)

### 3. commands/README.md References Archived Commands

**Location**: `/home/benjamin/.config/.claude/commands/README.md`

The README documents the following archived commands as if they are active:
- `/implement` (lines 137-149) - Should reference `/build`
- `/plan` (lines 156-165) - Should reference `/research-plan`
- `/debug` (lines 237-251) - Should reference `/fix`
- `/research` (lines 189-200) - Should reference `/research-report`
- `/revise` (lines 325-337) - Should reference `/research-revise`

**Discrepancy with**: `/home/benjamin/.config/.claude/docs/reference/command-reference.md` which correctly marks these as ARCHIVED.

### 4. Broken Documentation Links (56 Files)

**Pattern**: 56 files reference `command-development-guide.md` which doesn't exist.

The file was split into 5 parts:
- `command-development-index.md` (index)
- `command-development-fundamentals.md`
- `command-development-standards-integration.md`
- `command-development-advanced-patterns.md`
- `command-development-examples-case-studies.md`

**Verified Broken Link**:
- `/home/benjamin/.config/.claude/docs/concepts/architectural-decision-framework.md` - references `../guides/command-development-guide.md` (Status: 400)

### 5. Naming Convention Violations

**Standard**: Use kebab-case for bash scripts, prefer hyphens over underscores (directory-organization.md lines 194-196)

**Files with underscores**:
- `/home/benjamin/.config/.claude/lib/validate_executable_doc_separation.sh`

**Test fixtures with underscores** (acceptable for test data):
- Multiple files in `lib/fixtures/` use underscores (acceptable pattern for test fixtures)

### 6. Shared Directory Emptiness

**Standard**: Commands reference shared documentation in `commands/shared/` (commands/README.md lines 68-76)

**Current State**: `/home/benjamin/.config/.claude/commands/shared/` contains only README.md

**Expected Files** (from README.md):
- workflow-phases.md
- phase-execution.md
- implementation-workflow.md
- setup-modes.md
- bloat-detection.md
- extraction-strategies.md
- standards-analysis.md
- revise-auto-mode.md
- revision-types.md

### 7. Command Reference Agent Misalignment

**Location**: `/home/benjamin/.config/.claude/docs/reference/command-reference.md` lines 614-631

References agents that don't exist:
- `code-writer` (line 614-618)
- `test-specialist` (line 619-624)
- `doc-writer` (line 630-633)

## Recommendations

### 1. Fix Agent Registry (Priority: CRITICAL)
Either create the missing behavioral files or remove the phantom entries from agent-registry.json:
- Create: `code-reviewer.md`, `code-writer.md`, `doc-writer.md`, `test-specialist.md`, `implementation-executor.md`
- Remove `doc-converter-usage` entry (it's documentation, not an agent)

### 2. Update commands/README.md (Priority: HIGH)
Replace archived command documentation with references to their replacements:
- `/implement` -> point to `/build`
- `/plan` -> point to `/research-plan`
- `/debug` -> point to `/fix`
- `/research` -> point to `/research-report` or `/research-plan`
- `/revise` -> point to `/research-revise`

### 3. Fix Broken Links (Priority: HIGH)
Update all 56 files that reference `command-development-guide.md` to use `command-development-index.md` instead.

### 4. Restore Shared Documentation (Priority: MEDIUM)
Either restore the shared documentation files to `commands/shared/` or update the README.md to reflect actual state.

### 5. Rename Underscore File (Priority: LOW)
Rename `validate_executable_doc_separation.sh` to `validate-executable-doc-separation.sh` for consistency.

### 6. Re-evaluate Size Limits (Priority: MEDIUM)
Either:
- Enforce the documented limits by splitting large commands/agents
- Or update the standards to reflect realistic limits (e.g., 500 for commands, 700 for agents)

### 7. Update command-reference.md Agent Section (Priority: MEDIUM)
Update the "Commands by Agent" section to reference actual existing agents or create the referenced agents.

## References

### Standards Documents
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` (lines 36-37) - Size limits
- `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` (lines 194-196) - Naming conventions
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Command documentation

### Files Analyzed
- `/home/benjamin/.config/.claude/agents/agent-registry.json` (386 lines)
- `/home/benjamin/.config/.claude/commands/README.md` (871 lines)
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` (667 lines)
- `/home/benjamin/.config/.claude/docs/guides/command-development-index.md` (80 lines)
- All 12 command files in `/home/benjamin/.config/.claude/commands/`
- All 25 agent files in `/home/benjamin/.config/.claude/agents/`

### Scripts Used for Validation
- `/home/benjamin/.config/.claude/scripts/validate-links-quick.sh` - Link validation
