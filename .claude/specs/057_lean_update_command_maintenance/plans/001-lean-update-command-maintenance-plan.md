# /lean-update Command: Lean Project Maintenance Documentation Update

## Metadata
- **Date**: 2025-12-05
- **Feature**: /lean-update command for automated Lean project maintenance documentation updates
- **Status**: [COMPLETE]
- **Estimated Hours**: 30-50 hours
- **Complexity Score**: 185
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Lean Update Command Research Analysis](../reports/001-lean-update-command-maintenance-analysis.md)

## Overview

Create a /lean-update command that provides automated maintenance documentation updates for Lean theorem proving projects. The command will scan Lean source trees for sorry placeholders, update module completion percentages, validate cross-references, and maintain the six-document ecosystem used by the ProofChecker project (TODO.md, SORRY_REGISTRY.md, MAINTENANCE.md, IMPLEMENTATION_STATUS.md, KNOWN_LIMITATIONS.md, CLAUDE.md). This command extends the proven patterns from /todo to support multi-file documentation synchronization with Lean-specific verification.

**Key Features**:
- Multi-file documentation updates (6+ files)
- Automated sorry placeholder detection via grep
- Module completion percentage calculation
- Cross-reference integrity validation
- Optional build/test verification (lake build/test)
- Manual section preservation across documents
- Dry-run mode for change preview

**Architecture Philosophy**:
The /lean-update command will be created in the .config project but designed to operate on any Lean project with a .claude/ directory structure. It follows the portable command pattern where the command discovers the target project root and adapts to the local maintenance document structure.

## Success Criteria

- [ ] /lean-update command created at .claude/commands/lean-update.md
- [ ] lean-maintenance-analyzer agent created at .claude/agents/lean-maintenance-analyzer.md
- [ ] Command supports four modes: scan (default), verify, build, dry-run
- [ ] Automated sorry counting via grep matches SORRY_REGISTRY.md
- [ ] Module completion percentages derived from sorry counts
- [ ] Preservation of manually-curated sections across all documents
- [ ] Cross-reference validation detects broken bidirectional links
- [ ] Git snapshot created before updates (recovery mechanism)
- [ ] Multi-file atomic update with backup strategy
- [ ] Standardized 4-section console summary output
- [ ] Command guide documentation created
- [ ] Integration tests verify multi-file updates
- [ ] Dry-run mode previews all changes without modifications

## Technical Design

### Architecture

**Command Structure** (following /todo pattern):

```
/lean-update [--verify] [--with-build] [--dry-run]

Modes:
1. Scan Mode (default): Update all maintenance documents
2. Verify Mode (--verify): Check cross-references without updates
3. Build Mode (--with-build): Include lake build/test verification
4. Dry-Run Mode (--dry-run): Preview changes without modifications
```

**Six-Document Integration Model**:

```
                    ┌─────────────────┐
                    │   TODO.md       │
                    │  (Active Work)  │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
    ┌──────────────┐  ┌─────────────┐  ┌──────────────┐
    │ IMPL STATUS  │  │   SORRY     │  │   KNOWN      │
    │ (Module %)   │◄─┤  REGISTRY   │─►│ LIMITATIONS  │
    │              │  │ (Tech Debt) │  │ (Gaps)       │
    └──────────────┘  └─────────────┘  └──────────────┘
            │                │                │
            └────────────────┼────────────────┘
                             │
                    ┌────────▼────────┐
                    │  MAINTENANCE.md │
                    │   (Workflow)    │
                    └─────────────────┘
```

**Block Structure** (hard barrier pattern from /todo):

1. **Block 1**: Setup and Discovery
   - Argument parsing (--verify, --with-build, --dry-run)
   - Lean project detection (lakefile.toml, lean-toolchain)
   - Document path discovery (locate all 6 maintenance files)
   - Sorry placeholder scanning via grep
   - State persistence initialization

2. **Block 2a**: Pre-Calculate Output Paths
   - Calculate paths for all updated documents
   - Calculate temporary analysis report path
   - Persist all paths to state (hard barrier)
   - Validate paths are absolute

3. **Block 2b**: Documentation Analysis Execution
   - Delegate to lean-maintenance-analyzer agent via Task tool
   - Agent receives ALL current document paths
   - Agent scans Lean source tree for sorries
   - Agent generates JSON analysis report with recommended updates
   - Contract: MUST create analysis report at pre-calculated path

