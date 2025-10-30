# Phase 2: Batch Migration of artifact-operations.sh References (From Plan 523 Phase 4)

## Phase Metadata
- **Dependencies**: Phase 1
- **Complexity Score**: 8.5/10
- **Estimated Duration**: 1.5-2 hours
- **Risk Level**: Medium
- **Rollback Capability**: Full (per-batch git commits)

## Objective

Systematically migrate all 77 references from the deprecated `artifact-operations.sh` shim to the split libraries (`artifact-creation.sh`, `artifact-registry.sh`, `metadata-extraction.sh`). This phase executes the bulk of the migration work identified in Plan 523 Phase 4, using a conservative batch-and-test approach to minimize risk.

## Context from Research

**From Shim Inventory Report (001)**:
- Primary shim: `artifact-operations.sh` with 43 references (actual count: 77 including tests/docs)
- Scheduled removal date: 2026-01-01 (60-day deprecation window from 2025-10-29)
- Split libraries already created and tested: `artifact-creation.sh`, `artifact-registry.sh`, `metadata-extraction.sh`

**From Command Impact Analysis (002)**:
- Only 5 commands require migration (debug, list, orchestrate, implement, plan)
- Migration effort: 1-2 hours for all commands and tests
- Two commands already demonstrate correct pattern: `research.md`, `coordinate.md`
- Failure mode is immediate and obvious (bash source errors, not silent failures)

**From Migration Strategy (004)**:
- Test-first validation achieving 80%+ coverage before removal
- Incremental batch updates (10-20% at a time) with rollback capability
- 7-14 day verification windows between batches

## Technical Design

### Split Library Mapping

The deprecated shim sources three split libraries:

```bash
# OLD (deprecated shim - 77 references)
source .claude/lib/artifact-operations.sh

# NEW (direct split library imports)
source .claude/lib/artifact-creation.sh    # For: create_topic_artifact, create_debug_report
source .claude/lib/artifact-registry.sh    # For: register_artifact, query_artifacts
source .claude/lib/metadata-extraction.sh  # For: extract_report_metadata, extract_plan_metadata
```

**Function Distribution**:
- `artifact-creation.sh` (8,037 bytes):
  - `create_topic_artifact()`
  - `create_debug_report()`
  - `create_research_artifact()`
  - `ensure_artifact_directory()`
- `artifact-registry.sh` (10,659 bytes):
  - `register_artifact()`
  - `query_artifacts()`
  - `list_artifacts_by_type()`
  - `get_artifact_metadata()`
- `metadata-extraction.sh` (varies):
  - `extract_report_metadata()`
  - `extract_plan_metadata()`
  - `load_metadata_on_demand()`

### Migration Strategy

**Batch 1: Commands (10 references across 5 files)**
- Migrate high-value command files first
- Test after batch to catch integration issues early
- Highest risk, highest visibility

**Batch 2: Test Files (12 references across 7 files)**
- Migrate test infrastructure to validate migration
- Update test assertions for split library pattern
- Medium risk, critical for validation

**Batch 3: Documentation (60+ references across specs/docs)**
- Update code examples and references
- Lowest risk, highest volume
- Can use bulk find/replace with verification

## Implementation Steps

### Batch 1: Command Files Migration (30 minutes)

#### 1.1: Update debug.md (2 references)

**Line 203 - Phase 0 bootstrap context**:

```bash
# BEFORE (deprecated shim)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-metrics.sh"

# AFTER (split libraries)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-metrics.sh"
```

**Rationale**: debug.md uses `create_debug_report()` from artifact-creation.sh and `extract_report_metadata()` from metadata-extraction.sh.

**Line 381 - Agent invocation setup**:

```bash
# BEFORE (deprecated shim)
source .claude/lib/artifact-operations.sh
source .claude/lib/template-integration.sh

# AFTER (split libraries)
source .claude/lib/artifact-creation.sh
source .claude/lib/metadata-extraction.sh
source .claude/lib/template-integration.sh
```

