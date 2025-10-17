# Automatic Ancestor Plan Updates and Cross-Referencing System

## Metadata
- **Date**: 2025-10-16
- **Feature**: Automatic Ancestor Plan Updates and Standardized Cross-Referencing
- **Scope**: Refactor plan update mechanisms to automatically propagate updates through plan hierarchies and standardize bidirectional cross-referencing between reports, plans, and summaries
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: None (internal refactoring based on system analysis)

## Overview

This refactoring addresses critical gaps in the plan update and cross-referencing systems:

1. **Automatic Ancestor Updates**: Currently, when a Level 2 stage or Level 1 phase completes, only the immediate parent is updated. Grandparent plans remain out of sync. This refactor implements automatic propagation through the entire hierarchy.

2. **Standardized Cross-Referencing**: Cross-references between reports, plans, and summaries are manually maintained and inconsistently applied. This refactor creates unified utilities and integration points for automatic bidirectional linking.

3. **Unified Integration**: Both `/implement` and `/orchestrate` will use consistent update mechanisms, eliminating duplication and ensuring comprehensive cross-reference maintenance.

## Success Criteria
- [x] Ancestor plan updates occur automatically when any phase/stage completes
- [x] Standardized metadata sections for cross-references in all artifact types
- [x] Both `/implement` and `/orchestrate` maintain complete bidirectional links
- [x] No manual propagation required - fully automatic
- [x] Backward compatible with existing plan hierarchies and flat structures
- [x] Test coverage ≥80% for new update utilities
- [x] Documentation updated to reflect new automatic behaviors

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  Implementer Agent                          │
│           (code-writer in /implement or /orchestrate)       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Invokes after phase completion
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Spec-Updater Agent (Enhanced)                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1. Detect plan structure level (0/1/2)              │  │
│  │  2. Update current plan/phase/stage checkboxes       │  │
│  │  3. **NEW**: Propagate to ALL ancestors              │  │
│  │  4. **NEW**: Update cross-references bidirectionally │  │
│  │  5. Verify consistency across hierarchy              │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Uses enhanced utilities
                         ↓
┌─────────────────────────────────────────────────────────────┐
│           Enhanced Utilities Library                        │
│  ┌────────────────────┐  ┌─────────────────────────────┐   │
│  │ checkbox-utils.sh  │  │ cross-reference-utils.sh    │   │
│  │ (Enhanced)         │  │ (NEW)                       │   │
│  │                    │  │                             │   │
│  │ - mark_phase_      │  │ - add_report_to_plan()      │   │
│  │   complete()       │  │ - add_plan_to_summary()     │   │
│  │ - propagate_to_    │  │ - update_bidirectional_     │   │
│  │   ancestors()      │  │   refs()                    │   │
│  │   **NEW**          │  │ - validate_cross_refs()     │   │
│  └────────────────────┘  └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. Enhanced checkbox-utils.sh
**New Function**: `propagate_to_ancestors()`
- Detects current plan structure level
- Recursively updates parent plans up to root
- Maintains consistency across all hierarchy levels

#### 2. New cross-reference-utils.sh
**Purpose**: Centralized cross-reference management
- `add_report_to_plan()`: Links research reports to plans
- `add_plan_to_summary()`: Links plans to summaries (detects highest-level plan)
- `update_bidirectional_refs()`: Ensures two-way references
- `validate_cross_refs()`: Verifies link integrity

#### 3. Enhanced spec-updater Agent
**New Responsibilities**:
- Automatic ancestor update invocation
- Cross-reference synchronization during updates
- Metadata section standardization

#### 4. Command Integration Updates
**Files to Modify**:
- `.claude/commands/implement.md`: Use enhanced spec-updater
- `.claude/commands/orchestrate.md`: Use enhanced spec-updater
- Both commands will use identical update logic (DRY principle)

### Data Flow

```
Phase Completion Event
        ↓
Implementer Agent → git commit succeeds
        ↓
Spec-Updater Agent invoked with:
  - plan_path
  - phase_number
  - research_reports (optional)
        ↓
Spec-Updater executes:
  1. mark_phase_complete(plan, phase)
  2. propagate_to_ancestors(plan)  ← NEW
  3. update_bidirectional_refs(plan, reports, summary)  ← NEW
  4. verify_consistency()
        ↓
Checkpoint: hierarchy_updated=true, refs_updated=true
        ↓
Implementation continues or workflow completes
```

## Implementation Phases

### Phase 1: Create Cross-Reference Utilities Library
**Objective**: Build centralized utilities for managing bidirectional cross-references between artifacts
**Complexity**: Medium