4. **Block 2c**: Analysis Report Verification
   - Verify analysis report exists at expected path
   - Verify JSON structure is valid
   - Verify file size > threshold
   - Verify required fields present (files, updates)
   - Verify sorry counts match grep verification

5. **Block 3**: Multi-File Updates
   - Extract preservation sections from each document
   - Apply updates from analysis report
   - Verify preservation sections unchanged
   - Atomic file replacement per document
   - Git snapshot before first update

6. **Block 4**: Cross-Reference Validation
   - Verify bidirectional links (A→B implies B→A)
   - Check for broken file references
   - Validate section structure per document
   - Report validation results

7. **Block 5**: Optional Build Verification
   - Run lake build (if --with-build flag)
   - Run lake test (if --with-build flag)
   - Report build/test status
   - Include results in summary

8. **Block 6**: Standardized Completion Output
   - 4-section console summary
   - List all updated documents
   - Report sorry count changes
   - Provide recovery commands

**Agent Delegation Strategy**:

Create `lean-maintenance-analyzer` agent with responsibilities:
1. **Input**: Lean project root, current maintenance docs, sorry counts
2. **Analysis**: Detect staleness, recommend updates per file/section
3. **Output**: JSON report with file-specific updates
4. **Format**: `{files: [{path, updates: [{section, old, new}]}]}`

**Preservation Strategy** (extending /todo pattern):

| Document | Preserved Sections | Extraction Pattern |
|----------|-------------------|-------------------|
| TODO.md | Backlog, Saved | `sed -n '/^## Section/,/^## /p'` |
| SORRY_REGISTRY.md | Resolved Placeholders | `sed -n '/^## Resolved/,/^## /p'` |
| IMPLEMENTATION_STATUS.md | Manual annotations | Inline `<!-- MANUAL -->` comments |
| KNOWN_LIMITATIONS.md | Workaround details | Preserve if not auto-generated |
| MAINTENANCE.md | Custom procedures | Preserve custom sections |
| CLAUDE.md | Project standards | Preserve custom sections |

### File Locations

**Command Location**:
- `/home/benjamin/.config/.claude/commands/lean-update.md`

**Agent Location**:
- `/home/benjamin/.config/.claude/agents/lean-maintenance-analyzer.md`

**Documentation Location**:
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-update-command-guide.md`

**Test Location**:
- `/home/benjamin/.config/.claude/tests/commands/test_lean_update_multi_file.sh`

### Sorry Detection Implementation

**Grep-Based Sorry Counting**:

```bash
# Count sorries per module
count_sorries_by_module() {
  local project_root="$1"
  local module_path="$2"

  grep -rn "sorry" "$project_root/$module_path" 2>/dev/null | wc -l
}

# Verify sorry count matches registry
verify_sorry_counts() {
  local registry_path="$1"
  local project_root="$2"

  # Extract count from registry
  local registry_count=$(grep -c "^- \*\*" "$registry_path" || echo "0")

  # Count actual sorries
  local actual_count=$(grep -r "sorry" "$project_root/Logos/**/*.lean" 2>/dev/null | wc -l)

  if [ "$registry_count" -ne "$actual_count" ]; then
    echo "WARNING: Sorry count mismatch (registry: $registry_count, actual: $actual_count)"
    return 1
  fi

  return 0
}
```

**Module Completion Calculation**:

```bash
# Calculate module completion percentage
calculate_module_completion() {
  local module_path="$1"
  local total_functions="$2"
  local sorry_count="$3"

  # Completion % = (total - sorries) / total * 100
  local completed=$((total_functions - sorry_count))
  local percentage=$((completed * 100 / total_functions))

  echo "$percentage"
}
```

### Cross-Reference Validation

**Bidirectional Link Verification**:

```bash
# Verify bidirectional links
validate_cross_references() {
  local doc_a="$1"
  local doc_b="$2"

  # Check A → B
  if ! grep -q "$(basename "$doc_b")" "$doc_a"; then
    echo "ERROR: $doc_a does not reference $doc_b"
    return 1
  fi

  # Check B → A
  if ! grep -q "$(basename "$doc_a")" "$doc_b"; then
    echo "ERROR: $doc_b does not reference $doc_a"
    return 1
  fi

  return 0
}
```

**Broken Reference Detection**:

```bash
# Check for broken file references
check_broken_references() {
  local doc_path="$1"
  local project_root="$2"

  # Extract all markdown links
  grep -oP '\[.*?\]\(\K[^)]+' "$doc_path" | while read link; do
    # Resolve relative path
    local abs_path="$(cd "$(dirname "$doc_path")" && realpath "$link" 2>/dev/null)"

    # Check file exists
    if [ ! -f "$abs_path" ]; then
      echo "WARNING: Broken reference in $doc_path: $link"
    fi
  done
}
```

## Implementation Phases

### Phase 1: Command Scaffolding [COMPLETE]
dependencies: []

**Objective**: Create /lean-update command structure with argument parsing and project detection

**Complexity**: Medium

**Tasks**:
- [x] Create .claude/commands/lean-update.md with frontmatter (file: .claude/commands/lean-update.md)
- [x] Implement Block 1: Setup and Discovery (argument parsing, library sourcing)
- [x] Add Lean project detection (search for lakefile.toml, lean-toolchain)
- [x] Add maintenance document path discovery (locate all 6 files)
- [x] Implement mode selection (scan, verify, build, dry-run)
- [x] Add error logging integration (error-handling.sh)
- [x] Add state persistence initialization
- [x] Add early trap setup for error capture

**Testing**:
```bash
# Verify command created
test -f .claude/commands/lean-update.md