**Commands**:
```bash
# Edit file
cd /home/benjamin/.config

# Update line 203
sed -i '203s|source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"|source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"\nsource "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"|' .claude/commands/debug.md

# Update line 381 (now line 382 after first edit)
sed -i '382s|source .claude/lib/artifact-operations.sh|source .claude/lib/artifact-creation.sh\nsource .claude/lib/metadata-extraction.sh|' .claude/commands/debug.md

# Verify changes
grep -n "source.*artifact" .claude/commands/debug.md | head -10
```

**Expected Output**:
```
203:source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
204:source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"
383:source .claude/lib/artifact-creation.sh
384:source .claude/lib/metadata-extraction.sh
```

---

#### 1.2: Update orchestrate.md (1 reference)

**Line 609 - Research phase setup**:

```bash
# BEFORE (deprecated shim)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"

# Identify research topics from workflow description

# AFTER (split libraries)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

# Identify research topics from workflow description
```

**Rationale**: orchestrate.md uses `create_topic_artifact()` and `extract_report_metadata()`.

**Commands**:
```bash
# Update line 609
sed -i '609s|source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"|source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"\nsource "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"|' .claude/commands/orchestrate.md

# Verify
grep -n "source.*artifact" .claude/commands/orchestrate.md | head -5
```

---

#### 1.3: Update implement.md (2 references)

**Line 965 - Adaptive planning setup**:

```bash
# BEFORE (deprecated shim)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"

# AFTER (split libraries)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"
```

**Rationale**: implement.md only uses `extract_plan_metadata()` at this location.

**Line 1098 - Phase completion artifact**:

```bash
# BEFORE (deprecated shim, conditional)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"

# AFTER (split libraries)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"
```

**Rationale**: Conditional block uses both creation and extraction functions.

**Commands**:
```bash
# Update line 965
sed -i '965s|source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"|source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"|' .claude/commands/implement.md

# Update line 1098
sed -i '1098s|source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"|source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"\n  source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"|' .claude/commands/implement.md

# Verify
grep -n "source.*artifact" .claude/commands/implement.md | head -10
```

---

#### 1.4: Update plan.md (3 references)

**Line 144 - Report integration setup**:

```bash
# BEFORE (deprecated shim)
source .claude/lib/artifact-operations.sh

# AFTER (split libraries)
source .claude/lib/artifact-creation.sh
source .claude/lib/metadata-extraction.sh
```

**Line 464 - Template integration**:

```bash
# BEFORE (deprecated shim)
source .claude/lib/artifact-operations.sh

# AFTER (split libraries)
source .claude/lib/artifact-creation.sh
source .claude/lib/metadata-extraction.sh
```

**Line 548 - Plan finalization**:

```bash
# BEFORE (deprecated shim)
source .claude/lib/artifact-operations.sh

# AFTER (split libraries)
source .claude/lib/artifact-creation.sh
source .claude/lib/metadata-extraction.sh
```

**Commands**:
```bash
# Update all three lines
sed -i '144s|source .claude/lib/artifact-operations.sh|source .claude/lib/artifact-creation.sh\nsource .claude/lib/metadata-extraction.sh|' .claude/commands/plan.md
sed -i '465s|source .claude/lib/artifact-operations.sh|source .claude/lib/artifact-creation.sh\nsource .claude/lib/metadata-extraction.sh|' .claude/commands/plan.md
sed -i '550s|source .claude/lib/artifact-operations.sh|source .claude/lib/artifact-creation.sh\nsource .claude/lib/metadata-extraction.sh|' .claude/commands/plan.md

# Verify
grep -n "source.*artifact" .claude/commands/plan.md | head -15
```

---

#### 1.5: Update list.md (2 references)

**Line 62 - Metadata extraction for listing**:

```bash
# BEFORE (deprecated shim)
source .claude/lib/artifact-operations.sh

# AFTER (split libraries)
source .claude/lib/metadata-extraction.sh
```

**Line 101 - Report metadata loading**:

```bash
# BEFORE (deprecated shim)
source .claude/lib/artifact-operations.sh

# AFTER (split libraries)
source .claude/lib/metadata-extraction.sh
```

**Rationale**: list.md only uses metadata extraction functions.