Tasks:
- [ ] Create `.claude/lib/cross-reference-utils.sh` with core functions
- [ ] Implement `add_report_to_plan()`: Adds report link to plan metadata section
  - Uses standardized metadata format: `**Research Reports**: [relative/path](link)`
  - Creates metadata section if missing
  - Handles both flat and topic-based structures
- [ ] Implement `add_plan_to_summary()`: Adds plan link to summary
  - Detects highest-level plan in hierarchy (main plan, not leaf phase/stage)
  - Uses relative path for portability
  - Format: `**Plan**: [path](link)`
- [ ] Implement `update_bidirectional_refs()`: Synchronizes two-way references
  - Updates report with "Used in Implementation: [plan]" section
  - Updates summary with both plan and report references
  - Maintains consistency across all linked artifacts
- [ ] Implement `validate_cross_refs()`: Verifies link integrity
  - Checks all referenced files exist
  - Validates relative path correctness
  - Reports broken or missing links
- [ ] Add error handling and logging for all functions

Testing:
```bash
# Test cross-reference utilities
.claude/tests/test_cross_reference_utils.sh
# Expected: All functions create/update cross-references correctly
```

**Validation Criteria**:
- All functions handle edge cases (missing files, malformed metadata)
- Relative paths work across different directory structures
- Bidirectional links remain synchronized after updates

---

### Phase 2: Enhance checkbox-utils.sh with Ancestor Propagation
**Objective**: Add automatic ancestor plan update functionality to existing checkbox utilities
**Complexity**: High

Tasks:
- [ ] Read current `.claude/lib/checkbox-utils.sh` implementation
- [ ] Implement `propagate_to_ancestors()` function:
  - Detects current plan structure level (0/1/2) using `detect_structure_level()`
  - For Level 2 (stage): Updates phase file → updates main plan
  - For Level 1 (phase): Updates main plan
  - For Level 0 (single file): No propagation needed
  - Recursively traverses hierarchy to root
- [ ] Implement `detect_ancestor_plan()` helper:
  - Parses directory structure to identify parent plan
  - Handles both phase files (Level 1) and stage files (Level 2)
  - Returns parent plan path or null if at root
- [ ] Enhance `mark_phase_complete()` to invoke `propagate_to_ancestors()`:
  - After updating current plan checkboxes
  - Before verification step
  - Logs all ancestor updates for debugging
- [ ] Update `verify_checkbox_consistency()` to check all ancestors:
  - Validates consistency from leaf to root
  - Ensures parent checkboxes reflect child completion
  - Reports inconsistencies with specific file paths
- [ ] Add comprehensive error handling for hierarchy traversal edge cases

Testing:
```bash
# Test ancestor propagation
.claude/tests/test_ancestor_propagation.sh

# Test cases:
# 1. Level 2 stage completion → phase and main plan updated
# 2. Level 1 phase completion → main plan updated
# 3. Level 0 completion → no propagation (success)
# 4. Malformed hierarchy → graceful error handling
```

**Validation Criteria**:
- All ancestors updated correctly for Level 1 and Level 2 structures
- Checkbox states consistent from leaf to root
- No duplicate updates or infinite loops
- Graceful handling of missing or malformed parent plans

---

### Phase 3: Enhance spec-updater Agent with New Capabilities
**Objective**: Integrate new utilities into spec-updater agent for automatic cross-referencing and ancestor updates
**Complexity**: Medium

Tasks:
- [ ] Read current `.claude/agents/spec-updater.md` implementation
- [ ] Add cross-reference management to agent protocol:
  - Source `cross-reference-utils.sh` alongside `checkbox-utils.sh`
  - Accept `research_reports` parameter (optional array of report paths)
  - Accept `summary_path` parameter (optional, for final workflow summary)
- [ ] Update agent workflow in spec-updater.md:
  - **Step 1**: Execute `mark_phase_complete(plan, phase)` (existing)
  - **Step 2**: Execute `propagate_to_ancestors(plan)` (NEW)
  - **Step 3**: If research_reports provided: `update_bidirectional_refs(plan, reports)` (NEW)
  - **Step 4**: If summary_path provided: `add_plan_to_summary(summary, plan)` (NEW)
  - **Step 5**: Execute `verify_checkbox_consistency(plan)` (existing)
  - **Step 6**: Execute `validate_cross_refs(plan)` (NEW)
- [ ] Add reporting section to agent output:
  - List all ancestors updated (with paths)
  - List all cross-references added/updated
  - Report any validation errors or warnings
- [ ] Update agent examples to demonstrate new capabilities
- [ ] Add error recovery instructions for cross-reference failures

