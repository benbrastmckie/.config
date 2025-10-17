# Complete Topic-Based Spec Organization System

## Metadata
- **Date**: 2025-10-16
- **Feature**: Topic-Based Spec Organization
- **Scope**: Implement consistent topic-based directory structure for all spec artifacts with automatic numbering, cross-referencing, and spec-updater integration
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: Research findings from orchestrate research phase

## Overview

This plan addresses the incomplete migration to topic-based spec organization documented in CLAUDE.md. Currently, the system has a well-defined specification (`specs/{NNN_topic}/{artifact_type}/`) and comprehensive utilities (`create_topic_artifact()`, `get_next_artifact_number()`), but commands don't consistently use them, flat structure coexists with topic structure, and spec-updater agent integration is minimal.

**Goals**:
1. Complete migration from flat `specs/plans/`, `specs/reports/` to topic-based structure
2. Implement missing utilities (`find_matching_topic()`, `extract_topic_from_question()`)
3. Integrate spec-updater agent into all commands that create artifacts
4. Ensure consistent automatic numbering and cross-referencing
5. Validate gitignore compliance (debug/ committed, others ignored)

## Success Criteria
- [ ] All spec artifacts organized in topic directories (`specs/{NNN_topic}/`)
- [ ] Commands (`/plan`, `/report`, `/debug`, `/implement`, `/orchestrate`) consistently use `create_topic_artifact()`
- [ ] spec-updater agent invoked at appropriate points in command workflows
- [ ] Automatic cross-referencing between plans, reports, summaries, debug reports
- [ ] Numbering increments correctly within each topic subdirectory
- [ ] Gitignore compliance verified (debug/ committed, all others ignored)
- [ ] No flat structure artifacts remaining (or archived)

## Technical Design

### Current State Analysis

**Existing Utilities** (.claude/lib/artifact-operations.sh):
- `create_topic_artifact()` - Creates artifacts in topic subdirectories with auto-numbering
- `get_next_artifact_number()` - Finds next number in topic directory
- `cleanup_topic_artifacts()` - Cleans temporary artifacts by type and age
- `cleanup_all_temp_artifacts()` - Removes all temp artifacts from topic

**Missing Utilities** (identified in research):
- `find_matching_topic()` - Search existing topics to prevent duplicates
- `extract_topic_from_question()` - Parse research questions/feature descriptions
- `get_or_create_topic_dir()` - Get existing or create new topic directory with proper structure
- `update_cross_references()` - Automated link updates when artifacts created
- `validate_gitignore_compliance()` - Verify debug/ committed, others ignored
- `link_artifact_to_plan()` - Add artifact references to plan metadata

**Command Integration Status**:
- `/orchestrate`: Invokes spec-updater in Documentation Phase only
- `/implement`: Invokes spec-updater after phase completion (Step 5)
- `/plan`: Uses `create_topic_artifact()` but doesn't invoke spec-updater
- `/report`: Uses `create_topic_artifact()` but doesn't invoke spec-updater
- `/debug`: References `create_topic_artifact()` but doesn't invoke spec-updater

### Architecture Decisions

**1. Topic Directory Discovery**
- Implement `find_matching_topic()` to search existing topics by keyword
- Prevent duplicate topic creation for similar features
- Use fuzzy matching for topic names (e.g., "auth" matches "042_authentication")

**2. Topic Extraction**
- Implement `extract_topic_from_question()` to parse user input
- Extract 2-3 keyword topic name from research questions/feature descriptions
- Convert to snake_case format compatible with directory naming

**3. spec-updater Integration Points**
Commands invoke spec-updater at these workflow stages:

| Command | Integration Point | Purpose |
|---------|------------------|---------|
| `/plan` | After plan file creation | Topic structure initialization, verify subdirectories |
| `/report` | After report creation | Update cross-references in related plans |
| `/debug` | After debug report creation | Link debug report to plan and phase |
| `/implement` | After each phase completion | Checkbox hierarchy updates (already integrated) |
| `/orchestrate` | Documentation Phase | Plan hierarchy updates, workflow summary (already integrated) |