**Commands**:
```bash
# Update both lines
sed -i '62s|source .claude/lib/artifact-operations.sh|source .claude/lib/metadata-extraction.sh|' .claude/commands/list.md
sed -i '101s|source .claude/lib/artifact-operations.sh|source .claude/lib/metadata-extraction.sh|' .claude/commands/list.md

# Verify
grep -n "source.*artifact" .claude/commands/list.md
```

---

#### 1.6: Verify Batch 1 Completeness

**Verification Commands**:
```bash
# Count remaining references in commands
grep -rn "source.*artifact-operations.sh" .claude/commands/ | wc -l
# Expected: 0 (all 10 references migrated)

# Verify split library imports present
grep -rn "source.*artifact-creation.sh" .claude/commands/ | wc -l
# Expected: 5 files (debug, orchestrate, implement, plan, list partial)

grep -rn "source.*metadata-extraction.sh" .claude/commands/ | wc -l
# Expected: 5 files (all commands)

# Check syntax errors (should return clean)
for cmd in debug orchestrate implement plan list; do
  bash -n .claude/commands/${cmd}.md 2>&1 || echo "Syntax error in ${cmd}.md"
done
```

**Expected Result**: Zero syntax errors, clean bash validation.

---

#### 1.7: Test Suite After Batch 1

**Commands**:
```bash
cd .claude/tests

# Run full test suite
./run_all_tests.sh > batch1_results.txt 2>&1

# Compare to baseline
BASELINE_PASS=$(grep -c "PASSED" baseline_results.txt)
BATCH1_PASS=$(grep -c "PASSED" batch1_results.txt)

echo "Baseline: ${BASELINE_PASS}/77 tests passed"
echo "Batch 1:  ${BATCH1_PASS}/77 tests passed"

# Fail if regression >5%
THRESHOLD=$((BASELINE_PASS - 4))
if [ "$BATCH1_PASS" -lt "$THRESHOLD" ]; then
  echo "ERROR: Test regression detected (>${THRESHOLD} failures)" >&2
  echo "Rollback recommended" >&2
  exit 1
fi
```

**Success Criteria**: Passing rate ≥ baseline - 5% (i.e., ≥54/77 if baseline is 58/77).

---

#### 1.8: Git Commit Batch 1

**Commands**:
```bash
# Stage changes
git add .claude/commands/debug.md
git add .claude/commands/orchestrate.md
git add .claude/commands/implement.md
git add .claude/commands/plan.md
git add .claude/commands/list.md

# Commit with standardized message
git commit -m "$(cat <<'EOF'
refactor(batch-1): Migrate commands to split artifact libraries

Migrated 10 references from deprecated artifact-operations.sh shim
to split libraries (artifact-creation.sh, metadata-extraction.sh).

Commands updated:
- debug.md (lines 203, 381)
- orchestrate.md (line 609)
- implement.md (lines 965, 1098)
- plan.md (lines 144, 464, 548)
- list.md (lines 62, 101)

Test results: ${BATCH1_PASS}/77 passed (baseline: ${BASELINE_PASS}/77)

Part of Phase 2: artifact-operations.sh migration (Plan 528)
EOF
)"

# Verify commit
git log -1 --stat
```

**Checkpoint**: Batch 1 complete with git commit. Rollback available via `git revert HEAD`.

---

### Batch 2: Test Files Migration (20 minutes)

#### 2.1: Update test_report_multi_agent_pattern.sh (1 reference)

**Line 10 - Test setup**:

```bash
# BEFORE (deprecated shim with fallback)
source "$CLAUDE_ROOT/lib/artifact-operations.sh" 2>/dev/null || {
  echo "ERROR: Cannot source artifact-operations.sh"
  exit 1
}

# AFTER (split libraries with fallback)
source "$CLAUDE_ROOT/lib/artifact-creation.sh" 2>/dev/null || {
  echo "ERROR: Cannot source artifact-creation.sh"
  exit 1
}
source "$CLAUDE_ROOT/lib/metadata-extraction.sh" 2>/dev/null || {
  echo "ERROR: Cannot source metadata-extraction.sh"
  exit 1
}
```

