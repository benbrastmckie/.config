# TODO.md Standards Multi-File Tracking Analysis

## Research Metadata

- **Date**: 2025-12-08
- **Research Topic**: Revise /todo command to support multi-file TODO.md tracking via CLAUDE.md standards discovery
- **Complexity**: 3
- **Workflow**: research-and-plan
- **Standards File**: /home/benjamin/.config/CLAUDE.md

## Executive Summary

The /todo command currently updates only `.claude/TODO.md` by scanning `.claude/specs/` directories. This research identifies that subdirectories with their own TODO.md files (like `nvim/lua/neotex/plugins/tools/himalaya/TODO.md`) are not tracked. The proposed solution enables the /todo command to:

1. Parse the 'TODO.md Standards' section in CLAUDE.md to discover which additional TODO.md files require updating
2. Delegate to subdirectory-specific update logic based on instructions in those sections
3. Support both centralized (.claude/TODO.md) and localized (nvim/TODO.md, etc.) task tracking

## Current Implementation Analysis

### Single-File Architecture

The /todo command implements a single-file update workflow:

**File**: `.claude/commands/todo.md`
**Primary Target**: `.claude/TODO.md` (hard-coded)
**Scan Scope**: `.claude/specs/{NNN_topic}/plans/*.md` only

**Key Components**:
- **Block 1**: Scans specs/ directories for numbered topic folders (000_xxx, 001_xxx, etc.)
- **Block 2a-2c**: Delegates to todo-analyzer agent (haiku-4.5) for batch plan classification
- **Block 3**: Generates TODO.md content with 7-section hierarchy (In Progress, Not Started, Research, Saved, Backlog, Abandoned, Completed)
- **Block 4**: Writes `.claude/TODO.md` with git snapshot backup

**Limitations**:
- No awareness of additional TODO.md files in subdirectories
- No standards discovery mechanism for multi-file tracking
- Hard-coded path: `TODO_PATH="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"`

### Discovered TODO.md Files

Found 2 TODO.md files in the project:

1. **Primary**: `/home/benjamin/.config/.claude/TODO.md`
   - Tracks .claude/ infrastructure specs (000-999)
   - Managed by /todo command
   - 7-section hierarchy (In Progress, Not Started, Research, Saved, Backlog, Abandoned, Completed)

2. **Nvim Himalaya**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/TODO.md`
   - Tracks himalaya plugin refactoring phases (Phase 1-10)
   - NOT managed by /todo command
   - Custom format: checkbox-based phase tracking with nested subtasks
   - Includes guidelines, implementation details, and future features sections

### CLAUDE.md Standards Section Analysis

The root CLAUDE.md contains a 'TODO.md Standards' section (lines 361-370):

```markdown
### TODO.md Standards

See [TODO Organization Standards](.claude/docs/reference/standards/todo-organization-standards.md) for complete TODO.md file organization, section hierarchy, checkbox conventions, and artifact inclusion rules.

**Quick Reference**:
- 6-section hierarchy: In Progress -> Not Started -> Backlog -> Superseded -> Abandoned -> Completed
- Checkboxes: `[ ]` (not started), `[x]` (in progress/completed/abandoned), `[~]` (superseded)
- Backlog section is manually curated and preserved by /todo command
- Completed section uses date-grouped entries (newest first)
```

**Current Limitations**:
- References only the .claude/TODO.md standards (7-section hierarchy, note: documentation shows 6-section but implementation uses 7-section)
- Does not specify which files need updating
- Does not provide update instructions for subdirectory TODO.md files

### Subdirectory Standards Discovery

The nvim/CLAUDE.md (lines 1-225) provides Neovim-specific standards but does NOT include a TODO.md standards section. This means:

- No documented update instructions for nvim/lua/neotex/plugins/tools/himalaya/TODO.md
- No integration with /todo command workflow
- Manual updates only

## Standards Discovery Pattern Analysis

### Existing Pattern: Standards Inheritance

The project uses a standards inheritance pattern (CLAUDE.md lines 372-392):

```markdown
## Standards Discovery
[Used by: all commands]

