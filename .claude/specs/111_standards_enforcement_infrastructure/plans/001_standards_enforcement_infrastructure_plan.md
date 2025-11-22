# Standards Enforcement Infrastructure Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: Standards Enforcement Infrastructure
- **Scope**: Systematic enhancement of .claude/docs/ standards documentation with enforcement mechanisms, anti-pattern documentation, and unified validation infrastructure
- **Estimated Phases**: 6
- **Estimated Hours**: 14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 70.5
- **Research Reports**:
  - [Standards Enforcement Research](../reports/001_standards_enforcement_research.md)

## Overview

This plan addresses the systematic gaps identified in research report 001: standards are well-documented but enforcement mechanisms are fragmented, anti-patterns are inconsistently documented, and no unified validation framework exists. The implementation creates a cohesive enforcement infrastructure that prevents recurring violations like those discovered in Plans 105 (bash sourcing) and 891 (empty directories).

## Research Summary

Key findings from research report analysis:

1. **Current State**: 11 standards documents exist in .claude/docs/reference/standards/ but only 3 have automated enforcement (partial coverage)
2. **Enforcement Gap**: Pre-commit hook only prevents backup file commits; does not run linters or validators
3. **Anti-Pattern Documentation**: Anti-patterns documented inconsistently - some in standards files, some only in linter code, some undocumented
4. **Plan 105 Incomplete**: Phases 5-7 (pre-commit integration, documentation updates, standards enforcement documentation) remain NOT STARTED
5. **Plan 891 Insights**: Lazy directory creation anti-pattern well-documented but no agent-level enforcement exists

Recommended approach: Create unified enforcement-mechanisms.md as single source of truth, enhance pre-commit hook to run validators, consolidate anti-patterns into dedicated reference document, and add agent behavioral guidelines for directory creation policy.

## Success Criteria

- [ ] code-standards.md includes Mandatory Patterns section with enforcement references
- [ ] enforcement-mechanisms.md exists as unified enforcement reference (single source of truth)
- [ ] bash-block-execution-model.md includes consolidated Anti-Patterns section
- [ ] agent-behavioral-guidelines.md documents directory creation policy
- [ ] CLAUDE.md includes Code Quality Enforcement section with validator commands
- [ ] validate-all-standards.sh orchestrates all validation scripts with unified reporting
- [ ] Pre-commit hook runs critical validators on staged files
- [ ] All 6 existing linters integrated into unified validation framework
- [ ] Standards-to-enforcement bidirectional traceability documented
- [ ] Test coverage for enforcement infrastructure achieves >90%

## Technical Design

### Architecture Overview

```
.claude/
├── docs/reference/standards/
│   ├── enforcement-mechanisms.md      # NEW: Single source of truth
│   ├── code-standards.md              # UPDATE: Add Mandatory Patterns section
│   ├── agent-behavioral-guidelines.md # NEW: Agent-level policies
│   └── ...
├── docs/concepts/
│   └── bash-block-execution-model.md  # UPDATE: Add Anti-Patterns section
├── scripts/
│   ├── validate-all-standards.sh      # NEW: Unified orchestrator
│   └── lint/
│       └── check-library-sourcing.sh  # EXISTING
├── tests/utilities/
│   ├── lint_error_suppression.sh      # EXISTING
│   └── ...
└── .git/hooks/
    └── pre-commit                     # UPDATE: Run validators
```

### Enforcement Flow

```
Developer commits code
       ↓
.git/hooks/pre-commit
       ↓
┌─────────────────────────────────────┐
│ validate-all-standards.sh (staged)  │
├─────────────────────────────────────┤
│ • check-library-sourcing.sh         │
│ • lint_error_suppression.sh         │
│ • validate-readmes.sh --quick       │
│ • validate-links-quick.sh           │
└─────────────────────────────────────┘
       ↓
Pass: Commit proceeds
Fail: Commit blocked with documentation link
```

### Standards Traceability Matrix