# Test argument parsing
/lean-update --dry-run  # Should parse flag
/lean-update --verify   # Should parse flag
/lean-update --with-build --dry-run  # Should parse multiple flags

# Test project detection
cd /path/to/lean/project
/lean-update --dry-run  # Should detect Lean project

# Test document discovery
/lean-update --verify  # Should locate maintenance documents
```

**Expected Duration**: 4-6 hours

---

### Phase 2: Sorry Detection and Counting [COMPLETE]
dependencies: [1]

**Objective**: Implement automated sorry placeholder detection and module-based counting

**Complexity**: Medium

**Tasks**:
- [x] Implement grep-based sorry scanning (file: .claude/commands/lean-update.md, Block 1)
- [x] Add module-based grouping (Syntax, ProofSystem, Semantics, etc.)
- [x] Implement sorry count per module calculation
- [x] Add verification against SORRY_REGISTRY.md
- [x] Add module completion percentage calculation
- [x] Store sorry counts in workflow state
- [x] Add console output for discovered sorries

**Testing**:
```bash
# Test sorry detection
cd /path/to/lean/project
/lean-update --dry-run

# Verify output shows:
# - Sorry count per module
# - Module completion percentages
# - Comparison with SORRY_REGISTRY.md

# Test with project with no sorries
cd /path/to/complete/project
/lean-update --dry-run  # Should show 100% completion

# Test with project with known sorries
cd /path/to/partial/project
/lean-update --dry-run  # Should match known counts
```

**Expected Duration**: 5-7 hours

---

### Phase 3: Path Pre-Calculation (Hard Barrier) [COMPLETE]
dependencies: [2]

**Objective**: Implement Block 2a with pre-calculated paths for all documents and analysis report

**Complexity**: Low

**Tasks**:
- [x] Create Block 2a: Pre-Calculate Output Paths (file: .claude/commands/lean-update.md)
- [x] Pre-calculate paths for all 6 maintenance documents
- [x] Pre-calculate temporary analysis report path
- [x] Validate all paths are absolute
- [x] Persist all paths to workflow state
- [x] Add checkpoint output

**Testing**:
```bash
# Test path pre-calculation
/lean-update --dry-run

# Verify Block 2a output shows:
# - All 6 document paths (absolute)
# - Analysis report path (absolute)
# - Checkpoint message