**4. Cross-Reference Management**
- spec-updater maintains bidirectional links:
  - Plans → Reports (research used)
  - Plans → Debug Reports (issues encountered)
  - Reports → Plans (findings incorporated)
  - Summaries → Plans + Reports (artifacts linked)

**5. Numbering Strategy**
- Per-topic numbering (001-999 within each artifact type per topic) - already implemented correctly
- No changes needed to `get_next_artifact_number()` - it properly handles edge cases

### Data Flow

```
User Request
    ↓
Command (/plan, /report, /debug)
    ↓
extract_topic_from_question() → "user_authentication"
    ↓
find_matching_topic() → Find "042_authentication" or null
    ↓
get_or_create_topic_dir()
    ├─ Existing: "specs/042_authentication/"
    └─ New: "specs/043_new_topic/" (next number)
    ↓
create_topic_artifact("specs/042_authentication", "plans", "implementation", content)
    ├─ Create subdirectory if missing
    ├─ get_next_artifact_number() → "001" or "002"
    └─ Write file: "specs/042_authentication/plans/001_implementation.md"
    ↓
invoke spec-updater agent
    ├─ Verify topic subdirectories (reports/, debug/, scripts/, outputs/, artifacts/, backups/)
    ├─ Update cross-references (add plan reference to related reports)
    └─ Validate gitignore compliance
    ↓
Return artifact path to command
```

## Implementation Phases

### Phase 1: Create Missing Utility Functions [COMPLETED]
**Dependencies**: []
**Risk**: Low
**Estimated Time**: 2-3 hours

**Objective**: Implement missing utilities identified in research phase

Tasks:
- [x] Add `find_matching_topic()` to `.claude/lib/template-integration.sh` (.claude/lib/template-integration.sh:185-231)
  - Search `specs/*/` directories for keyword matches
  - Return best match path or empty string
  - Use fuzzy matching (partial keyword match acceptable)
  - Example: `find_matching_topic "auth"` → `"specs/042_authentication"`

- [x] Add `extract_topic_from_question()` to `.claude/lib/template-integration.sh` (.claude/lib/template-integration.sh:154-183)
  - Parse user input (research question, feature description)
  - Extract 2-3 keywords for topic name
  - Convert to snake_case format
  - Remove common stop words ("implement", "add", "fix", "the", "a")
  - Example: `extract_topic_from_question "Implement user authentication with JWT"` → `"user_authentication_jwt"`

- [x] Enhance `get_or_create_topic_dir()` in `.claude/lib/template-integration.sh` (.claude/lib/template-integration.sh:256-291)
  - Check if topic already exists via `find_matching_topic()`
  - If exists, return existing path
  - If new, get next topic number (`get_next_topic_number()`)
  - Create topic directory with standard subdirectories (plans/, reports/, summaries/, debug/)
  - Return topic directory path

- [x] Add `get_next_topic_number()` to `.claude/lib/template-integration.sh` (.claude/lib/template-integration.sh:233-254)
  - Find highest NNN in specs/NNN_*/ directories
  - Return next number with zero-padding (001, 002, etc.)
  - Similar logic to existing `get_next_artifact_number()`

- [x] Add `update_cross_references()` to `.claude/lib/artifact-operations.sh` (.claude/lib/artifact-operations.sh:1704-1756)
  - Parse artifact metadata for related artifacts
  - Update plan files with report references
  - Update report files with plan references
  - Maintain bidirectional links

- [x] Add `validate_gitignore_compliance()` to `.claude/lib/artifact-operations.sh` (.claude/lib/artifact-operations.sh:1758-1822)
  - Check debug/ subdirectories are not gitignored
  - Verify other subdirectories (plans/, reports/, summaries/, scripts/, outputs/, artifacts/, backups/) are gitignored
  - Use `git check-ignore` command
  - Return JSON validation report

- [x] Add `link_artifact_to_plan()` to `.claude/lib/artifact-operations.sh` (.claude/lib/artifact-operations.sh:1824-1897)
  - Add artifact reference to plan metadata section
  - Maintain list of related reports, debug reports
  - Update cross-reference sections