| Standard Document | Enforcement Tool | Pre-Commit | Severity |
|-------------------|------------------|------------|----------|
| code-standards.md | check-library-sourcing.sh | Yes | ERROR |
| code-standards.md | lint_error_suppression.sh | Yes | ERROR |
| output-formatting.md | lint_error_suppression.sh | Yes | ERROR |
| documentation-standards.md | validate-readmes.sh | Yes (quick) | WARNING |
| code-standards.md (links) | validate-links-quick.sh | Yes | WARNING |
| agent-behavioral-guidelines.md | validate-agent-directory-creation.sh | No (manual) | WARNING |

## Implementation Phases

### Phase 1: Create Enforcement Mechanisms Reference [COMPLETE]
dependencies: []

**Objective**: Create enforcement-mechanisms.md as the single source of truth for all enforcement tools and their integration with standards.

**Complexity**: Medium

Tasks:
- [x] Create `.claude/docs/reference/standards/enforcement-mechanisms.md` with structure:
  - Purpose and scope section
  - Enforcement tool inventory table (script path, checks performed, severity)
  - Pre-commit integration section
  - CI/CD integration section (future-ready placeholder)
  - Standards-to-tool mapping matrix
  - How to add new enforcement section
- [x] Document all 6 existing validators with their check patterns:
  - `scripts/lint/check-library-sourcing.sh` - bash sourcing patterns
  - `scripts/validate-readmes.sh` - README structure
  - `scripts/validate-links.sh` / `validate-links-quick.sh` - internal links
  - `scripts/validate-agent-behavioral-file.sh` - agent file structure
  - `tests/utilities/lint_error_suppression.sh` - error suppression anti-patterns
  - `tests/utilities/lint_bash_conditionals.sh` - bash conditional patterns
- [x] Add severity classification (ERROR=blocking, WARNING=informational)
- [x] Document bypass mechanism (`--no-verify`) with appropriate warnings

Testing:
```bash
# Verify file structure
test -f .claude/docs/reference/standards/enforcement-mechanisms.md
grep -q "## Enforcement Tool Inventory" .claude/docs/reference/standards/enforcement-mechanisms.md
grep -q "## Pre-Commit Integration" .claude/docs/reference/standards/enforcement-mechanisms.md
```

**Expected Duration**: 2 hours

### Phase 2: Update code-standards.md with Mandatory Patterns [COMPLETE]
dependencies: [1]

**Objective**: Add Mandatory Patterns section to code-standards.md that explicitly lists required patterns with enforcement references.

**Complexity**: Medium

Tasks:
- [x] Add `## Mandatory Patterns` section after existing content with subsections:
  - Bash Library Sourcing (mandatory fail-fast pattern)
  - Error Suppression Policy (what can/cannot be suppressed)
  - Directory Creation Policy (lazy creation requirement)
- [x] Add `## Enforcement` section at end of file with:
  - Automated Validation subsection listing applicable validators
  - Validation Command subsection with exact commands to run
  - Pre-Commit Integration note explaining automatic enforcement
- [x] Cross-reference enforcement-mechanisms.md for complete enforcement details
- [x] Update existing "Output Suppression Patterns" section to reference enforcement
- [x] Ensure all mandatory patterns include:
  - Clear MUST/NEVER language
  - Code examples (correct and incorrect)
  - Link to enforcement tool
  - Link to detailed rationale (bash-block-execution-model.md)

Testing:
```bash
# Verify new sections exist
grep -q "## Mandatory Patterns" .claude/docs/reference/standards/code-standards.md
grep -q "## Enforcement" .claude/docs/reference/standards/code-standards.md
grep -q "enforcement-mechanisms.md" .claude/docs/reference/standards/code-standards.md
```

**Expected Duration**: 2 hours

### Phase 3: Add Anti-Patterns Section to bash-block-execution-model.md [COMPLETE]
dependencies: [1]

**Objective**: Consolidate anti-patterns into dedicated section in bash-block-execution-model.md and ensure all anti-patterns from linters are documented.

**Complexity**: Medium

Tasks:
- [x] Review existing anti-patterns in bash-block-execution-model.md (currently inline with patterns)
- [x] Create consolidated `## Anti-Patterns Reference` section with standardized format:
  - Anti-Pattern name and ID
  - Description
  - Code example showing anti-pattern
  - Why it's problematic
  - Correct pattern
  - Detection method (linter/manual)