### Discovery Method
Commands should discover standards by:
1. Searching upward from current directory for CLAUDE.md
2. Checking for subdirectory-specific CLAUDE.md files
3. Merging/overriding: subdirectory standards extend parent standards
```

**Key Insight**: Commands already implement upward CLAUDE.md discovery for standards. The /todo command can extend this pattern to discover TODO.md file locations.

### Proposed Extension: TODO.md Multi-File Discovery

Extend the 'TODO.md Standards' section in CLAUDE.md to support multi-file tracking:

**Root CLAUDE.md** (proposed):
```markdown
### TODO.md Standards

See [TODO Organization Standards](.claude/docs/reference/standards/todo-organization-standards.md) for complete TODO.md file organization, section hierarchy, checkbox conventions, and artifact inclusion rules.

**Quick Reference**:
- 7-section hierarchy: In Progress -> Not Started -> Research -> Saved -> Backlog -> Abandoned -> Completed
- Checkboxes: `[ ]` (not started), `[x]` (in progress/completed/abandoned)
- Backlog section is manually curated and preserved by /todo command
- Completed section uses date-grouped entries (newest first)

**Multi-File Tracking**:
The /todo command updates multiple TODO.md files based on subdirectory CLAUDE.md declarations:

1. **.claude/TODO.md** (primary): Tracks all .claude/specs/ projects (auto-updated)
2. **nvim/TODO.md** (if declared): Tracks nvim-specific tasks per nvim/CLAUDE.md instructions
3. **Additional files**: Discovered via subdirectory CLAUDE.md 'TODO.md Standards' sections

**Update Delegation**:
Subdirectory CLAUDE.md files declare TODO.md update instructions:
- **File Location**: Relative path to TODO.md file from project root
- **Update Script**: Path to update script or "manual" for manual updates
- **Scan Scope**: Directories to scan for tasks (e.g., lua/neotex/plugins/tools/)
- **Format**: Custom format specification or "inherit" to use 7-section hierarchy
```

**Subdirectory CLAUDE.md** (example: nvim/CLAUDE.md proposed):
```markdown
### TODO.md Standards

**File Location**: nvim/lua/neotex/plugins/tools/himalaya/TODO.md
**Update Method**: manual
**Scan Scope**: nvim/lua/neotex/plugins/tools/himalaya/
**Format**: Phase-based tracking (custom)

This TODO.md uses phase-based tracking with nested subtasks. Updates are manual only.
The /todo command should skip this file during auto-updates.

**Guidelines**:
- Use checkbox-based phase tracking
- Include GUIDELINES, DETAILS, and FUTURE FEATURES sections
- Commit after completing each phase
- Update spec files as phases are completed
```

## Technical Implementation Analysis

### Command Flow Extension

**Current /todo Flow**:
```
Block 1: Setup and Discovery
  └─> Scan .claude/specs/ only
  └─> Initialize state machine

Block 2a-2c: Classification (todo-analyzer agent)
  └─> Classify all discovered plans
  └─> Verify results

Block 3: Generate TODO.md
  └─> Build 7-section content
  └─> Preserve Backlog/Saved sections

Block 4: Write .claude/TODO.md
  └─> Atomic replace with git snapshot
```

**Proposed Multi-File Flow**:
```
Block 1: Setup and Multi-File Discovery
  └─> Scan CLAUDE.md for TODO.md Standards section
  └─> Parse declared TODO.md files (locations, update methods)
  └─> Scan .claude/specs/ (existing logic)
  └─> For each subdirectory with TODO.md declaration:
      └─> Scan subdirectory scope (if update method != "manual")
  └─> Initialize state machine

Block 2a-2c: Classification (todo-analyzer agent)
  └─> Classify all discovered plans (existing logic)
  └─> Verify results

Block 3a: Generate .claude/TODO.md (existing)
  └─> Build 7-section content
  └─> Preserve Backlog/Saved sections

Block 3b: Generate Subdirectory TODO.md Files (new)
  └─> For each non-manual TODO.md file:
      └─> Invoke subdirectory update script or
      └─> Apply custom format generation logic
  └─> Skip manual TODO.md files

Block 4: Write All TODO.md Files
  └─> Atomic replace .claude/TODO.md (existing)
  └─> Atomic replace subdirectory TODO.md files (new)
  └─> Create git snapshot for all changes