Testing:
```bash
cd /home/benjamin/.config
source .claude/lib/template-integration.sh
source .claude/lib/artifact-operations.sh

# Test topic extraction
result=$(extract_topic_from_question "Implement user authentication with JWT tokens")
[[ "$result" == "user_authentication_jwt" ]] || echo "FAIL: extract_topic"

# Test topic finding
topic=$(find_matching_topic "auth")
[[ -n "$topic" ]] && echo "Found: $topic" || echo "No match"

# Test topic creation
topic_dir=$(get_or_create_topic_dir "test_feature" "specs")
[[ -d "$topic_dir" ]] || echo "FAIL: topic creation"
[[ -d "$topic_dir/plans" ]] || echo "FAIL: plans subdirectory"
[[ -d "$topic_dir/debug" ]] || echo "FAIL: debug subdirectory"

# Test gitignore compliance
compliance=$(validate_gitignore_compliance "$topic_dir")
echo "$compliance" | jq '.debug_committed' | grep -q "true" || echo "FAIL: gitignore"
```

Validation:
- All new utilities have test cases
- Functions handle edge cases (no topics exist, empty input, special characters)
- Error messages are clear and actionable

---

### Phase 2: Update `/plan` Command for Topic-Based Integration [COMPLETED]
**Dependencies**: [1]
**Risk**: Medium
**Estimated Time**: 3-4 hours

**Objective**: Integrate topic-based utilities and spec-updater agent into `/plan` command

Tasks:
- [x] Read current `/plan` command implementation (.claude/commands/plan.md:1-200)
  - Identify where plan file is created
  - Find integration points for topic utilities

- [x] Update plan creation workflow in `.claude/commands/plan.md` (.claude/commands/plan.md:150-250)
  - After receiving feature description from user
  - Call `extract_topic_from_question()` to get topic name
  - Call `get_or_create_topic_dir()` to get/create topic directory
  - Use topic directory for plan file location instead of flat `specs/plans/`
  - Maintain existing plan numbering logic within topic

- [x] Add spec-updater invocation after plan creation (.claude/commands/plan.md:250-350)
  - After plan file is written
  - Invoke spec-updater agent via Task tool
  - Pass plan path, topic directory, operation type ("plan_creation")
  - Wait for spec-updater completion before returning plan path to user

- [x] Create spec-updater invocation template for plan creation (.claude/commands/plan.md:352-420)
  ```markdown
  Task tool invocation:
  subagent_type: general-purpose
  description: "Update topic structure for new plan"
  prompt: |
    Read and follow: .claude/agents/spec-updater.md

    Context:
    - Plan created at: {plan_path}
    - Topic directory: {topic_dir}
    - Operation: plan_creation

    Tasks:
    - Verify topic subdirectories exist (plans/, reports/, summaries/, debug/, scripts/, outputs/, artifacts/, backups/)
    - Create .gitkeep in debug/ subdirectory
    - Validate gitignore compliance
    - Initialize plan metadata cross-reference section

    Return:
    - Verification status (subdirectories_ok, gitignore_ok)
    - Any warnings or issues encountered
  ```

- [x] Update plan command documentation (.claude/commands/plan.md:500-550)
  - Document topic-based plan creation workflow
  - Add examples showing topic directory structure
  - Note that plans created in topic-based format

