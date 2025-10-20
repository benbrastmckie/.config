# Fix /orchestrate Artifact Organization Implementation Plan

## Metadata
- **Date**: 2025-10-19
- **Feature**: Topic-based artifact organization compliance for /orchestrate
- **Scope**: Fix /orchestrate command and extend artifact-creation.sh utility
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Topic Directory**: specs/067_orchestrate_artifact_compliance/

## Overview

The /orchestrate command currently uses a legacy flat directory structure (`specs/reports/`, `specs/plans/`, `specs/summaries/`) that is incompatible with the documented topic-based organization standard (`specs/{NNN_topic}/reports/`, etc.). Additionally, the `artifact-creation.sh` utility only supports artifact types like `debug`, `scripts`, and `outputs`, but does NOT support `reports` and `plans`, forcing commands to use custom artifact creation logic.

This plan addresses both issues:
1. Migrate /orchestrate to use topic-based artifact organization
2. Extend artifact-creation.sh to support `reports` and `plans` as first-class artifact types
3. Ensure consistency across all commands (/report, /plan, /debug, /implement already compliant)

## Success Criteria
- [ ] artifact-creation.sh supports `reports` and `plans` artifact types
- [ ] /orchestrate creates research reports in `specs/{NNN_topic}/reports/`
- [ ] /orchestrate delegates plan creation using topic-based paths
- [ ] /orchestrate creates summaries in `specs/{NNN_topic}/summaries/`
- [ ] All artifact cross-references use topic-based paths
- [ ] Backward compatibility: existing flat-structure artifacts still accessible
- [ ] Tests verify topic-based artifact creation
- [ ] Documentation updated to reflect changes

## Technical Design

### Current Implementation Issues

**Problem 1: /orchestrate uses flat directory structure**
- Line 508: `TOPIC_DIR="${CLAUDE_PROJECT_DIR}/specs/reports/${topic}"`
- Line 1089: Creates plans at `specs/plans/NNN_feature.md`
- Line 1662: Creates summaries at `specs/summaries/[plan_number]_workflow_summary.md`

**Problem 2: artifact-creation.sh doesn't support reports/plans**
- Line 27-34: Valid types limited to `debug|scripts|outputs|artifacts|backups|data|logs|notes`
- No support for `reports` or `plans` types
- Commands like /report and /plan must use custom logic

**Problem 3: Inconsistency across commands**
- /report, /debug, /plan, /implement: Use topic-based structure via `get_or_create_topic_dir()`
- /orchestrate: Uses legacy flat structure
- Result: Fragmented artifact organization

### Proposed Solution

**Solution 1: Extend artifact-creation.sh**
- Add `reports` and `plans` to valid artifact types (line 27)
- Implement gitignore handling (reports/plans gitignored, debug committed)
- Support subdirectory organization for multi-report tasks

**Solution 2: Update /orchestrate command**
- Replace flat directory paths with `get_or_create_topic_dir()` calls
- Use `create_topic_artifact()` for research reports
- Delegate plan creation via `/plan` command (already topic-aware)
- Create summaries in topic-based directories

**Solution 3: Unified topic extraction**
- Extract topic from workflow description once
- Reuse topic directory for all artifacts in workflow
- Maintain cross-references between artifacts

### Architecture Changes

```bash
# Before (flat structure)
specs/
├── reports/
│   └── authentication_patterns/
│       └── 001_analysis.md
├── plans/
│   └── 042_auth_implementation.md
└── summaries/
    └── 042_workflow_summary.md

# After (topic-based structure)
specs/
└── 067_orchestrate_artifact_compliance/
    ├── reports/
    │   ├── 001_authentication_patterns.md
    │   └── 002_security_best_practices.md
    ├── plans/
    │   └── 001_implementation.md
    └── summaries/
        └── 001_workflow_summary.md
```

### Data Flow

```
/orchestrate workflow_description
    │
    ├─> Extract topic → get_or_create_topic_dir("workflow_description")
    │                   Returns: specs/067_topic_name/
    │
    ├─> Research Phase
    │   └─> create_topic_artifact(topic_dir, "reports", "research_name", content)
    │       Returns: specs/067_topic_name/reports/001_research_name.md
    │
    ├─> Planning Phase
    │   └─> /plan feature [report_paths]
    │       Uses: get_or_create_topic_dir() internally
    │       Returns: specs/067_topic_name/plans/001_plan_name.md
    │
    ├─> Implementation Phase
    │   └─> /implement plan_path
    │       Creates: specs/067_topic_name/summaries/001_partial.md
    │
    └─> Documentation Phase
        └─> Rename summary: 001_implementation_summary.md
            Create: workflow cross-references
```