# Verify state persistence
STATE_FILE=$(ls -t ~/.claude/data/state/lean_update_*.state | head -1)
grep -q "SORRY_REGISTRY_PATH" "$STATE_FILE"
grep -q "IMPL_STATUS_PATH" "$STATE_FILE"
grep -q "ANALYSIS_REPORT_PATH" "$STATE_FILE"
```

**Expected Duration**: 2-3 hours

---

### Phase 4: lean-maintenance-analyzer Agent [COMPLETE]
dependencies: [3]

**Objective**: Create specialized agent for Lean project analysis and update recommendations

**Complexity**: High

**Tasks**:
- [x] Create .claude/agents/lean-maintenance-analyzer.md (file: .claude/agents/lean-maintenance-analyzer.md)
- [x] Implement agent frontmatter with tool permissions
- [x] Add Lean source tree scanning logic
- [x] Add sorry placeholder analysis per module
- [x] Add staleness detection via git log analysis
- [x] Implement JSON analysis report generation
- [x] Add preservation policy respect per document
- [x] Add contract verification (required output format)
- [x] Add return signal: ANALYSIS_COMPLETE

**Agent Tools**:
- Read: Access Lean source and documentation
- Glob: Find Lean files by pattern
- Grep: Search for sorry placeholders
- Bash: Run git log queries
- Write: Create JSON analysis report

**Output Format**:
```json
{
  "files": [
    {
      "path": "/path/to/SORRY_REGISTRY.md",
      "updates": [
        {
          "section": "Active Placeholders",
          "old_content": "...",
          "new_content": "..."
        }
      ]
    }
  ],
  "sorry_counts": {
    "Syntax": 0,
    "ProofSystem": 0,
    "Semantics": 0,
    "Metalogic": 15,
    "Theorems": 8,
    "Automation": 22
  },
  "module_completion": {
    "Syntax": 100,
    "ProofSystem": 100,
    "Semantics": 100,
    "Metalogic": 60,
    "Theorems": 50,
    "Automation": 33
  }
}
```

**Testing**:
```bash
# Create test analysis report
echo '{"files": [], "sorry_counts": {}}' > /tmp/test_analysis.json

# Test agent directly (via Task tool simulation)
# Verify agent creates report at specified path
# Verify JSON structure is valid
# Verify sorry counts match grep

# Integration test with command
/lean-update --dry-run
# Verify agent invoked successfully
# Verify analysis report created
```

**Expected Duration**: 8-12 hours

---

### Phase 5: Analysis Report Verification [COMPLETE]
dependencies: [4]

**Objective**: Implement Block 2c with comprehensive verification of agent output

**Complexity**: Medium

**Tasks**:
- [x] Create Block 2c: Analysis Report Verification (file: .claude/commands/lean-update.md)
- [x] Verify analysis report exists at expected path
- [x] Verify file size > 500 bytes (not empty)
- [x] Validate JSON structure (jq parsing)
- [x] Verify required fields present (files, sorry_counts, module_completion)
- [x] Verify sorry counts match grep verification
- [x] Log verification errors with error-handling.sh
- [x] Add checkpoint output

**Testing**:
```bash
# Test with missing report
rm -f /path/to/analysis/report.json
/lean-update  # Should error: report not found

# Test with empty report
touch /path/to/analysis/report.json
/lean-update  # Should error: file too small

# Test with invalid JSON
echo "invalid json" > /path/to/analysis/report.json
/lean-update  # Should error: JSON parse failed

# Test with valid report
echo '{"files": [], "sorry_counts": {}}' > /path/to/analysis/report.json
/lean-update  # Should pass verification

# Test sorry count mismatch
# Analysis report: 10 sorries
# Actual grep: 15 sorries
# Should warn about mismatch
```

**Expected Duration**: 3-4 hours

---

### Phase 6: Multi-File Update Implementation [COMPLETE]
dependencies: [5]

**Objective**: Implement Block 3 with preservation, atomic updates, and git snapshot

**Complexity**: High

**Tasks**:
- [x] Create Block 3: Multi-File Updates (file: .claude/commands/lean-update.md)
- [x] Implement preservation extraction for each document
- [x] Apply updates from analysis report per file/section
- [x] Verify preservation sections unchanged after updates
- [x] Implement atomic file replacement per document
- [x] Create git snapshot before first update
- [x] Add rollback mechanism on failure
- [x] Support dry-run mode (preview without applying)
- [x] Add per-file update logging

**Preservation Implementation**:
```bash
# Extract preservation section
extract_preservation_section() {
  local doc_path="$1"
  local section_name="$2"

  sed -n "/^## $section_name/,/^## /p" "$doc_path" | sed '$d' || echo ""
}

# Verify preservation after update
verify_preservation() {
  local original_section="$1"
  local new_section="$2"
  local doc_name="$3"

  if [ "$original_section" != "$new_section" ]; then
    echo "ERROR: Preserved section modified in $doc_name"
    return 1
  fi

  return 0
}
```

**Testing**:
```bash
# Test preservation extraction
/lean-update --dry-run
# Verify Backlog section extracted from TODO.md
# Verify Saved section extracted from TODO.md
# Verify Resolved section extracted from SORRY_REGISTRY.md