Testing:
```bash
# Test spec-updater agent with new capabilities
.claude/tests/test_spec_updater_enhanced.sh

# Test scenarios:
# 1. Phase completion with ancestor updates
# 2. Phase completion with report cross-referencing
# 3. Phase completion with summary cross-referencing
# 4. Combined: ancestors + reports + summary
```

**Validation Criteria**:
- Agent successfully invokes all new utilities
- Output clearly reports all updates performed
- Error handling prevents partial updates
- Backward compatible with existing agent invocations (no research_reports/summary_path)

---

### Phase 4: Integrate Enhanced Updates into /implement Command
**Objective**: Refactor /implement to use enhanced spec-updater with automatic ancestor updates and cross-referencing
**Complexity**: Medium

Tasks:
- [ ] Read `.claude/commands/implement.md` Step 5 (current spec-updater integration)
- [ ] Update spec-updater invocation in /implement Step 5:
  - Pass `research_reports` parameter extracted from plan metadata
  - Add checkpoint field: `cross_refs_updated: true|false`
  - Update agent prompt to use enhanced protocol (ancestor updates + cross-refs)
- [ ] Modify checkpoint structure to track new updates:
  - Add `ancestors_updated: [list of parent plan paths]`
  - Add `cross_references_added: [list of {type, source, target}]`
  - Preserve existing `hierarchy_updated: true` for backward compatibility
- [ ] Update /implement output to report new updates:
  - Display "Ancestor plans updated: N" with paths
  - Display "Cross-references added: N" with summary
  - Maintain existing concise output format
- [ ] Add error handling for cross-reference failures:
  - If cross-ref update fails: Log warning but continue (non-blocking)
  - If ancestor update fails: Log error and report to user
  - Preserve checkpoint for recovery

Testing:
```bash
# Integration test: /implement with enhanced updates
.claude/tests/test_implement_enhanced_updates.sh

# Test plan with:
# - Level 1 structure (phases)
# - Research reports in metadata
# - Multiple phases to complete
# Expected: All ancestors and cross-refs updated after each phase
```

**Validation Criteria**:
- /implement successfully updates ancestors after each phase
- Research reports automatically linked to plan
- Checkpoint accurately reflects all updates performed
- Backward compatible with existing /implement behavior

---

### Phase 5: Integrate Enhanced Updates into /orchestrate Command
**Objective**: Refactor /orchestrate Documentation Phase to use enhanced spec-updater with cross-referencing for workflow summaries
**Complexity**: Medium

Tasks:
- [ ] Read `.claude/commands/orchestrate.md` Documentation Phase (lines ~2660-2704)
- [ ] Update spec-updater invocation in Documentation Phase:
  - Pass `research_reports` from workflow context (if research phase completed)
  - Pass `summary_path` after workflow summary is created
  - Update agent prompt to use enhanced protocol
- [ ] Modify workflow summary generation to include cross-reference metadata:
  - Add standardized "Research Reports" section with relative links
  - Add standardized "Implementation Plan" section (highest-level plan only)
  - Ensure summary uses relative paths for portability
- [ ] Update orchestrate workflow checkpoint:
  - Track `all_ancestors_updated: true|false`
  - Track `workflow_cross_refs_complete: true|false`
- [ ] Enhance final workflow output message:
  - Report "Plan hierarchy fully synchronized" if ancestors updated
  - Report "Cross-references: X reports ↔ plan ↔ summary"
  - Provide workflow summary path with cross-reference confirmation
- [ ] Ensure /orchestrate and /implement use identical spec-updater invocation patterns (DRY)

Testing:
```bash
# Integration test: /orchestrate with enhanced updates
.claude/tests/test_orchestrate_enhanced_updates.sh

# Test workflow with:
# - Research phase (generates reports)
# - Planning phase (generates plan)
# - Implementation phase (Level 1 structure)
# - Documentation phase (generates summary)
# Expected: Complete cross-reference graph: reports ↔ plan ↔ summary
```

**Validation Criteria**:
- /orchestrate maintains complete bidirectional cross-references
- Workflow summary correctly links to highest-level plan (not leaf phases)
- Both /implement and /orchestrate use identical update mechanisms
- Final output clearly communicates all synchronization performed

---

## Testing Strategy

### Unit Tests (Per Phase)
Each phase includes focused unit tests for new utilities and functions:
- `test_cross_reference_utils.sh`: Tests all cross-ref functions individually
- `test_ancestor_propagation.sh`: Tests hierarchy traversal and update logic
- `test_spec_updater_enhanced.sh`: Tests agent with new capabilities