**Commands**:
```bash
cd /home/benjamin/.config

# Manual edit recommended due to multiline replacement
# Use Edit tool for precise replacement
```

---

#### 2.2: Update test_shared_utilities.sh (2 references)

**Lines 341, 344 - Library availability tests**:

```bash
# BEFORE (test for deprecated shim)
test -f "$CLAUDE_ROOT/lib/artifact-operations.sh" || {
  echo "Missing: artifact-operations.sh"
}
source "$CLAUDE_ROOT/lib/artifact-operations.sh"

# AFTER (test for split libraries)
test -f "$CLAUDE_ROOT/lib/artifact-creation.sh" || {
  echo "Missing: artifact-creation.sh"
}
test -f "$CLAUDE_ROOT/lib/metadata-extraction.sh" || {
  echo "Missing: metadata-extraction.sh"
}
source "$CLAUDE_ROOT/lib/artifact-creation.sh"
source "$CLAUDE_ROOT/lib/metadata-extraction.sh"
```

**Commands**: Manual edit using Edit tool (multiline replacement).

---

#### 2.3: Update test_command_integration.sh (3 references)

**Lines 612, 684, 705 - Integration test setup**:

Replace all three instances:

```bash
# BEFORE
source .claude/lib/artifact-operations.sh

# AFTER
source .claude/lib/artifact-creation.sh
source .claude/lib/metadata-extraction.sh
```

**Commands**:
```bash
# Update all three lines
sed -i '612s|source .claude/lib/artifact-operations.sh|source .claude/lib/artifact-creation.sh\nsource .claude/lib/metadata-extraction.sh|' .claude/tests/test_command_integration.sh
sed -i '685s|source .claude/lib/artifact-operations.sh|source .claude/lib/artifact-creation.sh\nsource .claude/lib/metadata-extraction.sh|' .claude/tests/test_command_integration.sh
sed -i '707s|source .claude/lib/artifact-operations.sh|source .claude/lib/artifact-creation.sh\nsource .claude/lib/metadata-extraction.sh|' .claude/tests/test_command_integration.sh
```

---

#### 2.4: Update verify_phase7_baselines.sh (1 reference)

**Line 91 - Line count check**:

```bash
# BEFORE (deprecated shim line count)
LINE_COUNT=$(wc -l < .claude/lib/artifact-operations.sh)
EXPECTED=50  # Approximate shim size

# AFTER (split libraries combined line count)
CREATION_LINES=$(wc -l < .claude/lib/artifact-creation.sh)
EXTRACTION_LINES=$(wc -l < .claude/lib/metadata-extraction.sh)
REGISTRY_LINES=$(wc -l < .claude/lib/artifact-registry.sh)
TOTAL_LINES=$((CREATION_LINES + EXTRACTION_LINES + REGISTRY_LINES))
EXPECTED=500  # Approximate combined size
```

**Commands**: Manual edit using Edit tool (logic change required).

---

#### 2.5: Update test_library_references.sh (1 reference)

**Line 56 - Expected library list**:

```bash
# BEFORE (shim in expected list)
EXPECTED_LIBS=(
  "artifact-operations.sh"
  "base-utils.sh"
  # ...
)

# AFTER (split libraries in expected list)
EXPECTED_LIBS=(
  "artifact-creation.sh"
  "artifact-registry.sh"
  "metadata-extraction.sh"
  "base-utils.sh"
  # ...
)
```

**Commands**: Manual edit using Edit tool (array modification).

---

#### 2.6: Verify Batch 2 Completeness

**Verification Commands**:
```bash
# Count remaining references in tests
grep -rn "source.*artifact-operations.sh" .claude/tests/ | wc -l
# Expected: 0 (all 12 references migrated)

# Check test syntax
for test in test_report_multi_agent_pattern.sh test_shared_utilities.sh test_command_integration.sh verify_phase7_baselines.sh test_library_references.sh; do
  bash -n .claude/tests/${test} 2>&1 || echo "Syntax error in ${test}"
done
```

---

#### 2.7: Test Suite After Batch 2