# Test git snapshot
cd /path/to/lean/project
/lean-update
# Verify git commit created before updates
# Verify commit message includes workflow ID

# Test atomic updates
/lean-update
# Verify all 6 files updated atomically
# Verify tmp files cleaned up

# Test rollback on failure
# Simulate update failure mid-process
# Verify git recovery possible via snapshot

# Test dry-run mode
/lean-update --dry-run
# Verify no files modified
# Verify preview output shows proposed changes
```

**Expected Duration**: 10-14 hours

---

### Phase 7: Cross-Reference Validation [COMPLETE]
dependencies: [6]

**Objective**: Implement Block 4 with bidirectional link and broken reference checking

**Complexity**: Medium

**Tasks**:
- [x] Create Block 4: Cross-Reference Validation (file: .claude/commands/lean-update.md)
- [x] Implement bidirectional link verification (A→B implies B→A)
- [x] Check for broken file references in markdown links
- [x] Validate section structure per document
- [x] Generate validation report
- [x] Add --verify mode for validation-only runs
- [x] Log validation failures with error-handling.sh
- [x] Add validation results to console summary

**Testing**:
```bash
# Test bidirectional link validation
# Create TODO.md with link to SORRY_REGISTRY.md
# But SORRY_REGISTRY.md missing link to TODO.md
/lean-update --verify
# Should error: bidirectional link missing

# Test broken reference detection
# Create CLAUDE.md with link to non-existent file
/lean-update --verify
# Should warn: broken reference detected

# Test section structure validation
# Remove required section from IMPLEMENTATION_STATUS.md
/lean-update --verify
# Should error: missing required section

# Test verify-only mode
/lean-update --verify
# Should not modify any files
# Should only report validation status
```

**Expected Duration**: 4-6 hours

---

### Phase 8: Optional Build Verification [COMPLETE]
dependencies: [7]

**Objective**: Implement Block 5 with lake build/test integration

**Complexity**: Low

**Tasks**:
- [x] Create Block 5: Optional Build Verification (file: .claude/commands/lean-update.md)
- [x] Add --with-build flag support
- [x] Run lake build if flag present
- [x] Run lake test if flag present
- [x] Capture build/test output
- [x] Report build/test status in summary
- [x] Add timeout for long-running builds
- [x] Log build failures with error-handling.sh

**Testing**:
```bash
# Test build verification skipped by default
/lean-update
# Verify lake build NOT invoked

# Test build verification with flag
/lean-update --with-build
# Verify lake build invoked
# Verify lake test invoked
# Verify results in summary

# Test build failure handling
# Introduce syntax error in Lean file
/lean-update --with-build
# Should complete update despite build failure
# Should report build failure in summary

# Test build timeout
# Simulate very long build
/lean-update --with-build
# Should timeout after threshold
# Should log timeout error
```

**Expected Duration**: 2-4 hours

---

### Phase 9: Standardized Completion Output [COMPLETE]
dependencies: [8]

**Objective**: Implement Block 6 with 4-section console summary

**Complexity**: Low

**Tasks**:
- [x] Create Block 6: Standardized Completion Output (file: .claude/commands/lean-update.md)
- [x] Generate 4-section summary (Summary, Phases, Artifacts, Next Steps)
- [x] List all updated documents with paths
- [x] Report sorry count changes per module
- [x] Report module completion percentage changes
- [x] Include build/test results (if --with-build)
- [x] Provide recovery commands (git restore)
- [x] Use print_artifact_summary from summary-formatting.sh
- [x] Emit completion signal: LEAN_UPDATE_COMPLETE

**Summary Format**:
```
=== /lean-update Command Summary ===

Summary:
Updated 6 maintenance documents. Sorry count decreased from 45 to 38 (-7).
Module completion: Metalogic 60% → 65%, Theorems 50% → 55%.
Build verification: PASSED (lake build: success, lake test: 48/48 passed).

Artifacts:
  📄 TODO.md: /path/to/TODO.md
  📄 SORRY_REGISTRY.md: /path/to/SORRY_REGISTRY.md
  📄 MAINTENANCE.md: /path/to/MAINTENANCE.md
  📄 IMPLEMENTATION_STATUS.md: /path/to/IMPLEMENTATION_STATUS.md
  📄 KNOWN_LIMITATIONS.md: /path/to/KNOWN_LIMITATIONS.md
  📄 CLAUDE.md: /path/to/CLAUDE.md
  📝 Git Snapshot: abc123def