- [x] Update plan templates to include topic context (.claude/templates/*.yaml)
  - Add topic metadata field
  - Include cross-reference section placeholders
  - Add spec-updater checklist

Testing:
```bash
# Test plan creation with topic extraction
/plan "Implement OAuth2 authentication with Google provider"

# Verify topic directory created
[[ -d "specs/NNN_oauth2_authentication_google" ]] || echo "FAIL: topic directory"

# Verify plan file in topic/plans/ subdirectory
plan_file=$(find specs/NNN_oauth2_authentication_google/plans -name "001_*.md")
[[ -f "$plan_file" ]] || echo "FAIL: plan file location"

# Verify subdirectories exist
[[ -d "specs/NNN_oauth2_authentication_google/debug" ]] || echo "FAIL: debug subdir"

# Verify gitignore compliance
git check-ignore "specs/NNN_oauth2_authentication_google/plans/001_*.md" && echo "OK: plan gitignored" || echo "FAIL"
git check-ignore "specs/NNN_oauth2_authentication_google/debug/" && echo "FAIL: debug should not be ignored" || echo "OK: debug committed"
```

Validation:
- Plan files created in topic/plans/ subdirectory
- Topic directories have all standard subdirectories
- spec-updater successfully validates structure
- No errors or warnings during plan creation

---

### Phase 3: Update `/report` and `/debug` Commands for Topic Integration [COMPLETED]
**Dependencies**: [1, 2]
**Risk**: Medium
**Estimated Time**: 3-4 hours

**Objective**: Integrate topic-based utilities and spec-updater agent into `/report` and `/debug` commands

Tasks:
- [x] Update `/report` command workflow (.claude/commands/report.md:1-300)
  - Extract topic from research question via `extract_topic_from_question()`
  - Get/create topic directory via `get_or_create_topic_dir()`
  - Use topic/reports/ subdirectory for report file
  - Get next report number via `get_next_artifact_number(topic_dir/reports)`

- [x] Add spec-updater invocation to `/report` (.claude/commands/report.md:300-400)
  - After report file is written
  - Invoke spec-updater agent to update cross-references
  - Pass report path, topic directory, related plan path (if any)
  - spec-updater adds report reference to plan metadata

- [x] Create spec-updater invocation template for report creation (.claude/commands/report.md:402-470)
  ```markdown
  Task tool invocation:
  subagent_type: general-purpose
  description: "Update cross-references for new report"
  prompt: |
    Read and follow: .claude/agents/spec-updater.md

    Context:
    - Report created at: {report_path}
    - Topic directory: {topic_dir}
    - Related plan: {plan_path} (if exists)
    - Operation: report_creation

    Tasks:
    - If related plan exists, add report reference to plan metadata
    - Update plan's Research Reports section
    - Validate cross-references are bidirectional

    Return:
    - Cross-reference update status
    - Plan files modified (if any)
  ```

- [x] Update `/debug` command workflow (.claude/commands/debug.md:1-350)
  - Extract topic from issue description or use plan's topic
  - Get/create topic directory (usually same as plan's topic)
  - Use topic/debug/ subdirectory for debug report file
  - Get next debug number via `get_next_artifact_number(topic_dir/debug)`

- [x] Add spec-updater invocation to `/debug` (.claude/commands/debug.md:350-450)
  - After debug report file is written
  - Invoke spec-updater agent to link debug report to plan
  - Pass debug report path, plan path, phase number (if applicable)
  - spec-updater updates plan with debug report reference

- [x] Create spec-updater invocation template for debug report creation (.claude/commands/debug.md:452-520)
  ```markdown
  Task tool invocation:
  subagent_type: general-purpose
  description: "Link debug report to plan"
  prompt: |
    Read and follow: .claude/agents/spec-updater.md

    Context:
    - Debug report created at: {debug_report_path}
    - Topic directory: {topic_dir}
    - Related plan: {plan_path}
    - Failed phase: {phase_number} (if applicable)
    - Operation: debug_report_creation

    Tasks:
    - Add debug report reference to plan metadata
    - If phase specified, add note to phase section
    - Update plan's Debug Reports section
    - Verify debug/ subdirectory is not gitignored

    Return:
    - Link status
    - Plan modifications
    - Gitignore validation result
  ```

- [x] Update command documentation (.claude/commands/report.md:600-650, .claude/commands/debug.md:600-650)
  - Document topic-based artifact creation
  - Add examples with topic directories
  - Note cross-referencing behavior

Testing:
```bash
# Test report creation
/report "Research JWT token security best practices"

# Verify report in topic directory
report_file=$(find specs/NNN_token_security/reports -name "001_*.md")
[[ -f "$report_file" ]] || echo "FAIL: report location"

# Verify cross-reference if plan exists
if [[ -f "specs/NNN_token_security/plans/001_*.md" ]]; then
  grep -q "$(basename "$report_file")" specs/NNN_token_security/plans/001_*.md || echo "FAIL: cross-reference"
fi

# Test debug report creation
/debug "Token refresh fails after 1 hour" specs/NNN_token_security/plans/001_*.md

# Verify debug report location
debug_file=$(find specs/NNN_token_security/debug -name "001_*.md")
[[ -f "$debug_file" ]] || echo "FAIL: debug location"

# Verify gitignore compliance for debug
git check-ignore "$debug_file" && echo "FAIL: debug should be committed" || echo "OK: debug not ignored"

# Verify cross-reference in plan
grep -q "$(basename "$debug_file")" specs/NNN_token_security/plans/001_*.md || echo "FAIL: debug cross-ref"
```

Validation:
- Reports created in topic/reports/ subdirectory
- Debug reports created in topic/debug/ subdirectory
- Cross-references added to plan files
- Gitignore compliance verified (debug/ committed)
- spec-updater successfully updates cross-references

---

### Phase 4: Migrate Existing Flat Structure to Topic-Based
**Dependencies**: [1, 2, 3]
**Risk**: High
**Estimated Time**: 4-5 hours

**Objective**: Migrate all existing spec artifacts from flat structure to topic-based directories

Tasks:
- [ ] Create migration script `.claude/scripts/migrate_to_topic_structure.sh` (.claude/scripts/migrate_to_topic_structure.sh:1-300)
  - Scan flat `specs/plans/`, `specs/reports/`, `specs/summaries/` directories
  - Group artifacts by related topic (use plan metadata, naming patterns)
  - Create topic directories for each group
  - Move artifacts to appropriate topic subdirectories
  - Preserve original numbering or renumber sequentially
  - Update cross-references in all moved files

- [ ] Implement artifact grouping logic (.claude/scripts/migrate_to_topic_structure.sh:50-150)
  - Parse plan metadata for feature name
  - Extract keywords from plan title
  - Use `extract_topic_from_question()` for consistent naming
  - Group plans, reports, summaries with matching keywords
  - Example: "026_agential_system_refinement.md" → "026_agential_system/" topic

- [ ] Implement safe migration with backups (.claude/scripts/migrate_to_topic_structure.sh:152-220)
  - Create backup of entire specs/ directory before migration
  - Backup location: `specs/backups/pre_migration_$(date +%Y%m%d_%H%M%S)/`
  - Copy files to new locations (don't delete originals until verified)
  - Validate all files copied correctly
  - Update all cross-references to new paths

- [ ] Implement cross-reference update logic (.claude/scripts/migrate_to_topic_structure.sh:222-280)
  - Parse all markdown files for artifact references
  - Update paths from `specs/plans/NNN_*.md` to `specs/NNN_topic/plans/NNN_*.md`
  - Update paths in CLAUDE.md examples
  - Verify no broken links remain

- [ ] Run migration script with dry-run mode (.claude/scripts/migrate_to_topic_structure.sh:10-20)
  ```bash
  #!/usr/bin/env bash
  # Dry-run flag shows what would be moved without making changes
  DRY_RUN="${DRY_RUN:-true}"
  ```

- [ ] Execute migration
  ```bash
  # Dry run first
  DRY_RUN=true .claude/scripts/migrate_to_topic_structure.sh

  # Review dry-run output, verify groupings are correct

  # Execute migration
  DRY_RUN=false .claude/scripts/migrate_to_topic_structure.sh

  # Verify migration success
  .claude/scripts/validate_migration.sh
  ```

- [ ] Create migration validation script `.claude/scripts/validate_migration.sh` (.claude/scripts/validate_migration.sh:1-150)
  - Check all topic directories have standard subdirectories
  - Verify no artifacts remain in flat directories
  - Validate all cross-references point to valid files
  - Check gitignore compliance for all topics
  - Generate migration report

- [ ] Archive or remove flat structure directories
  - Option 1: Archive to `specs/archived_flat_structure/`
  - Option 2: Remove flat directories if validation 100% successful
  - Document migration in `specs/MIGRATION.md`

Testing:
```bash
# Run migration validation
.claude/scripts/validate_migration.sh

# Check for remaining flat structure
[[ -z "$(ls specs/plans/*.md 2>/dev/null)" ]] || echo "FAIL: plans remain in flat structure"
[[ -z "$(ls specs/reports/*.md 2>/dev/null)" ]] || echo "FAIL: reports remain in flat structure"

# Verify topic directories exist
topic_count=$(find specs -maxdepth 1 -type d -name "[0-9][0-9][0-9]_*" | wc -l)
[[ $topic_count -gt 0 ]] || echo "FAIL: no topic directories"

# Validate cross-references
broken_links=$(grep -r "specs/plans/[0-9]" specs/[0-9]*/  | wc -l)
[[ $broken_links -eq 0 ]] || echo "FAIL: $broken_links broken cross-references"