## Implementation Phases

### Phase 1: Extend artifact-creation.sh Utility
**Objective**: Add support for `reports` and `plans` artifact types
**Complexity**: Low

Tasks:
- [ ] Read `.claude/lib/artifact-creation.sh` to understand current implementation (.claude/lib/artifact-creation.sh:1-263)
- [ ] Add `reports` and `plans` to valid artifact types in `create_topic_artifact()` case statement (.claude/lib/artifact-creation.sh:26-34)
- [ ] Update error message to include new types (.claude/lib/artifact-creation.sh:31-32)
- [ ] Add gitignore configuration for reports/plans (like debug reports are committed, but these should be gitignored)
- [ ] Test artifact creation for both new types using test script

Testing:
```bash
# Test reports artifact creation
source .claude/lib/artifact-creation.sh
source .claude/lib/template-integration.sh

TOPIC_DIR=$(get_or_create_topic_dir "test artifact creation" ".claude/specs")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "test_report" "# Test Report\n\nThis is a test.")

# Verify report created at correct path
[[ -f "$REPORT_PATH" ]] && echo "✓ Report artifact created"
[[ "$REPORT_PATH" =~ specs/[0-9]+_test_artifact_creation/reports/[0-9]+_test_report\.md ]] && echo "✓ Correct path format"

# Test plans artifact creation
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "test_plan" "# Test Plan\n\n## Phase 1\n- [ ] Task 1")

# Verify plan created at correct path
[[ -f "$PLAN_PATH" ]] && echo "✓ Plan artifact created"
[[ "$PLAN_PATH" =~ specs/[0-9]+_test_artifact_creation/plans/[0-9]+_test_plan\.md ]] && echo "✓ Correct path format"

# Cleanup
rm -rf ".claude/specs/"*_test_artifact_creation
```

Validation:
- [ ] `create_topic_artifact()` accepts "reports" and "plans" types
- [ ] Reports created at `specs/{NNN_topic}/reports/NNN_name.md`
- [ ] Plans created at `specs/{NNN_topic}/plans/NNN_name.md`
- [ ] Artifact registry updated for both types
- [ ] No breaking changes to existing artifact types

### Phase 2: Update /orchestrate Research Phase
**Objective**: Migrate research report creation to topic-based organization
**Complexity**: Medium

Tasks:
- [ ] Read `/orchestrate` command to understand research phase workflow (.claude/commands/orchestrate.md:480-680)
- [ ] Identify workflow description extraction logic (.claude/commands/orchestrate.md:1-100)
- [ ] Add topic directory creation at workflow start using `get_or_create_topic_dir("$workflow_description", ".claude/specs")`
- [ ] Replace flat directory path construction (line 508: `TOPIC_DIR="${CLAUDE_PROJECT_DIR}/specs/reports/${topic}"`)
- [ ] Update research agent prompts to use topic-based artifact paths (.claude/commands/orchestrate.md:536-550)
- [ ] Change report path pattern from `specs/reports/{topic}/NNN_analysis.md` to `${TOPIC_DIR}/reports/NNN_${topic}.md`
- [ ] Use `create_topic_artifact()` for research report creation instead of custom numbering
- [ ] Update report path storage in `REPORT_PATHS` associative array
- [ ] Verify research summary extraction still works with new paths

Testing:
```bash
# Simulate research phase with topic-based artifacts
# (This would be tested as part of full /orchestrate integration test)

# Expected behavior:
# 1. Extract topic from workflow description
# 2. Create or find topic directory (specs/0NN_topic/)
# 3. Create research reports in specs/0NN_topic/reports/
# 4. Return report paths for planning phase
```

Validation:
- [ ] Workflow description extracted correctly
- [ ] Topic directory created using `get_or_create_topic_dir()`
- [ ] Research reports created in `specs/{NNN_topic}/reports/`
- [ ] Report paths correctly passed to planning phase
- [ ] No hardcoded `specs/reports/` paths remain

### Phase 3: Update /orchestrate Planning and Implementation Phases
**Objective**: Ensure plan and summary creation use topic-based organization
**Complexity**: Medium