Next Steps:
  • Review changes: git diff abc123def
  • Run tests: lake test
  • Recovery (if needed): git restore --source=abc123def -- Documentation/
```

**Testing**:
```bash
# Test summary output
/lean-update
# Verify 4-section format
# Verify all 6 files listed
# Verify sorry count changes reported
# Verify completion signal emitted

# Test summary with build results
/lean-update --with-build
# Verify build/test results in summary

# Test summary for dry-run
/lean-update --dry-run
# Verify preview summary (no actual changes)
```

**Expected Duration**: 2-3 hours

---

### Phase 10: Documentation and Testing [COMPLETE]
dependencies: [9]

**Objective**: Create command guide documentation and comprehensive integration tests

**Complexity**: Medium

**Tasks**:
- [x] Create command guide at .claude/docs/guides/commands/lean-update-command-guide.md
- [x] Document all four modes (scan, verify, build, dry-run)
- [x] Document preservation policies per document
- [x] Document sorry detection methodology
- [x] Document cross-reference validation rules
- [x] Create integration test suite at .claude/tests/commands/test_lean_update_multi_file.sh
- [x] Test multi-file update workflow
- [x] Test preservation verification
- [x] Test cross-reference validation
- [x] Test build verification (if applicable)
- [x] Test error recovery (git restore)
- [x] Add command to Command Reference documentation

**Documentation Sections**:
1. Overview and Purpose
2. Modes and Options
3. Lean Project Detection
4. Sorry Detection Methodology
5. Multi-File Update Workflow
6. Preservation Policies
7. Cross-Reference Validation
8. Build Verification
9. Error Recovery
10. Troubleshooting
11. Examples

**Testing**:
```bash
# Run integration test suite
bash .claude/tests/commands/test_lean_update_multi_file.sh

# Test scenarios:
# 1. Full update workflow (all 6 files)
# 2. Preservation verification (Backlog, Saved sections)
# 3. Cross-reference validation (bidirectional links)
# 4. Build verification (--with-build flag)
# 5. Dry-run mode (no modifications)
# 6. Error recovery (git restore from snapshot)

# Verify documentation completeness
test -f .claude/docs/guides/commands/lean-update-command-guide.md
grep -q "Sorry Detection Methodology" .claude/docs/guides/commands/lean-update-command-guide.md
grep -q "Preservation Policies" .claude/docs/guides/commands/lean-update-command-guide.md

# Verify command reference updated
grep -q "/lean-update" .claude/docs/reference/standards/command-reference.md
```

**Expected Duration**: 6-8 hours

---

## Testing Strategy

### Unit Testing
Each phase includes inline test commands to verify correctness:
- Phase 1: Command creation, argument parsing, project detection
- Phase 2: Sorry detection, module counting, completion calculation
- Phase 3: Path pre-calculation, state persistence
- Phase 4: Agent creation, JSON report generation
- Phase 5: Analysis report verification, JSON validation
- Phase 6: Multi-file updates, preservation verification, git snapshot
- Phase 7: Cross-reference validation, broken link detection
- Phase 8: Build verification, timeout handling
- Phase 9: Console summary format, completion signal
- Phase 10: Documentation completeness, integration tests

### Integration Testing
After Phase 10 completion:
```bash
# Full workflow test
cd /path/to/lean/project
/lean-update

# Verify all updates:
# - TODO.md updated with current tasks
# - SORRY_REGISTRY.md reflects current sorries
# - IMPLEMENTATION_STATUS.md shows updated completion %
# - KNOWN_LIMITATIONS.md gaps synchronized
# - MAINTENANCE.md workflow current
# - CLAUDE.md references updated

# Verify preservation:
# - Backlog section unchanged in TODO.md
# - Saved section unchanged in TODO.md
# - Resolved section unchanged in SORRY_REGISTRY.md
# - Manual annotations preserved in IMPLEMENTATION_STATUS.md

# Verify cross-references:
# - All bidirectional links valid
# - No broken file references
# - Section structure intact

# Verify git snapshot:
# - Snapshot commit created before updates
# - Recovery possible via git restore