### Integration Tests (Phases 4-5)
Commands tested with real plan structures:
- `test_implement_enhanced_updates.sh`: /implement with Level 1/2 plans
- `test_orchestrate_enhanced_updates.sh`: Full workflow with cross-refs

### Regression Tests
Ensure backward compatibility:
- Existing plans without research reports still update correctly
- Level 0 (single file) plans work unchanged
- /implement and /orchestrate with old checkpoint formats still function

### Coverage Target
- New utilities: ≥80% coverage
- Enhanced agent: ≥70% coverage (agent execution harder to unit test)
- Command integration: ≥60% coverage (tested via integration tests)

## Documentation Requirements

### Updates Needed

1. **CLAUDE.md** (Spec Updater Integration section):
   - Document automatic ancestor updates
   - Document standardized cross-reference metadata sections
   - Update integration points for /implement and /orchestrate
   - Add examples of new bidirectional linking behavior

2. **.claude/docs/adaptive-planning-guide.md**:
   - Add section on automatic hierarchy synchronization
   - Document new checkpoint fields for cross-reference tracking
   - Update examples to show ancestor update logs

3. **.claude/lib/checkbox-utils.sh** (inline comments):
   - Add detailed comments for `propagate_to_ancestors()`
   - Document edge cases and hierarchy traversal logic

4. **.claude/lib/cross-reference-utils.sh** (new file with header):
   - Comprehensive header documenting all functions
   - Usage examples for each cross-reference utility
   - Integration patterns with spec-updater

5. **.claude/agents/spec-updater.md**:
   - Update agent protocol section with new steps
   - Add examples demonstrating cross-reference updates
   - Document new parameters (research_reports, summary_path)

6. **Command Documentation**:
   - Update /implement command documentation (Step 5)
   - Update /orchestrate command documentation (Documentation Phase)
   - Add examples showing automatic cross-referencing output

## Dependencies

### Existing Components (Required)
- `.claude/lib/checkbox-utils.sh`: Base for enhancements
- `.claude/lib/plan-core-bundle.sh`: Structure detection utilities
- `.claude/agents/spec-updater.md`: Base agent to enhance
- `.claude/commands/implement.md`: Command to refactor
- `.claude/commands/orchestrate.md`: Command to refactor

### New Components (Created in this plan)
- `.claude/lib/cross-reference-utils.sh`: New utility library (Phase 1)

### External Dependencies
- Bash 4.0+ (for associative arrays in cross-ref utilities)
- Standard Unix tools: sed, grep, awk (already in use)

## Risk Assessment

### Medium Risks
1. **Hierarchy Traversal Complexity**:
   - Risk: Edge cases in Level 2 → Level 1 → Level 0 propagation
   - Mitigation: Comprehensive unit tests, careful path parsing, error logging

2. **Backward Compatibility**:
   - Risk: Breaking existing /implement and /orchestrate workflows
   - Mitigation: Preserve old checkpoint formats, optional parameters for new features

### Low Risks
1. **Cross-Reference Validation**:
   - Risk: Broken links if files moved after referencing
   - Mitigation: Use relative paths, validation function to detect issues

2. **Performance Impact**:
   - Risk: Ancestor updates may slow phase completion
   - Mitigation: Minimal - only 1-2 additional file writes per phase

## Notes

### Design Decisions

1. **DRY Principle**: Both /implement and /orchestrate use identical spec-updater invocation patterns to avoid duplication and ensure consistency.

2. **Relative Paths**: All cross-references use relative paths for portability when moving topic directories.

3. **Graceful Degradation**: If cross-reference updates fail, log warnings but continue execution (non-blocking). Ancestor updates are critical and will error if they fail.

4. **Standardized Metadata Sections**:
   - Plans: `**Research Reports**: [list]`
   - Summaries: `**Research Reports**: [list]`, `**Plan**: [path]`
   - Reports: `**Used in Implementation**: [plan]` (added by cross-ref utils)

5. **Highest-Level Plan Detection**: Summaries link to the main plan in a hierarchy, not leaf phases or stages, ensuring users can navigate to the complete implementation plan.

### Future Enhancements (Out of Scope)
- Automated cross-reference repair tool (detects and fixes broken links)
- Visual dependency graph generator (reports → plans → summaries)
- Cross-project cross-referencing (linking artifacts across different codebases)

---

## Spec Updater Checklist

- [ ] Ensure plan is in topic-based directory structure (`.claude/specs/058_ancestor_updates/plans/`)
- [ ] Create standard subdirectories if needed (`reports/`, `summaries/`, `debug/`)
- [ ] Update cross-references if artifacts moved
- [ ] Create implementation summary when complete
- [ ] Verify gitignore compliance (debug/ committed, others ignored)