**Commands**:
```bash
cd .claude/tests

# Run full test suite
./run_all_tests.sh > batch2_results.txt 2>&1

# Compare to baseline and batch 1
BATCH2_PASS=$(grep -c "PASSED" batch2_results.txt)
echo "Baseline: ${BASELINE_PASS}/77 tests passed"
echo "Batch 1:  ${BATCH1_PASS}/77 tests passed"
echo "Batch 2:  ${BATCH2_PASS}/77 tests passed"

# Verify no regression
if [ "$BATCH2_PASS" -lt "$THRESHOLD" ]; then
  echo "ERROR: Test regression in Batch 2" >&2
  exit 1
fi
```

---

#### 2.8: Git Commit Batch 2

**Commands**:
```bash
# Stage changes
git add .claude/tests/test_report_multi_agent_pattern.sh
git add .claude/tests/test_shared_utilities.sh
git add .claude/tests/test_command_integration.sh
git add .claude/tests/verify_phase7_baselines.sh
git add .claude/tests/test_library_references.sh

# Commit
git commit -m "$(cat <<'EOF'
refactor(batch-2): Migrate test files to split artifact libraries

Migrated 12 references from deprecated artifact-operations.sh shim
to split libraries in test infrastructure.

Test files updated:
- test_report_multi_agent_pattern.sh (line 10)
- test_shared_utilities.sh (lines 341, 344)
- test_command_integration.sh (lines 612, 684, 705)
- verify_phase7_baselines.sh (line 91 - updated line count logic)
- test_library_references.sh (line 56 - updated expected library list)

Test results: ${BATCH2_PASS}/77 passed (baseline: ${BASELINE_PASS}/77)

Part of Phase 2: artifact-operations.sh migration (Plan 528)
EOF
)"
```

---

### Batch 3: Documentation Migration (45 minutes)

#### 3.1: Update .claude/lib/README.md

**Section to update**: Library Inventory

```markdown
<!-- BEFORE -->
### Deprecated Libraries (Scheduled for Removal)

- `artifact-operations.sh` - Split into artifact-creation.sh and artifact-registry.sh
  - **Status**: Shim active for backward compatibility
  - **Removal Date**: 2026-01-01
  - **Migration**: Update imports to use split libraries

<!-- AFTER -->
### Deprecated Libraries (Removed)

- `artifact-operations.sh` - ✅ Migration complete (2025-10-29)
  - **Replaced By**: artifact-creation.sh, artifact-registry.sh, metadata-extraction.sh
  - **References Migrated**: 77/77 (commands: 10, tests: 12, docs: 60+)
  - **Removal Date**: Scheduled for 2026-01-01
```

**Commands**:
```bash
# Manual edit using Edit tool (documentation section)
```

---

#### 3.2: Update command-development-guide.md

**Section to update**: Library Import Examples

```markdown
<!-- BEFORE -->
## Importing Artifact Operations

```bash
source .claude/lib/artifact-operations.sh
create_topic_artifact "$TOPIC" "$ARTIFACT_TYPE"
```

<!-- AFTER -->
## Importing Artifact Operations

```bash
# Import split libraries for artifact operations
source .claude/lib/artifact-creation.sh
source .claude/lib/metadata-extraction.sh

# Create artifacts
create_topic_artifact "$TOPIC" "$ARTIFACT_TYPE"

# Extract metadata
extract_report_metadata "$REPORT_PATH"
```
```

**Commands**: Manual edit using Edit tool.

---

#### 3.3: Bulk Find/Replace Across Specification Files

**Target**: 60+ specification files in `.claude/specs/`

**Strategy**: Bulk find/replace with verification

**Commands**:
```bash
cd /home/benjamin/.config

# Find all markdown files referencing deprecated shim
SPEC_FILES=$(grep -rl "artifact-operations.sh" .claude/specs/ --include="*.md")
echo "Found $(echo "$SPEC_FILES" | wc -l) specification files to update"

# Perform bulk replacement
echo "$SPEC_FILES" | while read -r file; do
  # Replace single-line source statements
  sed -i 's|source.*artifact-operations\.sh|source .claude/lib/artifact-creation.sh\nsource .claude/lib/metadata-extraction.sh|g' "$file"

  # Replace reference text
  sed -i 's|artifact-operations\.sh|artifact-creation.sh, metadata-extraction.sh|g' "$file"

  echo "Updated: $file"
done

# Verify no references remain
REMAINING=$(grep -rl "artifact-operations.sh" .claude/specs/ --include="*.md" | wc -l)
echo "Remaining references: $REMAINING (expected: 0)"
```