- [x] Add anti-patterns currently only documented in linter code:
  - State persistence error suppression (lint_error_suppression.sh:36-63)
  - Deprecated state paths (lint_error_suppression.sh:109-134)
  - Missing defensive type checks (check-library-sourcing.sh:94-123)
- [x] Add cross-references to enforcement-mechanisms.md
- [x] Update table of contents if present

Testing:
```bash
# Verify anti-patterns section exists
grep -q "## Anti-Patterns Reference" .claude/docs/concepts/bash-block-execution-model.md
# Verify all documented anti-patterns from linters are included
grep -q "State Persistence Error Suppression" .claude/docs/concepts/bash-block-execution-model.md
grep -q "Deprecated State Paths" .claude/docs/concepts/bash-block-execution-model.md
```

**Expected Duration**: 2 hours

### Phase 4: Create Agent Behavioral Guidelines [COMPLETE]
dependencies: [1]

**Objective**: Create agent-behavioral-guidelines.md documenting policies that apply specifically to AI agents, including directory creation policy from Plan 891.

**Complexity**: Medium

Tasks:
- [x] Create `.claude/docs/reference/standards/agent-behavioral-guidelines.md` with sections:
  - Purpose: Agent-specific policies not covered in code-standards.md
  - Directory Creation Policy (lazy creation, ensure_artifact_directory timing)
  - State Persistence Policy (output-based pattern, not bash execution in agents)
  - Error Return Protocol (structured error signals for parent parsing)
  - Tool Access Guidelines (what tools require what capabilities)
- [x] Document lazy directory creation requirement from Plan 891:
  - Timing requirement: ensure_artifact_directory called immediately before Write tool
  - Anti-pattern: calling ensure_artifact_directory at agent startup
  - Cleanup consideration: agents cannot guarantee cleanup on failure
- [x] Add Task tool subprocess isolation constraints
- [x] Cross-reference bash-block-execution-model.md for technical details
- [x] Add to docs/reference/standards/README.md index

Testing:
```bash
# Verify file exists and has required sections
test -f .claude/docs/reference/standards/agent-behavioral-guidelines.md
grep -q "## Directory Creation Policy" .claude/docs/reference/standards/agent-behavioral-guidelines.md
grep -q "ensure_artifact_directory" .claude/docs/reference/standards/agent-behavioral-guidelines.md
```

**Expected Duration**: 2 hours

### Phase 5: Create Unified Validation Script [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Create validate-all-standards.sh that orchestrates all validation scripts with unified reporting and selective execution support.

**Complexity**: High

Tasks:
- [x] Create `.claude/scripts/validate-all-standards.sh` with:
  - Argument parsing for selective validation (--readme, --sourcing, --links, --all)
  - Staged-files mode (--staged) for pre-commit integration
  - Unified output format with pass/fail per validator
  - Exit code aggregation (any ERROR=1, only WARNINGS=0)
  - Summary report with links to violated standards
- [x] Integrate all 6 validators:
  - scripts/lint/check-library-sourcing.sh
  - scripts/validate-readmes.sh (with --quick flag for staged mode)
  - scripts/validate-links-quick.sh
  - scripts/validate-agent-behavioral-file.sh
  - tests/utilities/lint_error_suppression.sh
  - tests/utilities/lint_bash_conditionals.sh
- [x] Add file type filtering (only check relevant validators per file extension)
- [x] Add documentation link output on failure:
  - "See .claude/docs/reference/standards/enforcement-mechanisms.md for details"
- [x] Make script executable with proper shebang and error handling

Testing:
```bash
# Verify script exists and is executable
test -x .claude/scripts/validate-all-standards.sh
# Verify help output
bash .claude/scripts/validate-all-standards.sh --help | grep -q "Usage"
# Verify selective execution
bash .claude/scripts/validate-all-standards.sh --sourcing --dry-run 2>&1 | grep -q "check-library-sourcing"
```

**Expected Duration**: 3 hours

### Phase 6: Enhance Pre-Commit Hook and Update CLAUDE.md [COMPLETE]
dependencies: [5]