```

### Multi-File Discovery Algorithm

**Pseudocode**:
```bash
# 1. Parse root CLAUDE.md 'TODO.md Standards' section
TODO_FILES=()
TODO_FILES+=(".claude/TODO.md:auto:specs/:.claude/lib/todo/generate-main-todo.sh")

# 2. Find subdirectory CLAUDE.md files
for claudemd in $(find . -name "CLAUDE.md" -not -path "./.claude/*"); do
  SUBDIR=$(dirname "$claudemd")

  # 3. Check for 'TODO.md Standards' section
  if grep -q "### TODO.md Standards" "$claudemd"; then
    # 4. Extract metadata
    FILE_LOCATION=$(parse_field "$claudemd" "File Location")
    UPDATE_METHOD=$(parse_field "$claudemd" "Update Method")
    SCAN_SCOPE=$(parse_field "$claudemd" "Scan Scope")
    FORMAT=$(parse_field "$claudemd" "Format")

    # 5. Add to tracking list (skip if "manual")
    if [ "$UPDATE_METHOD" != "manual" ]; then
      TODO_FILES+=("$FILE_LOCATION:$UPDATE_METHOD:$SCAN_SCOPE:$FORMAT")
    fi
  fi
done

# 6. Process each TODO.md file
for entry in "${TODO_FILES[@]}"; do
  IFS=":" read -r file method scope format <<< "$entry"

  if [ "$method" = "auto" ]; then
    # Use default /todo logic (7-section hierarchy)
    generate_default_todo "$file" "$scope"
  elif [ "$method" = "script" ]; then
    # Invoke custom update script
    bash "$format" "$file" "$scope"
  fi
done
```

### Backward Compatibility

**Zero-Impact Design**:
- If no subdirectory CLAUDE.md files declare TODO.md standards, behavior identical to current
- Primary .claude/TODO.md update unchanged (existing 7-section logic preserved)
- Manual TODO.md files (like himalaya/TODO.md) remain manual-only
- No breaking changes to existing command interface

**Migration Path**:
1. Deploy multi-file discovery code (no CLAUDE.md changes yet)
2. Test with existing single-file workflow (should pass all tests)
3. Add subdirectory CLAUDE.md 'TODO.md Standards' sections incrementally
4. Verify each subdirectory TODO.md generation independently

## Use Cases and Benefits

### Use Case 1: Himalaya Plugin Development

**Current Workflow**:
```bash
# 1. Work on himalaya plugin
cd nvim/lua/neotex/plugins/tools/himalaya

# 2. Manually update TODO.md after each phase
vim TODO.md  # Mark phase complete, update status

# 3. Run /todo (only updates .claude/TODO.md)
/todo

# 4. Manually sync if spec created in .claude/specs/
vim TODO.md  # Add cross-reference to spec
```

**Proposed Workflow with Auto-Update**:
```bash
# 1. Declare TODO.md in nvim/CLAUDE.md with update script
### TODO.md Standards
File Location: nvim/lua/neotex/plugins/tools/himalaya/TODO.md
Update Method: script
Scan Scope: nvim/lua/neotex/plugins/tools/himalaya/
Script: nvim/scripts/update-himalaya-todo.sh

# 2. Work on himalaya plugin
cd nvim/lua/neotex/plugins/tools/himalaya

# 3. Run /todo (updates both .claude/TODO.md AND himalaya/TODO.md)
/todo
# Output:
# Updated .claude/TODO.md (245 projects)
# Updated nvim/lua/neotex/plugins/tools/himalaya/TODO.md (10 phases)
```

**Benefit**: Eliminates manual sync between .claude/specs/ and nvim/TODO.md files.

### Use Case 2: Documentation Task Tracking

**Scenario**: Track documentation tasks separately from implementation tasks

**Setup**:
```markdown
# docs/CLAUDE.md
### TODO.md Standards
File Location: docs/TODO.md
Update Method: auto
Scan Scope: docs/specs/
Format: inherit
```

**Workflow**:
```bash
# Create documentation spec
/plan "Update API reference documentation"
# -> Creates .claude/specs/050_api_docs_update/plans/001.md