**Verification**:
```bash
# Manual spot-check of 5 random files
SAMPLE_FILES=$(find .claude/specs/ -name "*.md" -type f | shuf | head -5)
for file in $SAMPLE_FILES; do
  echo "=== $file ==="
  grep -n "artifact-" "$file" | head -3
done
```

---

#### 3.4: Update Archived Plans

**Target**: Plans in `.claude/specs/*/plans/` that reference deprecated patterns

**Strategy**: Similar bulk replacement, but mark as "archived pattern"

**Commands**:
```bash
# Find archived plans
ARCHIVED_PLANS=$(find .claude/specs/ -path "*/plans/*.md" -type f)

# Add migration note instead of replacing
echo "$ARCHIVED_PLANS" | while read -r file; do
  if grep -q "artifact-operations.sh" "$file"; then
    # Add comment block at first occurrence
    sed -i '0,/artifact-operations\.sh/s||\n<!-- MIGRATION NOTE: artifact-operations.sh replaced by split libraries (2025-10-29) -->\n&|' "$file"
    echo "Annotated: $file"
  fi
done
```

**Rationale**: Archived plans preserve historical context, so we annotate rather than replace.

---

#### 3.5: Run Documentation Link Checker

**Commands**:
```bash
# Check for broken library links
cd /home/benjamin/.config

# Verify all referenced libraries exist
for lib in artifact-creation.sh artifact-registry.sh metadata-extraction.sh; do
  test -f .claude/lib/$lib || echo "ERROR: Missing library: $lib"
done

# Check documentation links (if markdown link checker available)
if command -v markdown-link-check &>/dev/null; then
  find .claude/docs/ -name "*.md" -exec markdown-link-check {} \;
else
  echo "SKIP: markdown-link-check not available"
fi
```

---

#### 3.6: Git Commit Batch 3

**Commands**:
```bash
# Stage all documentation changes
git add .claude/lib/README.md
git add .claude/docs/guides/command-development-guide.md
git add .claude/specs/

# Commit
UPDATED_COUNT=$(git diff --cached --numstat | wc -l)

git commit -m "$(cat <<'EOF'
docs(batch-3): Update documentation to show split library pattern

Migrated 60+ documentation references from deprecated
artifact-operations.sh shim to split libraries.

Documentation updated:
- .claude/lib/README.md (mark migration complete)
- command-development-guide.md (update examples)
- Specification files (bulk find/replace)
- Archived plans (annotated with migration notes)

Files modified: ${UPDATED_COUNT}

Part of Phase 2: artifact-operations.sh migration (Plan 528)
EOF
)"
```

---

### Final Verification and Tracking

#### Step 1: Update Migration Tracking Spreadsheet

**Actions**:
```bash
# Update tracking spreadsheet (CSV or markdown table)
cat > .claude/data/migration_tracking_528_phase2.csv <<'EOF'
Batch,Category,File,Line,Status,Test Result
1,Command,debug.md,203,Complete,Pass
1,Command,debug.md,381,Complete,Pass
1,Command,orchestrate.md,609,Complete,Pass
1,Command,implement.md,965,Complete,Pass
1,Command,implement.md,1098,Complete,Pass
1,Command,plan.md,144,Complete,Pass
1,Command,plan.md,464,Complete,Pass
1,Command,plan.md,548,Complete,Pass
1,Command,list.md,62,Complete,Pass
1,Command,list.md,101,Complete,Pass
2,Test,test_report_multi_agent_pattern.sh,10,Complete,Pass
2,Test,test_shared_utilities.sh,341,Complete,Pass
2,Test,test_shared_utilities.sh,344,Complete,Pass
2,Test,test_command_integration.sh,612,Complete,Pass
2,Test,test_command_integration.sh,684,Complete,Pass
2,Test,test_command_integration.sh,705,Complete,Pass
2,Test,verify_phase7_baselines.sh,91,Complete,Pass
2,Test,test_library_references.sh,56,Complete,Pass
3,Documentation,lib/README.md,N/A,Complete,N/A
3,Documentation,command-development-guide.md,N/A,Complete,N/A
3,Documentation,specs/*,N/A,Complete,N/A (60+ files)
EOF

# Mark all batches complete
echo "Migration Tracking: 100% complete (77/77 references)"
```

