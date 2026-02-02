# Implementation Plan: Task #20

- **Task**: 20 - Update specs/README.md with directory overview
- **Status**: [COMPLETED]
- **Effort**: 0.5-1 hours
- **Dependencies**: None
- **Research Inputs**: specs/20_update_specs_readme_overview/reports/research-001.md
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: general
- **Lean Intent**: false

## Overview

Update specs/README.md to correct outdated information (project numbering format, lockfile reference) and add missing documentation about the archival workflow via the `/todo` command, state management files, and directory lifecycle.

### Research Integration

The research report identified several gaps and inaccuracies:
1. Project numbering documented as 3-digit zero-padded but actual practice uses unpadded integers
2. `.lockfile` reference is outdated; `next_project_number` is now in TODO.md frontmatter and state.json
3. No documentation of archive/ directory or /todo archival process
4. No documentation of state.json, TODO.md, or archive/state.json roles

## Goals & Non-Goals

**Goals**:
- Correct project numbering documentation to match actual practice (unpadded integers)
- Remove outdated .lockfile reference and document actual next_project_number location
- Add archive/ directory documentation and /todo archival workflow
- Document state management files (state.json, TODO.md, archive/state.json)
- Add directory lifecycle explanation (accumulation -> archival)

**Non-Goals**:
- Complete rewrite of the README (preserve useful existing content)
- Documenting implementation details of /todo command
- Adding new directory structure beyond what exists

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Missing edge cases in archival description | L | M | Reference /todo command docs for accuracy |
| Breaking existing cross-references | L | L | Verify relative paths after edit |

## Implementation Phases

### Phase 1: Fix Project Numbering and Remove Lockfile [COMPLETED]

**Goal**: Correct the outdated project numbering format and remove the non-existent .lockfile reference

**Tasks**:
- [ ] Update project numbering section: change from "3-digit zero-padded" to "unpadded integers"
- [ ] Update directory structure diagram: change `NNN_project_name/` to `{N}_project_name/`
- [ ] Remove `.lockfile` line from directory structure
- [ ] Update the "Project Numbering" section to describe next_project_number location (TODO.md frontmatter, state.json)

**Timing**: 15 minutes

**Files to modify**:
- `specs/README.md` - Update project numbering section and directory structure

**Verification**:
- Directory structure diagram shows `{N}_project_name/` format
- No reference to `.lockfile`
- Project numbering section accurately describes current mechanism

---

### Phase 2: Add Archive and State Management Documentation [COMPLETED]

**Goal**: Document the archive directory, state management files, and /todo archival workflow

**Tasks**:
- [ ] Add new section "State Management Files" documenting state.json, TODO.md, archive/state.json
- [ ] Add new section "Archival Process" documenting /todo command workflow
- [ ] Update directory structure to show archive/ and state files
- [ ] Add brief explanation of directory lifecycle (active -> archived)

**Timing**: 20 minutes

**Files to modify**:
- `specs/README.md` - Add state management and archival sections

**Verification**:
- State management files section exists with clear role descriptions
- Archival process section describes /todo workflow
- Directory structure includes archive/ and state files
- Navigation links remain valid

---

## Testing & Validation

- [ ] All relative paths in README resolve correctly
- [ ] Directory structure matches actual specs/ layout
- [ ] No references to non-existent files (.lockfile)
- [ ] Project numbering documentation matches actual practice (unpadded)

## Artifacts & Outputs

- Updated `specs/README.md` with corrected and expanded documentation

## Rollback/Contingency

If the update introduces errors:
1. Revert specs/README.md using git checkout
2. Review research report findings against actual file state
3. Make incremental corrections based on verification failures