Tasks:
- [ ] Read planning phase implementation (.claude/commands/orchestrate.md:700-950)
- [ ] Verify `/plan` command already uses topic-based organization (it does, per research)
- [ ] Update planning agent prompt to pass topic directory context
- [ ] Ensure `/plan` receives report paths and infers topic directory correctly
- [ ] Read implementation phase (.claude/commands/orchestrate.md:950-1200)
- [ ] Verify `/implement` creates summaries in correct topic directory (it does, per research)
- [ ] Read documentation phase (.claude/commands/orchestrate.md:1600-1900)
- [ ] Update summary creation path from `specs/summaries/NNN_*.md` to `${TOPIC_DIR}/summaries/NNN_*.md` (line 1662, 2666)
- [ ] Ensure summary numbering matches plan number (already implemented)
- [ ] Update cross-reference logic to use topic-relative paths

Testing:
```bash
# Test planning phase integration
# 1. Create mock research reports in topic directory
# 2. Invoke planning with report paths
# 3. Verify plan created in same topic directory

# Test summary creation
# 1. Create mock plan in topic directory
# 2. Simulate implementation completion
# 3. Verify summary created in same topic directory with matching number
```

Validation:
- [ ] `/plan` invocation includes topic context
- [ ] Plans created in same topic directory as research reports
- [ ] Summaries created in `specs/{NNN_topic}/summaries/`
- [ ] Summary numbering matches plan numbering
- [ ] Cross-references use relative paths within topic directory

### Phase 4: Testing, Documentation, and Migration Path
**Objective**: Comprehensive testing and documentation updates
**Complexity**: Medium

Tasks:
- [ ] Create test script for topic-based artifact workflow (`.claude/tests/test_orchestrate_topic_artifacts.sh`)
- [ ] Test research phase: verify reports in topic directory
- [ ] Test planning phase: verify plan in same topic directory
- [ ] Test implementation phase: verify summary in topic directory
- [ ] Test cross-referencing: verify all artifact links work
- [ ] Test backward compatibility: ensure existing flat artifacts still accessible (read-only)
- [ ] Update `/orchestrate` command documentation (.claude/commands/orchestrate.md)
- [ ] Add "Artifact Organization" section explaining topic-based structure
- [ ] Update examples to show topic-based paths
- [ ] Update `.claude/docs/README.md` to reflect orchestrate compliance
- [ ] Update CLAUDE.md directory_protocols section if needed
- [ ] Document migration path for existing flat-structure artifacts (optional manual migration)
- [ ] Add inline comments in orchestrate.md explaining topic-based artifact flow

Testing:
```bash
# Full integration test
.claude/tests/test_orchestrate_topic_artifacts.sh

# Expected test coverage:
# 1. Topic directory creation from workflow description
# 2. Research report creation in topic/reports/
# 3. Plan creation in topic/plans/
# 4. Summary creation in topic/summaries/
# 5. Cross-reference verification
# 6. Artifact numbering consistency
# 7. Gitignore compliance (reports/plans gitignored, debug committed)

# Test should verify:
TOPIC_DIR=$(get_or_create_topic_dir "test workflow" ".claude/specs")
[[ -d "$TOPIC_DIR/reports" ]] && echo "✓ Reports subdirectory created"
[[ -d "$TOPIC_DIR/plans" ]] && echo "✓ Plans subdirectory created"
[[ -d "$TOPIC_DIR/summaries" ]] && echo "✓ Summaries subdirectory created"

# Create artifacts and verify paths
REPORT=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "content")
PLAN=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "content")
SUMMARY=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow" "content")

[[ "$REPORT" =~ $TOPIC_DIR/reports/[0-9]+_research\.md ]] && echo "✓ Report path correct"
[[ "$PLAN" =~ $TOPIC_DIR/plans/[0-9]+_implementation\.md ]] && echo "✓ Plan path correct"
[[ "$SUMMARY" =~ $TOPIC_DIR/summaries/[0-9]+_workflow\.md ]] && echo "✓ Summary path correct"
```

Validation:
- [ ] All tests pass for topic-based artifact creation
- [ ] Documentation accurately reflects new behavior
- [ ] Examples updated with topic-based paths
- [ ] Migration guidance provided for existing artifacts
- [ ] No regression in existing /report, /plan, /debug, /implement commands

## Testing Strategy

### Unit Tests
- `artifact-creation.sh`: Test `reports` and `plans` artifact creation
- Topic directory creation: Test `get_or_create_topic_dir()` with various inputs
- Artifact numbering: Test sequential numbering within topic subdirectories

### Integration Tests
- Full /orchestrate workflow: Research → Plan → Implement → Document
- Verify all artifacts in same topic directory
- Verify cross-references between artifacts
- Test with multiple research reports in single workflow

### Regression Tests
- Existing /report, /plan, /debug, /implement commands still work
- Existing flat-structure artifacts remain accessible
- No breaking changes to artifact registry
- Gitignore configuration correct (reports/plans gitignored, debug committed)