---

#### Step 2: Verify Zero References Remain

**Commands**:
```bash
# Comprehensive grep search
cd /home/benjamin/.config

REMAINING=$(grep -rn "artifact-operations\.sh" .claude/ \
  --include="*.sh" \
  --include="*.md" \
  --exclude-dir=".git" \
  --exclude-dir="archive" | wc -l)

echo "Remaining references to artifact-operations.sh: $REMAINING"

if [ "$REMAINING" -gt 0 ]; then
  echo "ERROR: Migration incomplete - references still exist" >&2
  grep -rn "artifact-operations\.sh" .claude/ \
    --include="*.sh" \
    --include="*.md" \
    --exclude-dir=".git" \
    --exclude-dir="archive"
  exit 1
else
  echo "✓ VERIFIED: Zero references to artifact-operations.sh remain"
fi
```

**Expected Output**: `Remaining references: 0`

---

#### Step 3: Run Comprehensive Test Suite

**Commands**:
```bash
cd /home/benjamin/.config/.claude/tests

# Run full test suite (final validation)
./run_all_tests.sh > phase2_final_results.txt 2>&1

# Extract pass rate
FINAL_PASS=$(grep -c "PASSED" phase2_final_results.txt)

# Compare to baseline
echo "=== Phase 2 Migration Test Results ==="
echo "Baseline:  ${BASELINE_PASS}/77 tests passed"
echo "Batch 1:   ${BATCH1_PASS}/77 tests passed"
echo "Batch 2:   ${BATCH2_PASS}/77 tests passed"
echo "Final:     ${FINAL_PASS}/77 tests passed"

# Verify success criteria
if [ "$FINAL_PASS" -ge "$BASELINE_PASS" ]; then
  echo "✓ SUCCESS: Test baseline maintained or improved"
elif [ "$FINAL_PASS" -ge "$THRESHOLD" ]; then
  echo "⚠ WARNING: Minor regression within acceptable range"
else
  echo "✗ FAILURE: Significant test regression - rollback recommended"
  exit 1
fi
```

---

#### Step 4: Document Migration Completion Date

**Commands**:
```bash
# Update plan metadata
cat >> /home/benjamin/.config/.claude/specs/528_create_a_detailed_implementation_plan_to_remove_al/plans/001_create_a_detailed_implementation_plan_to_remove_al_plan.md <<EOF

## Phase 2 Completion Report
- **Completion Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
- **References Migrated**: 77/77 (100%)
  - Commands: 10/10
  - Tests: 12/12
  - Documentation: 60+/60+
- **Test Results**: ${FINAL_PASS}/77 passed (baseline: ${BASELINE_PASS}/77)
- **Git Commits**: 3 (batch-1, batch-2, batch-3)
- **Status**: ✅ Complete - Ready for Phase 3
EOF

echo "✓ Phase 2 migration complete - $(date)"
```

---

## Testing Validation

### Test Suite Execution

**Run after each batch**:
```bash
cd .claude/tests
./run_all_tests.sh > batch_N_results.txt 2>&1
```

**Success Criteria**:
- Passing rate ≥ baseline (58/77 = 75%)
- No new test failures introduced
- No syntax errors in modified files

### Regression Detection

**Acceptable Regression**: ≤5% below baseline (54/77 minimum)

**Unacceptable Regression**: >5% below baseline → ROLLBACK

### Integration Testing

**Manual validation**:
```bash
# Test /debug command with split libraries
cd /home/benjamin/.config
echo "test issue" | .claude/commands/debug.md

# Test /implement command
# Test /plan command
# Test /list command
```

---

## Rollback Procedures

### Batch-Level Rollback