# Run /todo
/todo
# -> Updates .claude/TODO.md (all specs)
# -> Creates docs/TODO.md (docs/specs/ only)

# Benefit: Separate tracking for docs team vs engineering team
cat docs/TODO.md  # Docs team sees only documentation tasks
cat .claude/TODO.md  # Engineering sees all tasks
```

### Use Case 3: Git Submodule Integration

**Scenario**: Project includes git submodule with its own TODO.md

**Setup**:
```markdown
# modules/external-lib/CLAUDE.md
### TODO.md Standards
File Location: modules/external-lib/TODO.md
Update Method: manual
Scan Scope: N/A
Format: upstream

This TODO.md is managed by the upstream project. Do not auto-update.
```

**Behavior**:
```bash
/todo
# Skips modules/external-lib/TODO.md (marked as "manual")
# Updates .claude/TODO.md only
```

**Benefit**: Respects upstream TODO.md ownership while maintaining local tracking.

## Edge Cases and Limitations

### Edge Case 1: Conflicting Section Names

**Problem**: Subdirectory TODO.md might use different section names than 7-section hierarchy.

**Example**:
```markdown
# himalaya/TODO.md
## PLAN
## DETAILS
## REFINE REFACTORS
## FUTURE FEATURES
```

**Solution**: Allow custom format specification in subdirectory CLAUDE.md:
```markdown
Format: custom
Sections: PLAN, DETAILS, REFINE REFACTORS, FUTURE FEATURES
```

The /todo command would skip auto-generation for custom formats (or invoke custom script).

### Edge Case 2: Circular CLAUDE.md References

**Problem**: Subdirectory CLAUDE.md might reference parent TODO.md.

**Example**:
```markdown
# subdir/CLAUDE.md
### TODO.md Standards
File Location: ../TODO.md  # References parent
```

**Solution**: Detect circular references during discovery:
```bash
# Track visited files
VISITED_TODOS=()

discover_todo_files() {
  local file="$1"

  # Normalize path
  local abs_path=$(realpath "$file")

  # Check if already visited
  if [[ " ${VISITED_TODOS[@]} " =~ " ${abs_path} " ]]; then
    echo "WARNING: Circular reference detected: $file" >&2
    return 1
  fi

  VISITED_TODOS+=("$abs_path")
}
```

### Edge Case 3: TODO.md Outside Project Root

**Problem**: CLAUDE.md might reference TODO.md outside project.

**Example**:
```markdown
File Location: /home/user/external-notes/TODO.md
```

**Solution**: Restrict to project-relative paths only:
```bash
validate_todo_path() {
  local path="$1"
  local project_root="$CLAUDE_PROJECT_DIR"
  local abs_path=$(realpath "$path")

  # Ensure path is under project root
  if [[ "$abs_path" != "$project_root"* ]]; then
    echo "ERROR: TODO.md path outside project root: $path" >&2
    return 1
  fi
}
```

### Limitation 1: Update Script Failures

If a subdirectory update script fails, the /todo command should:
- Log the error to centralized error log
- Skip that TODO.md file (preserve existing content)
- Continue with remaining TODO.md files
- Display warning in completion summary

**Error Recovery**:
```bash
for entry in "${TODO_FILES[@]}"; do
  if ! update_todo_file "$entry"; then
    log_command_error "file_error" "Failed to update TODO.md: $entry" "Block3b:SubdirectoryUpdate"
    echo "WARNING: Skipped TODO.md due to update failure: $entry" >&2
    SKIPPED_FILES+=("$entry")
  fi
done

# Completion summary includes skipped files
NEXT_STEPS="  • Review skipped files: ${SKIPPED_FILES[@]}
  • Check error log: /errors --command /todo --type file_error"