### Test Script Structure
```bash
#!/usr/bin/env bash
# test_orchestrate_topic_artifacts.sh

set -euo pipefail

# Source required libraries
source .claude/lib/artifact-creation.sh
source .claude/lib/template-integration.sh

# Test 1: artifact-creation.sh supports reports/plans
test_artifact_creation() {
  local topic_dir=$(get_or_create_topic_dir "test topic" ".claude/specs")

  # Test reports
  local report=$(create_topic_artifact "$topic_dir" "reports" "test_report" "# Test")
  [[ -f "$report" ]] || { echo "FAIL: Report not created"; return 1; }

  # Test plans
  local plan=$(create_topic_artifact "$topic_dir" "plans" "test_plan" "# Test")
  [[ -f "$plan" ]] || { echo "FAIL: Plan not created"; return 1; }

  echo "PASS: Artifact creation supports reports and plans"
}

# Test 2: Topic-based directory structure
test_topic_structure() {
  local topic_dir=$(get_or_create_topic_dir "orchestrate test" ".claude/specs")

  [[ "$topic_dir" =~ .claude/specs/[0-9]+_orchestrate_test ]] || {
    echo "FAIL: Topic directory format incorrect: $topic_dir"
    return 1
  }

  [[ -d "$topic_dir/reports" ]] || { echo "FAIL: reports/ not created"; return 1; }
  [[ -d "$topic_dir/plans" ]] || { echo "FAIL: plans/ not created"; return 1; }
  [[ -d "$topic_dir/summaries" ]] || { echo "FAIL: summaries/ not created"; return 1; }

  echo "PASS: Topic directory structure correct"
}

# Test 3: Artifact numbering
test_artifact_numbering() {
  local topic_dir=$(get_or_create_topic_dir "numbering test" ".claude/specs")

  local report1=$(create_topic_artifact "$topic_dir" "reports" "first" "content")
  local report2=$(create_topic_artifact "$topic_dir" "reports" "second" "content")

  [[ "$(basename "$report1")" == "001_first.md" ]] || {
    echo "FAIL: First report not numbered 001"
    return 1
  }

  [[ "$(basename "$report2")" == "002_second.md" ]] || {
    echo "FAIL: Second report not numbered 002"
    return 1
  }

  echo "PASS: Artifact numbering sequential"
}

# Run all tests
echo "=== Testing Topic-Based Artifact Organization ==="
test_artifact_creation
test_topic_structure
test_artifact_numbering

# Cleanup test artifacts
rm -rf .claude/specs/*_test_*
rm -rf .claude/specs/*_orchestrate_test
rm -rf .claude/specs/*_numbering_test

echo "=== All Tests Passed ==="
```

## Documentation Requirements

### Files to Update

1. **`.claude/commands/orchestrate.md`**
   - Add "Artifact Organization" section
   - Update all path examples to use topic-based structure
   - Document topic extraction from workflow description
   - Explain artifact co-location in topic directories

2. **`.claude/docs/README.md`**
   - Update "Artifact Organization" section to note /orchestrate compliance
   - Add /orchestrate to list of compliant commands

3. **`.claude/lib/artifact-creation.sh`**
   - Add inline comments explaining reports/plans support
   - Document gitignore behavior for each artifact type

4. **`CLAUDE.md` (project root)**
   - Verify directory_protocols section accurate
   - Update any references to /orchestrate artifact paths

### Documentation Sections

**orchestrate.md - Artifact Organization**
```markdown
## Artifact Organization

The /orchestrate command follows topic-based artifact organization as specified
in CLAUDE.md directory protocols.

### Topic Directory Structure

All artifacts generated during a workflow are co-located in a single topic directory:

```
specs/067_workflow_name/
├── reports/          # Research reports (gitignored)
│   ├── 001_existing_patterns.md
│   ├── 002_best_practices.md
│   └── 003_alternatives.md
├── plans/            # Implementation plan (gitignored)
│   └── 001_implementation.md
└── summaries/        # Workflow summary (gitignored)
    └── 001_workflow_summary.md
```

### Topic Extraction

The topic directory is created from the workflow description:
- "Add user authentication" → `specs/067_user_authentication/`
- "Fix caching bug" → `specs/068_caching_bug/`

If a related topic already exists (e.g., from previous /report or /plan), the
existing directory is reused.

### Cross-Referencing

All artifacts within a workflow reference each other using relative paths:
- Plan references reports: `../reports/001_research.md`
- Summary references plan: `../plans/001_implementation.md`
```