**Objective**: Update pre-commit hook to run validators on staged files and add Code Quality Enforcement section to CLAUDE.md.

**Complexity**: Medium

Tasks:
- [x] Update `.git/hooks/pre-commit` to:
  - Keep existing backup file check
  - Add validator execution for staged .md and .sh files
  - Call `validate-all-standards.sh --staged` with staged file list
  - Output clear failure messages with documentation links
  - Preserve --no-verify bypass capability
- [x] Add `<!-- SECTION: code_quality_enforcement -->` section to CLAUDE.md with:
  - Quick reference to enforcement tools
  - Common validation commands
  - Pre-commit behavior explanation
  - Link to enforcement-mechanisms.md for complete details
- [x] Update `<!-- SECTION: code_standards -->` to reference new enforcement section
- [x] Create integration test for pre-commit hook:
  - Test with violating file (should fail)
  - Test with clean file (should pass)
  - Test --no-verify bypass

Testing:
```bash
# Verify pre-commit hook has validator integration
grep -q "validate-all-standards.sh" .git/hooks/pre-commit
# Verify CLAUDE.md has enforcement section
grep -q "code_quality_enforcement" CLAUDE.md
# Integration test: Create temp branch, add violating file, attempt commit
```

**Expected Duration**: 3 hours

## Testing Strategy

### Unit Tests
- Each validator script has standalone test capability
- validate-all-standards.sh tested with --dry-run flag
- Pre-commit hook tested with mock staged files

### Integration Tests
- End-to-end pre-commit hook test with actual commit attempt
- Validate bidirectional links between standards and enforcement-mechanisms.md
- Verify all anti-patterns in bash-block-execution-model.md have detection methods

### Regression Tests
- Run full validation suite against current codebase
- Ensure no false positives from new enforcement
- Verify existing tests still pass

### Coverage Requirements
- All 6 validators integrated into unified script
- All documented anti-patterns have detection mechanisms
- Pre-commit hook coverage for .md and .sh files in .claude/

## Documentation Requirements

### Files to Create
- `.claude/docs/reference/standards/enforcement-mechanisms.md` - Phase 1
- `.claude/docs/reference/standards/agent-behavioral-guidelines.md` - Phase 4
- `.claude/scripts/validate-all-standards.sh` - Phase 5

### Files to Update
- `.claude/docs/reference/standards/code-standards.md` - Phase 2
- `.claude/docs/concepts/bash-block-execution-model.md` - Phase 3
- `.claude/docs/reference/standards/README.md` - Phase 1, 4 (index updates)
- `.git/hooks/pre-commit` - Phase 6
- `CLAUDE.md` - Phase 6

### Cross-Reference Updates
- enforcement-mechanisms.md must reference all validator scripts
- code-standards.md must reference enforcement-mechanisms.md
- bash-block-execution-model.md must reference enforcement-mechanisms.md
- agent-behavioral-guidelines.md must reference bash-block-execution-model.md

## Dependencies

### Prerequisites
- Research report 001 completed (done)
- Existing validator scripts functional (verified)
- Pre-commit hook exists (verified)

### External Dependencies
- None

### Internal Dependencies
- Phase dependencies enable parallel execution:
  - Phase 1 must complete before Phases 2, 3, 4, 5
  - Phases 2, 3, 4 can execute in parallel after Phase 1
  - Phase 5 requires Phases 1-4 complete
  - Phase 6 requires Phase 5 complete

## Risk Assessment

### Technical Risks
- **Pre-commit hook performance**: Mitigated by --staged flag and quick validators
- **False positives blocking commits**: Mitigated by WARNING vs ERROR severity distinction
- **Validator compatibility**: All validators tested standalone before integration

### Implementation Risks
- **Scope creep**: Plan focuses on existing validators only, no new detection logic
- **Documentation drift**: Bidirectional traceability ensures updates propagate

## Notes

- This plan completes work left incomplete in Plan 105 (Phases 5-7)
- Anti-pattern documentation consolidation benefits from Plan 891 insights
- Complexity score (70.5) suggests potential for `/expand` during Phase 5 (validation script)