```

### Limitation 2: Format Divergence

Different TODO.md formats (7-section vs phase-based vs custom) may diverge over time, making unified tooling difficult.

**Mitigation**:
- Document format specifications in subdirectory CLAUDE.md
- Provide format validation scripts (optional)
- Encourage "inherit" format for subdirectories when possible

## Implementation Recommendations

### Phase 1: Discovery Infrastructure (Low Risk)

**Goal**: Add multi-file discovery without changing update logic.

**Changes**:
1. Add `discover_todo_files()` function to `.claude/lib/todo/todo-functions.sh`
2. Update Block 1 in `/todo` command to call discovery function
3. Store discovered TODO.md files in state machine
4. Pass to existing classification logic (no changes to Block 2)

**Validation**:
- Run /todo with no subdirectory CLAUDE.md files (should behave identically)
- Add mock subdirectory CLAUDE.md with "manual" update method
- Verify TODO.md discovered but not updated

**Estimated Effort**: 2-3 hours

### Phase 2: Update Delegation (Medium Risk)

**Goal**: Implement subdirectory TODO.md update logic.

**Changes**:
1. Add `update_subdirectory_todo()` function to todo-functions.sh
2. Add Block 3b to /todo command for subdirectory updates
3. Implement script invocation for "script" update method
4. Implement "inherit" format generation (reuse 7-section logic)
5. Add error handling for update failures

**Validation**:
- Create test subdirectory with CLAUDE.md + TODO.md
- Configure "inherit" format, run /todo
- Verify subdirectory TODO.md updated correctly
- Introduce intentional error, verify skip behavior

**Estimated Effort**: 4-6 hours

### Phase 3: Standards Documentation (Low Risk)

**Goal**: Document multi-file tracking in CLAUDE.md and standards files.

**Changes**:
1. Update root CLAUDE.md 'TODO.md Standards' section (add Multi-File Tracking subsection)
2. Update `.claude/docs/reference/standards/todo-organization-standards.md` (add Multi-File Discovery section)
3. Update `.claude/docs/guides/commands/todo-command-guide.md` (add Multi-File Usage Examples)
4. Add validation script: `scripts/validate-todo-declarations.sh`

**Validation**:
- Run validation script on example subdirectory CLAUDE.md files
- Verify documentation examples match implementation
- Check link validity with `validate-links-quick.sh`

**Estimated Effort**: 2-3 hours

### Phase 4: Optional - Custom Format Support (High Risk)

**Goal**: Support fully custom TODO.md formats via subdirectory-specific scripts.

**Changes**:
1. Add `invoke_custom_script()` function to todo-functions.sh
2. Define script interface contract (input: scan scope, output: TODO.md content)
3. Add script examples in `.claude/docs/guides/development/custom-todo-scripts.md`

**Validation**:
- Create reference implementation for himalaya plugin
- Test with various custom formats
- Document script contract and error handling

**Estimated Effort**: 6-8 hours (optional, defer if not needed)

### Total Estimated Effort

**Core Implementation (Phases 1-3)**: 8-12 hours
**Optional Custom Scripts (Phase 4)**: +6-8 hours if needed

## Alternative Approaches Considered

### Alternative 1: Git Submodule per Subdirectory

**Idea**: Move each subdirectory (nvim/, etc.) to separate git repositories with their own .claude/ infrastructure.

**Pros**:
- Complete isolation of TODO.md files
- Independent /todo commands per repository
- No multi-file tracking complexity

**Cons**:
- Massive restructuring effort (weeks)
- Breaks existing cross-references between .claude/specs/ and nvim/
- Complicates unified project management
- Submodule update friction

**Verdict**: Rejected due to high cost and disruption.

### Alternative 2: Unified TODO.md Format Enforcement

**Idea**: Require all TODO.md files to use 7-section hierarchy.

**Pros**:
- Simpler /todo command logic (single format)
- Consistent user experience across project

**Cons**:
- Breaks existing himalaya/TODO.md (phase-based format)
- Forces unnatural fit for subdirectory-specific workflows
- Limits flexibility for different team preferences

**Verdict**: Rejected due to format rigidity.

### Alternative 3: TODO.md Symlinks

**Idea**: Create symlinks from subdirectories to .claude/TODO.md.

**Pros**:
- No code changes needed
- Single source of truth

**Cons**:
- Confusing UX (nvim/TODO.md shows all .claude/specs/ projects)
- Doesn't solve format divergence problem
- Breaks separate tracking use cases

**Verdict**: Rejected due to poor UX.

### Recommended Approach: Multi-File Discovery (Proposed)

**Rationale**:
- Minimal code changes (extend existing discovery pattern)
- Backward compatible (zero impact if no subdirectory CLAUDE.md files)
- Flexible (supports manual, auto, script update methods)
- Respects format diversity (inherit vs custom)
- Aligns with existing standards discovery pattern

## Security and Safety Considerations

### Script Execution Safety

**Risk**: Malicious subdirectory CLAUDE.md could specify script path to sensitive system files.

**Mitigation**:
```bash
validate_update_script() {
  local script="$1"

  # 1. Must be relative path under project root
  if [[ "$script" = /* ]]; then
    echo "ERROR: Absolute paths not allowed for update scripts" >&2
    return 1
  fi

  # 2. Must be .sh file
  if [[ "$script" != *.sh ]]; then
    echo "ERROR: Update script must be .sh file" >&2
    return 1
  fi

  # 3. Must be executable
  if [ ! -x "$CLAUDE_PROJECT_DIR/$script" ]; then
    echo "ERROR: Update script not executable: $script" >&2
    return 1
  fi

  # 4. Must not escape project directory (no ../)
  if [[ "$script" =~ \.\. ]]; then
    echo "ERROR: Update script path must not contain .." >&2
    return 1
  fi
}
```

### Git Snapshot Coverage

**Current**: .claude/TODO.md gets git snapshot before update.

**Proposed**: Extend to all TODO.md files.

```bash
# Create snapshot commit for all TODO.md files
snapshot_all_todo_files() {
  local files_to_snapshot=()

  for entry in "${TODO_FILES[@]}"; do
    IFS=":" read -r file method scope format <<< "$entry"
    if [ -f "$CLAUDE_PROJECT_DIR/$file" ]; then
      files_to_snapshot+=("$file")
    fi
  done

  if [ ${#files_to_snapshot[@]} -gt 0 ]; then
    git add "${files_to_snapshot[@]}"
    git commit -m "chore: snapshot TODO.md files before /todo update"
  fi
}
```

### Concurrent Modification Handling

**Risk**: User manually edits TODO.md while /todo is running.

**Current Mitigation**: Atomic file replacement (mv) ensures no partial writes.

**Proposed Enhancement**: Add file locking for multi-file updates.

```bash
acquire_todo_locks() {
  for entry in "${TODO_FILES[@]}"; do
    IFS=":" read -r file method scope format <<< "$entry"
    local lock_file="$CLAUDE_PROJECT_DIR/$file.lock"

    if [ -f "$lock_file" ]; then
      echo "ERROR: TODO.md file locked: $file" >&2
      return 1
    fi

    touch "$lock_file"
  done
}

release_todo_locks() {
  for entry in "${TODO_FILES[@]}"; do
    IFS=":" read -r file method scope format <<< "$entry"
    rm -f "$CLAUDE_PROJECT_DIR/$file.lock"
  done
}

trap release_todo_locks EXIT
```

## Testing Strategy

### Unit Tests

**File**: `.claude/tests/unit/test_todo_multifile.sh`

```bash
test_discover_single_todo_file() {
  # Setup: No subdirectory CLAUDE.md files
  local result=$(discover_todo_files)
  assert_equals ".claude/TODO.md:auto:specs/:.claude/lib/todo/generate-main-todo.sh" "$result"
}

test_discover_multiple_todo_files() {
  # Setup: Add nvim/CLAUDE.md with TODO.md Standards section
  local result=$(discover_todo_files)
  assert_contains ".claude/TODO.md" "$result"
  assert_contains "nvim/TODO.md" "$result"
}

test_skip_manual_todo_files() {
  # Setup: Add himalaya/CLAUDE.md with "manual" update method
  local result=$(discover_todo_files)
  assert_not_contains "himalaya/TODO.md" "$result"
}

test_validate_script_path_security() {
  assert_fails validate_update_script "/etc/passwd"
  assert_fails validate_update_script "../../../etc/passwd"
  assert_fails validate_update_script "../../script.sh"
  assert_passes validate_update_script "nvim/scripts/update-todo.sh"
}
```

### Integration Tests

**File**: `.claude/tests/integration/test_todo_command_multifile.sh`

```bash
test_todo_updates_all_declared_files() {
  # Setup: Create test subdirectory with CLAUDE.md + TODO.md
  mkdir -p test-subdir
  create_test_claudemd "test-subdir/CLAUDE.md" "test-subdir/TODO.md" "auto"

  # Execute: Run /todo
  /todo

  # Verify: Both .claude/TODO.md and test-subdir/TODO.md updated
  assert_file_modified ".claude/TODO.md"
  assert_file_modified "test-subdir/TODO.md"
}

test_todo_preserves_backlog_in_subdirectory() {
  # Setup: Add Backlog section to test-subdir/TODO.md
  echo "## Backlog\n- Manual entry" >> test-subdir/TODO.md

  # Execute: Run /todo
  /todo

  # Verify: Backlog preserved in test-subdir/TODO.md
  assert_file_contains "test-subdir/TODO.md" "Manual entry"
}

test_todo_skips_failed_updates() {
  # Setup: Configure broken update script
  create_test_claudemd "test-subdir/CLAUDE.md" "test-subdir/TODO.md" "script"
  create_broken_script "test-subdir/broken-update.sh"

  # Execute: Run /todo
  /todo

  # Verify: .claude/TODO.md updated, test-subdir/TODO.md skipped
  assert_file_modified ".claude/TODO.md"
  assert_file_not_modified "test-subdir/TODO.md"
  assert_error_logged "file_error" "Failed to update TODO.md"
}
```

### Manual Testing Checklist

```markdown
- [ ] Run /todo with no subdirectory CLAUDE.md files (backward compatibility)
- [ ] Add nvim/CLAUDE.md with TODO.md Standards (File Location: nvim/TODO.md, Update Method: auto)
- [ ] Run /todo, verify nvim/TODO.md created with 7-section hierarchy
- [ ] Manually edit nvim/TODO.md Backlog section
- [ ] Run /todo again, verify Backlog preserved
- [ ] Change Update Method to "manual" in nvim/CLAUDE.md
- [ ] Run /todo, verify nvim/TODO.md not modified
- [ ] Create custom update script, configure "script" method
- [ ] Run /todo, verify script invoked and nvim/TODO.md updated
- [ ] Introduce script error (exit 1)
- [ ] Run /todo, verify error logged and nvim/TODO.md skipped
- [ ] Run /todo --dry-run, verify preview shows all TODO.md files to be updated
```

## Conclusion

The /todo command can be extended to support multi-file TODO.md tracking with minimal code changes by leveraging the existing standards discovery pattern. The proposed implementation:

1. **Discovers** subdirectory TODO.md files via CLAUDE.md 'TODO.md Standards' sections
2. **Delegates** updates based on declared update method (auto, script, manual)
3. **Preserves** backward compatibility (zero impact if no subdirectory declarations)
4. **Respects** format diversity (inherit vs custom)
5. **Secures** script execution with path validation

The phased implementation plan (Phases 1-3: 8-12 hours) provides low-risk incremental delivery with validation at each step. Optional Phase 4 (custom format support) can be deferred until specific use cases emerge.

**Next Steps**:
1. Create implementation plan based on Phase 1-3 recommendations
2. Implement discovery infrastructure (Phase 1)
3. Test with himalaya plugin TODO.md as pilot (Phase 2)
4. Document standards and update guides (Phase 3)

## Related Research

- [TODO Organization Standards](.claude/docs/reference/standards/todo-organization-standards.md) - Current TODO.md format specification
- [Command-TODO Integration Guide](.claude/docs/guides/development/command-todo-integration-guide.md) - How commands trigger TODO.md updates
- [TODO Command Guide](.claude/docs/guides/commands/todo-command-guide.md) - Complete /todo command documentation
- [Standards Discovery](CLAUDE.md#standards_discovery) - Pattern for CLAUDE.md inheritance

## Appendix: Code Snippets

### Snippet 1: discover_todo_files() Implementation

```bash
# discover_todo_files()
# Purpose: Discover all TODO.md files declared in CLAUDE.md files
# Returns: Array of "file:method:scope:format" entries
# Usage:
#   declare -a TODO_FILES
#   readarray -t TODO_FILES < <(discover_todo_files)
#
discover_todo_files() {
  local project_root="$CLAUDE_PROJECT_DIR"

  # Primary TODO.md (always included)
  echo ".claude/TODO.md:auto:specs/:.claude/lib/todo/generate-main-todo.sh"

  # Find subdirectory CLAUDE.md files
  while IFS= read -r claudemd; do
    [ -z "$claudemd" ] && continue

    # Check for 'TODO.md Standards' section
    if ! grep -q "^### TODO.md Standards" "$claudemd"; then
      continue
    fi

    # Extract metadata using sed/awk
    local file_location=$(sed -n 's/^\*\*File Location\*\*: \(.*\)$/\1/p' "$claudemd" | head -1)
    local update_method=$(sed -n 's/^\*\*Update Method\*\*: \(.*\)$/\1/p' "$claudemd" | head -1)
    local scan_scope=$(sed -n 's/^\*\*Scan Scope\*\*: \(.*\)$/\1/p' "$claudemd" | head -1)
    local format=$(sed -n 's/^\*\*Format\*\*: \(.*\)$/\1/p' "$claudemd" | head -1)

    # Skip if manual or missing required fields
    if [ "$update_method" = "manual" ] || [ -z "$file_location" ]; then
      continue
    fi

    # Validate path security
    if ! validate_todo_path "$file_location"; then
      log_command_error "validation_error" "Invalid TODO.md path: $file_location" "discover_todo_files"
      continue
    fi

    # Output entry
    echo "${file_location}:${update_method}:${scan_scope}:${format}"
  done < <(find "$project_root" -name "CLAUDE.md" -not -path "*/.claude/*" 2>/dev/null)
}
```

### Snippet 2: Update Delegation Logic

```bash
# update_all_todo_files()
# Purpose: Update all discovered TODO.md files
# Returns: 0 on success, 1 if any updates failed
#
update_all_todo_files() {
  local -a skipped_files=()
  local -a updated_files=()

  # Discover all TODO.md files
  declare -a TODO_FILES
  readarray -t TODO_FILES < <(discover_todo_files)

  # Update each file
  for entry in "${TODO_FILES[@]}"; do
    IFS=":" read -r file method scope format <<< "$entry"

    echo "Updating TODO.md: $file (method: $method)"

    if [ "$method" = "auto" ]; then
      # Use default 7-section generation
      if generate_default_todo "$file" "$scope"; then
        updated_files+=("$file")
      else
        skipped_files+=("$file")
        echo "WARNING: Skipped $file (auto-generation failed)" >&2
      fi
    elif [ "$method" = "script" ]; then
      # Invoke custom script
      local script="$format"
      if bash "$CLAUDE_PROJECT_DIR/$script" "$file" "$scope"; then
        updated_files+=("$file")
      else
        skipped_files+=("$file")
        echo "WARNING: Skipped $file (script failed: $script)" >&2
      fi
    fi
  done

  # Report results
  echo ""
  echo "Updated ${#updated_files[@]} TODO.md files"
  if [ ${#skipped_files[@]} -gt 0 ]; then
    echo "Skipped ${#skipped_files[@]} TODO.md files due to errors"
    return 1
  fi

  return 0
}
```

### Snippet 3: Subdirectory CLAUDE.md Example

```markdown
# nvim/CLAUDE.md

# Neovim Configuration Guidelines

## TODO.md Standards
[Used by: /todo]

**File Location**: nvim/TODO.md
**Update Method**: auto
**Scan Scope**: nvim/lua/neotex/plugins/
**Format**: inherit

This TODO.md tracks Neovim plugin development tasks. The /todo command auto-updates this file by scanning nvim/lua/neotex/plugins/ for TODO comments and generating entries in the standard 7-section hierarchy.

**Scan Rules**:
- Scan lua files for TODO/FIXME/HACK comments
- Group by plugin directory (e.g., nvim/lua/neotex/plugins/lsp/ -> "LSP Configuration")
- Extract comment text as task description
- Default to "Not Started" section unless marked with [IN PROGRESS] or [COMPLETE]

**Preservation**:
- Backlog section manually curated (preserved across updates)
- Completed section uses date grouping (newest first)
```

---

**Report Completion Signal**: REPORT_CREATED: /home/benjamin/.config/.claude/specs/014_todo_standards_multifile/reports/001-todo-standards-multifile-analysis.md