## Dependencies

### Required Utilities
- `.claude/lib/artifact-creation.sh` (will be modified)
- `.claude/lib/template-integration.sh` (provides `get_or_create_topic_dir()`)
- `.claude/lib/artifact-registry.sh` (artifact tracking)
- `.claude/lib/unified-logger.sh` (logging)

### Command Dependencies
- `/plan` command (already topic-aware, will be invoked by /orchestrate)
- `/implement` command (already topic-aware, creates summaries correctly)

### Testing Dependencies
- `jq` (JSON parsing for artifact registry)
- `bash` v4+ (associative arrays)

## Risk Assessment

### Risks

1. **Breaking Changes for Active Workflows**
   - Risk: In-progress /orchestrate workflows may have artifacts in old locations
   - Mitigation: Backward compatibility - read from both old and new locations
   - Impact: Low (orchestrate workflows are ephemeral, not long-running)

2. **Path References in Existing Artifacts**
   - Risk: Old artifacts may reference flat-structure paths
   - Mitigation: Document migration path, but don't force migration
   - Impact: Low (old artifacts remain readable, new workflows use new structure)

3. **Command Compatibility**
   - Risk: /list-plans, /list-reports may not find artifacts in topic directories
   - Mitigation: These commands already support topic-based structure
   - Impact: None (verified in research phase)

4. **Gitignore Configuration**
   - Risk: Reports/plans may be accidentally committed or ignored incorrectly
   - Mitigation: Verify .gitignore patterns match artifact-creation.sh behavior
   - Impact: Low (gitignore already configured for topic directories)

### Mitigation Strategies

- **Incremental Rollout**: Modify artifact-creation.sh first, test thoroughly, then update /orchestrate
- **Comprehensive Testing**: Test all artifact creation paths before deployment
- **Documentation First**: Update docs to clarify expected behavior
- **Backward Compatibility**: Ensure old flat-structure artifacts remain accessible

## Migration Path for Existing Artifacts

### Manual Migration (Optional)

Users can manually migrate existing flat-structure artifacts to topic-based organization:

```bash
# Example: Migrate authentication workflow artifacts
mkdir -p specs/042_authentication/{reports,plans,summaries}

# Move artifacts
mv specs/reports/auth_patterns/001_analysis.md specs/042_authentication/reports/001_auth_patterns.md
mv specs/plans/042_auth_implementation.md specs/042_authentication/plans/001_implementation.md
mv specs/summaries/042_workflow_summary.md specs/042_authentication/summaries/001_workflow_summary.md

# Update cross-references in artifacts (manual edit)
# Change: ../../reports/auth_patterns/001_analysis.md
# To:     ../reports/001_auth_patterns.md
```

### No Forced Migration

- Existing flat-structure artifacts remain in place
- Old workflows can still reference old paths
- New /orchestrate invocations use topic-based structure
- Gradual migration as old artifacts become obsolete

## Notes

### Why This Matters

**Consistency**: All commands should follow the same artifact organization standard. Currently, /report, /plan, /debug, and /implement use topic-based structure, but /orchestrate uses a legacy flat structure. This creates confusion and fragmentation.

**Maintainability**: Topic-based organization keeps all artifacts for a single feature together, making it easier to:
- Find related artifacts (reports, plans, summaries in one place)
- Cross-reference between artifacts (relative paths within topic directory)
- Clean up obsolete artifacts (delete entire topic directory)
- Track feature evolution (all artifacts numbered sequentially within topic)

**Standards Compliance**: The documented standard in CLAUDE.md specifies topic-based organization. /orchestrate should comply with this standard.

### Implementation Notes

- Phase 1 is foundational: Without reports/plans support in artifact-creation.sh, /orchestrate must use custom logic
- Phase 2 and 3 can be implemented in parallel (research phase independent of planning/implementation phases)
- Phase 4 testing should cover all previous phases comprehensively
- Backward compatibility is important but not critical (orchestrate workflows are ephemeral)

### Assumptions

- `get_or_create_topic_dir()` correctly extracts topics from workflow descriptions
- `/plan` and `/implement` commands already use topic-based organization (verified in research)
- Gitignore patterns already cover topic-based directories (verified: `!specs/*/debug/`, gitignore patterns exist)
- No active /orchestrate workflows in progress during deployment

### Future Enhancements

- Automatic migration utility for old flat-structure artifacts
- Enhanced topic matching (avoid duplicate topics for similar workflows)
- Artifact consolidation (merge multiple research reports into structured subdirectories)
- Integration with /list commands to query by topic directory