# Performance test
time /lean-update
# Should complete in < 60 seconds for typical Lean project
```

### Quality Metrics
- Command execution time: < 60 seconds for typical Lean project
- Sorry count accuracy: 100% match between grep and SORRY_REGISTRY.md
- Preservation verification: 100% success rate
- Cross-reference validation: 0 broken links
- Build verification: 100% pass rate (if project builds)
- Documentation completeness: All 11 sections present in guide
- Test coverage: 10+ integration test scenarios

## Documentation Requirements

### Files to Create
1. **.claude/commands/lean-update.md**
   - Command frontmatter with dependencies
   - Mode descriptions (scan, verify, build, dry-run)
   - Six execution blocks (Setup, Pre-Calculate, Analyze, Verify, Update, Complete)
   - Error handling integration
   - State persistence across blocks
   - Standardized completion output

2. **.claude/agents/lean-maintenance-analyzer.md**
   - Agent frontmatter with tool permissions
   - Lean source tree scanning logic
   - Sorry placeholder analysis
   - JSON analysis report generation
   - Preservation policy respect
   - Contract requirements
   - Return signal specification

3. **.claude/docs/guides/commands/lean-update-command-guide.md**
   - Complete command guide with examples
   - Mode documentation
   - Sorry detection methodology
   - Multi-file update workflow
   - Preservation policies
   - Cross-reference validation
   - Error recovery procedures
   - Troubleshooting section

4. **.claude/tests/commands/test_lean_update_multi_file.sh**
   - Integration test suite
   - Multi-file update tests
   - Preservation verification tests
   - Cross-reference validation tests
   - Build verification tests
   - Error recovery tests

### Files to Update
1. **.claude/docs/reference/standards/command-reference.md**
   - Add /lean-update to command catalog
   - Document all options and modes
   - Link to command guide

## Dependencies

### External Dependencies
- Lean 4 project with lakefile.toml (target project)
- Git repository (for snapshot and history queries)
- jq (for JSON parsing in verification)
- grep, sed, awk (for sorry counting and preservation)

### Internal Prerequisites
- error-handling.sh library (Tier 1)
- state-persistence.sh library (Tier 1)
- unified-location-detection.sh library (Tier 1)
- summary-formatting.sh library (Tier 2)
- /todo command patterns (hard barrier, preservation, agent delegation)
- ProofChecker TODO cleanup plan (reference implementation)

### Documentation Standards
From CLAUDE.md:
- Markdown format for all documentation
- Three-tier library sourcing pattern
- Hard barrier pattern for agent delegation
- Preservation pattern for manually-curated sections
- State persistence across bash blocks
- Standardized 4-section console summary
- Error logging integration

## Risk Assessment

### Medium Risk
- Multi-file coordination complexity (6+ files updated atomically)
- Preservation logic must handle multiple document formats
- Cross-reference validation requires graph traversal
- Build verification may timeout on large projects

### Mitigation Strategies
- **Atomic Updates**: Use git snapshot before any modifications
- **Preservation Verification**: Extract and verify sections after updates
- **Cross-Reference Testing**: Comprehensive test suite for link validation
- **Build Timeout**: Set 5-minute timeout for lake build/test
- **Dry-Run Mode**: Allow preview of all changes before execution
- **Recovery Documentation**: Clear git restore instructions in guide

### Success Validation
- All 10 phases completed with passing tests
- Integration test suite passes (10+ scenarios)
- Documentation complete (command guide, agent docs, tests)
- Command successfully updates ProofChecker maintenance documents
- Performance meets targets (< 60 seconds execution time)
- Zero data loss (preservation verification 100% success rate)

## Notes

**Implementation Approach**: This plan uses the proven hard barrier pattern from /todo, extending it to support multi-file updates with preservation verification. Each document maintains its own preservation policies, and the atomic update strategy ensures recovery is always possible via git snapshot.

**Completion Criteria**: Plan complete when all phases verified, integration tests pass, documentation published, and command successfully maintains ProofChecker project documentation ecosystem.

**Time Savings**: After implementation, Lean project maintainers save 30-60 minutes per maintenance cycle by automating sorry counting, module completion calculation, and cross-reference validation (reducing manual effort from 45-75 minutes to 15 minutes).

**Portability Design**: The command is designed to be portable across any Lean project with a .claude/ directory structure. Project detection via lakefile.toml ensures the command adapts to different Lean project layouts, while the document discovery mechanism locates maintenance files regardless of their specific organization within the project.

---

**Last Updated**: 2025-12-05