# Verify gitignore compliance
debug_ignored=$(find specs/*/debug -type d -exec git check-ignore {} \; | wc -l)
[[ $debug_ignored -eq 0 ]] || echo "FAIL: debug directories are gitignored"
```

Validation:
- All artifacts successfully moved to topic directories
- No artifacts remain in flat structure
- All cross-references updated and valid
- Gitignore compliance maintained
- Backup created and verified
- Migration report generated

---

### Phase 5: Update Command Integration Tests
**Dependencies**: [1, 2, 3, 4]
**Risk**: Low
**Estimated Time**: 2-3 hours

**Objective**: Update all command integration tests to expect topic-based artifact creation

Tasks:
- [ ] Update `/plan` command tests (.claude/tests/test_command_integration.sh:50-150)
  - Modify assertions to check for topic directory creation
  - Verify plan file in `specs/NNN_topic/plans/` not `specs/plans/`
  - Add test for spec-updater invocation
  - Test topic extraction from various feature descriptions

- [ ] Update `/report` command tests (.claude/tests/test_command_integration.sh:152-220)
  - Verify report file in `specs/NNN_topic/reports/` subdirectory
  - Test cross-reference creation in related plans
  - Add test for spec-updater invocation

- [ ] Update `/debug` command tests (.claude/tests/test_command_integration.sh:222-290)
  - Verify debug report in `specs/NNN_topic/debug/` subdirectory
  - Test debug report not gitignored
  - Verify cross-reference added to plan
  - Add test for spec-updater invocation

- [ ] Update `/implement` command tests (.claude/tests/test_command_integration.sh:292-400)
  - Verify implementation summary in `specs/NNN_topic/summaries/` subdirectory
  - Test spec-updater invocation after phase completion (already should exist)
  - Verify checkbox hierarchy updates

- [ ] Update `/orchestrate` command tests (.claude/tests/test_command_integration.sh:402-550)
  - Verify all workflow artifacts in topic directory
  - Test research reports, plan, summary all in same topic
  - Verify spec-updater invocation in Documentation Phase

- [ ] Add new test suite for topic utilities (.claude/tests/test_topic_utilities.sh:1-250)
  ```bash
  test_extract_topic_from_question() {
    local topic=$(extract_topic_from_question "Implement OAuth2 with Google")
    [[ "$topic" == "oauth2_google" ]] || return 1
  }

  test_find_matching_topic() {
    # Create test topic
    mkdir -p specs/042_authentication

    local match=$(find_matching_topic "auth")
    [[ "$match" == "specs/042_authentication" ]] || return 1

    # Cleanup
    rmdir specs/042_authentication
  }

  test_get_or_create_topic_dir() {
    local topic_dir=$(get_or_create_topic_dir "test_feature" "specs")
    [[ -d "$topic_dir/plans" ]] || return 1
    [[ -d "$topic_dir/debug" ]] || return 1

    # Cleanup
    rm -rf "$topic_dir"
  }

  test_validate_gitignore_compliance() {
    # Create test topic
    local topic_dir=$(get_or_create_topic_dir "test_compliance" "specs")

    local compliance=$(validate_gitignore_compliance "$topic_dir")
    echo "$compliance" | jq -e '.debug_committed == true' || return 1

    # Cleanup
    rm -rf "$topic_dir"
  }
  ```

- [ ] Run all tests and verify pass rate
  ```bash
  cd /home/benjamin/.config
  .claude/tests/run_all_tests.sh
  ```

- [ ] Fix any failing tests related to topic-based changes
  - Update expected paths
  - Update assertion logic
  - Add new assertions for spec-updater behavior

Testing:
```bash
# Run command integration tests
.claude/tests/test_command_integration.sh

# Run topic utility tests
.claude/tests/test_topic_utilities.sh

# Check overall test coverage
coverage_report=$(grep -E "(PASS|FAIL)" .claude/tests/*.sh.log | wc -l)
pass_count=$(grep "PASS" .claude/tests/*.sh.log | wc -l)
pass_rate=$(( pass_count * 100 / coverage_report ))
[[ $pass_rate -ge 80 ]] || echo "FAIL: Test pass rate $pass_rate% < 80%"
```

Validation:
- All command integration tests pass
- Topic utility tests have ≥80% coverage
- No regressions in existing functionality
- New tests verify spec-updater integration

---

### Phase 6: Documentation and Validation
**Dependencies**: [1, 2, 3, 4, 5]
**Risk**: Low
**Estimated Time**: 2-3 hours

**Objective**: Update all documentation to reflect topic-based structure and validate system-wide compliance

Tasks:
- [ ] Update CLAUDE.md examples with topic-based paths (CLAUDE.md:76-120)
  - Update Directory Structure Example to show actual topic directories
  - Update all command usage examples with topic paths
  - Update Spec Updater Integration section with new integration points

- [ ] Update command documentation (.claude/commands/plan.md, .claude/commands/report.md, .claude/commands/debug.md)
  - Add "Topic-Based Organization" section to each command
  - Document topic extraction and directory creation workflow
  - Add examples showing topic directory structure
  - Document spec-updater integration points

- [ ] Update spec-updater agent documentation (.claude/agents/spec-updater.md)
  - Document new invocation points (plan creation, report creation, debug report creation)
  - Add examples for each operation type
  - Document cross-reference update behavior
  - Add gitignore validation documentation

- [ ] Create topic-based organization guide (.claude/docs/topic_based_organization.md:1-500)
  - Comprehensive guide to topic-based spec organization
  - Topic discovery workflow (find existing vs. create new)
  - Numbering conventions within topics
  - Cross-referencing best practices
  - Gitignore compliance rules
  - Migration guide for future users
  - Troubleshooting common issues

- [ ] Update README files in specs/ directories
  - Create `specs/README.md` explaining topic-based structure
  - Add README.md to each topic directory explaining its artifacts
  - Document cross-reference conventions

- [ ] Create system-wide validation script `.claude/scripts/validate_topic_structure.sh` (.claude/scripts/validate_topic_structure.sh:1-300)
  - Check all topics have standard subdirectories
  - Validate numbering within each artifact type
  - Verify cross-references are valid
  - Check gitignore compliance
  - Generate compliance report

- [ ] Run final validation
  ```bash
  .claude/scripts/validate_topic_structure.sh > specs/validation_report.md
  ```

- [ ] Review validation report and fix any issues
  - Broken cross-references
  - Missing subdirectories
  - Gitignore violations
  - Numbering gaps or duplicates

Testing:
```bash
# Validate topic structure
.claude/scripts/validate_topic_structure.sh

# Check documentation completeness
doc_files=(
  "CLAUDE.md"
  ".claude/docs/topic_based_organization.md"
  ".claude/commands/plan.md"
  ".claude/commands/report.md"
  ".claude/commands/debug.md"
  ".claude/agents/spec-updater.md"
)

for file in "${doc_files[@]}"; do
  [[ -f "$file" ]] || echo "FAIL: Missing $file"
  grep -q "topic-based" "$file" || echo "FAIL: $file doesn't document topic-based structure"
done

# Verify validation script exists and is executable
[[ -x ".claude/scripts/validate_topic_structure.sh" ]] || echo "FAIL: validation script not executable"

# Run validation and check for errors
error_count=$(./claude/scripts/validate_topic_structure.sh | grep -c "ERROR" || true)
[[ $error_count -eq 0 ]] || echo "FAIL: $error_count validation errors"
```

Validation:
- All documentation updated with topic-based examples
- Topic-based organization guide comprehensive and clear
- Validation script runs successfully
- Validation report shows 100% compliance
- No broken cross-references
- All gitignore rules correctly applied

## Testing Strategy

### Unit Tests
- Test each new utility function independently
- Mock file system operations where appropriate
- Verify error handling for edge cases

### Integration Tests
- Test full command workflows (plan → report → implement → summary)
- Verify cross-references created correctly
- Test spec-updater integration at each invocation point

### Migration Tests
- Test migration script on subset of artifacts (dry-run mode)
- Verify backup creation and restoration
- Test cross-reference updates

### Validation Tests
- Run validation script on migrated structure
- Check gitignore compliance across all topics
- Verify numbering correctness

### Regression Tests
- Ensure existing commands still work after migration
- Verify no loss of functionality
- Test backward compatibility where needed

## Documentation Requirements

### Command Documentation
- Update all command files with topic-based examples
- Document spec-updater integration points
- Add troubleshooting sections

### Utility Documentation
- Document all new utility functions
- Add usage examples for each function
- Document error codes and edge cases

### Architecture Documentation
- Create topic-based organization guide
- Document cross-reference conventions
- Add migration guide for reference

### User Documentation
- Update CLAUDE.md with topic-based structure
- Add examples showing typical workflows
- Document best practices

## Dependencies

### Internal Dependencies
- `.claude/lib/artifact-operations.sh` - Core artifact creation utilities
- `.claude/lib/template-integration.sh` - Topic utilities location
- `.claude/agents/spec-updater.md` - Agent role definition
- All command files that create spec artifacts

### External Dependencies
- `jq` - JSON processing for metadata
- `git` - Gitignore validation
- Bash 4.0+ - Array operations and associative arrays

## Risk Assessment

### High-Risk Areas
- **Phase 4 (Migration)**: Risk of data loss or broken cross-references
  - Mitigation: Comprehensive backups, dry-run mode, validation scripts
- **spec-updater Integration**: Risk of workflow interruptions if agent fails
  - Mitigation: Error handling, graceful degradation, fallback to manual updates

### Medium-Risk Areas
- **Command Updates**: Risk of breaking existing workflows
  - Mitigation: Extensive testing, backward compatibility where possible
- **Cross-Reference Updates**: Risk of creating broken links
  - Mitigation: Validation scripts, automated link checking

### Low-Risk Areas
- **Utility Functions**: New functions with isolated scope
  - Mitigation: Unit tests, clear interfaces
- **Documentation**: Updates don't affect functionality
  - Mitigation: Review before publishing

## Notes

### Research Integration
This plan incorporates findings from the research phase:
- Identified missing utilities (`find_matching_topic()`, `extract_topic_from_question()`)
- Documented current integration gaps (spec-updater only used in 2 of 5 commands)
- Addressed root cause of incomplete migration (commands use utilities directly without spec-updater)

### Phased Approach Rationale
- Phase 1: Foundation (utilities) - required by all subsequent phases
- Phase 2-3: Command updates - can be done in parallel after Phase 1
- Phase 4: Migration - requires working commands from Phase 2-3
- Phase 5: Testing - verifies phases 1-4
- Phase 6: Documentation - finalizes the implementation

### Future Enhancements
- Automated topic merging (combine overly granular topics)
- Topic analytics (artifact counts, age, activity)
- Cross-reference visualization (graph of plan/report relationships)
- Automated orphan detection (artifacts not linked to any plan)

## Spec Updater Checklist

When implementing this plan:
- [ ] Ensure plan is created in topic-based directory structure
- [ ] Create standard subdirectories (plans/, reports/, summaries/, debug/, scripts/, outputs/, artifacts/, backups/)
- [ ] Update cross-references when artifacts are moved during migration
- [ ] Create implementation summary in topic/summaries/ subdirectory when complete
- [ ] Verify gitignore compliance (debug/ committed, others ignored)
- [ ] Validate all cross-references are bidirectional and point to valid files