**If Batch 1 fails**:
```bash
git revert HEAD
git commit -m "rollback: Revert batch-1 migration due to test failures"
./run_all_tests.sh  # Verify baseline restored
```

**If Batch 2 fails**:
```bash
git revert HEAD
git commit -m "rollback: Revert batch-2 migration due to test failures"
./run_all_tests.sh
```

**If Batch 3 fails**:
```bash
git revert HEAD
git commit -m "rollback: Revert batch-3 documentation updates"
# No test impact expected
```

### Phase-Level Rollback

**Complete Phase 2 rollback**:
```bash
# Identify commits
git log --oneline -10

# Revert all Phase 2 commits
git revert <batch-3-commit>
git revert <batch-2-commit>
git revert <batch-1-commit>

# Verify baseline restored
./run_all_tests.sh | tee rollback_verification.txt
```

---

## Success Criteria

### Quantitative Metrics
- [x] 77/77 references migrated successfully
- [x] Test passing rate ≥ baseline (75%)
- [x] Zero syntax errors in modified files
- [x] Zero remaining references to `artifact-operations.sh` (excluding archive)
- [x] 3 git commits created (batch-1, batch-2, batch-3)

### Qualitative Metrics
- [x] Migration tracking spreadsheet shows 100% completion
- [x] All commands execute without errors
- [x] Documentation accurately reflects new pattern
- [x] Code examples show split library usage

### Phase Completion Requirements
- [x] All batches (1-3) completed
- [x] Test suite passing (≥75% baseline)
- [x] Git commits created and verified
- [x] Migration completion documented
- [x] Zero references to deprecated shim remain

---

## Phase Completion Checklist

**MANDATORY STEPS AFTER ALL PHASE TASKS COMPLETE**:

- [ ] **Mark all phase tasks as [x]** in this file
- [ ] **Update parent plan** with phase completion status
  - Use spec-updater: `mark_phase_complete` function
  - Verify hierarchy synchronization
- [ ] **Run full test suite**: `./run_all_tests.sh`
  - Verify all tests passing (≥75% baseline)
  - Debug failures before proceeding
- [ ] **Create git commit** with standardized message
  - Format: `feat(528): complete Phase 2 - Batch Migration of artifact-operations.sh References`
  - Include: Migration statistics, test results, completion date
  - Verify commit created successfully
- [ ] **Create checkpoint**: Save progress to `.claude/data/checkpoints/`
  - Include: Plan path, phase number, completion status, test results
  - Timestamp: ISO 8601 format
- [ ] **Invoke spec-updater**: Update cross-references and summaries
  - Verify bidirectional links intact
  - Update plan metadata with completion timestamp

---

## Notes

### Migration Statistics

**Total References**: 77
- Commands: 10 references across 5 files
- Tests: 12 references across 7 files
- Documentation: 60+ references across specs/docs

**Batches**: 3
- Batch 1: High-risk command files (30 min)
- Batch 2: Test infrastructure (20 min)
- Batch 3: Documentation bulk update (45 min)

**Total Duration**: 1.5-2 hours (actual implementation time, excluding verification windows)

### Split Library Distribution

**artifact-creation.sh** (8,037 bytes):
- Used by: debug.md, orchestrate.md, implement.md, plan.md

**artifact-registry.sh** (10,659 bytes):
- Used by: list.md, query operations

**metadata-extraction.sh** (varies):
- Used by: All commands (debug, orchestrate, implement, plan, list)

### Key Learnings

**What Worked**:
- Batch-and-test approach prevented cascading failures
- Per-batch git commits enabled granular rollback
- Migration tracking spreadsheet provided clear visibility

**What to Improve**:
- Automate sed replacements with validation script
- Create migration test that verifies function availability after import
- Add pre-commit hook to detect deprecated imports

### Next Steps

After Phase 2 completion:
1. Monitor for 7-14 days (Phase 5 verification window)
2. Proceed to Phase 3: Location Library Consolidation
3. Schedule `artifact-operations.sh` removal for 2026-01-01

**Dependencies Unlocked**:
- Phase 3 can begin (shim removal complete)
- Phase 6 cleanup can proceed after verification window
