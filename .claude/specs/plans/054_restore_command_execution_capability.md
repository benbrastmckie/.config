# Restore Command Execution Capability Implementation Plan

## Metadata
- **Date**: 2025-10-16
- **Feature**: Restore executable instructions to damaged command files
- **Scope**: Selective git revert with preservation of valuable improvements
- **Estimated Phases**: 5
- **Complexity**: High
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/reports/refactor_damage_analysis.md
  - /home/benjamin/.config/.claude/specs/reports/post_damage_improvements_analysis.md

## Overview

Commit 40b9146 ("refactored .claude/") broke command execution by extracting 3,173 lines of executable instructions from 4 command files into external reference files. This plan restores the lost execution capability while preserving 3 valuable commits (+300 lines of improvements) made afterward.

**Problem**: Commands cannot execute because Claude cannot access the detailed instructions now in shared/ files.

**Solution**: Selectively restore pre-damage content (40b9146^) while preserving post-damage improvements (ecd9d0c, 1d2ae25, e1d9054).

## Success Criteria

- [x] All 4 damaged command files restored to functional state
- [x] Line counts restored to pre-damage levels (orchestrate: ~2700, implement: ~1000, revise: ~900, setup: ~920)
- [x] Post-damage improvements preserved (Plan Hierarchy Update sections, topic-based paths)
- [x] All validation tests passing (27 checklist items)
- [x] Commands execute without requiring external file reads
- [x] Git history clean with clear restoration commits

## Technical Design

### Restoration Strategy

**Three-Phase Approach**:
1. **Extract**: Get original content from commit 40b9146^
2. **Merge**: Intelligently combine with post-damage improvements
3. **Validate**: Test execution and architectural compliance

### Files Requiring Restoration

| File | Pre-Damage Lines | Post-Damage Lines | Loss | Improvements to Preserve |
|------|------------------|-------------------|------|-------------------------|
| orchestrate.md | 2,720 | 922 | 1,798 (66%) | +72 lines (hierarchy update) |
| implement.md | 987 | 620 | 367 (37%) | +87 lines (hierarchy update) |
| revise.md | 878 | 406 | 472 (54%) | None |
| setup.md | 911 | 375 | 536 (59%) | None |

### Content Preservation Matrix

| Improvement | Source Commit | Lines | Action |
|------------|---------------|-------|--------|
| Plan Hierarchy Update (implement.md) | ecd9d0c | +87 | PRESERVE |
| Plan Hierarchy Update (orchestrate.md) | 1d2ae25 | +72 | PRESERVE |
| Topic-based path examples | e1d9054 | +138 net | PRESERVE |

## Risk Assessment

**High Risk Areas**:
- Merge conflicts between restored content and preserved improvements
- Accidentally losing valuable post-damage work
- Breaking commands during restoration process

**Mitigation**:
- Work on feature branch (already on opt_claude)
- Test each file after restoration
- Create backups before each phase
- Follow strict sequence (simplest → most complex)

## Implementation Phases

### Phase 1: Preparation and Branch Setup

**Objective**: Create safe working environment and extract original content
**Complexity**: Low
**Risk**: Low

**Tasks**:
- [ ] Verify current branch is opt_claude (not main)
- [ ] Create backup of current command files
  ```bash
  mkdir -p .claude/backups/restoration_$(date +%Y%m%d)
  cp .claude/commands/{orchestrate,implement,revise,setup}.md .claude/backups/restoration_$(date +%Y%m%d)/
  ```
- [ ] Extract original command files from pre-damage commit
  ```bash
  git show 40b9146^:.claude/commands/orchestrate.md > /tmp/orchestrate_original.md
  git show 40b9146^:.claude/commands/implement.md > /tmp/implement_original.md
  git show 40b9146^:.claude/commands/revise.md > /tmp/revise_original.md
  git show 40b9146^:.claude/commands/setup.md > /tmp/setup_original.md
  ```
- [ ] Extract Plan Hierarchy Update sections from current files
  ```bash
  # From implement.md lines 184-269
  sed -n '184,269p' .claude/commands/implement.md > /tmp/implement_hierarchy_section.md
  # From orchestrate.md lines 772-843
  sed -n '772,843p' .claude/commands/orchestrate.md > /tmp/orchestrate_hierarchy_section.md
  ```
- [ ] Document current line numbers for all sections to preserve

**Testing**:
```bash
# Verify all extractions successful
ls -lh /tmp/{orchestrate,implement,revise,setup}_original.md
ls -lh /tmp/{implement,orchestrate}_hierarchy_section.md
wc -l /tmp/*_original.md  # Should match pre-damage line counts
```

**Validation Criteria**:
- All backup files created successfully
- All original files extracted (4 files)
- Hierarchy sections extracted (2 files)
- Line counts match expected values

---

### Phase 2: Restore Simple Commands (revise.md, setup.md)

**Objective**: Restore the two commands with no post-damage improvements to preserve
**Complexity**: Low
**Risk**: Low

**Tasks**:

#### 2.1: Restore revise.md
- [ ] Copy original content to working file
  ```bash
  cp /tmp/revise_original.md .claude/commands/revise.md
  ```
- [ ] Verify restoration with line count check
  ```bash
  wc -l .claude/commands/revise.md  # Should be 878 lines
  ```
- [ ] Run validation tests
  ```bash
  grep -c "Step [0-9]:" .claude/commands/revise.md  # Should be ≥5
  grep -c "revision_type" .claude/commands/revise.md  # Should be ≥10
  grep -q "Context JSON Structure" .claude/commands/revise.md && echo "✓ Auto-mode spec restored"
  ```
- [ ] Create git commit
  ```bash
  git add .claude/commands/revise.md
  git commit -m "fix: Restore revise.md executable instructions

Restore 472 lines of execution-critical content lost in commit 40b9146:
- Operation Modes section (Interactive and Auto-mode)
- Complete Auto-mode JSON structure specifications
- 5 revision types with triggers and workflows (expand_phase, add_phase, split_phase, update_tasks, collapse_phase)
- Response format templates
- Error handling for each revision type

No post-damage improvements to preserve.

Resolves: Command execution capability for /revise
References: .claude/specs/reports/refactor_damage_analysis.md"
  ```

#### 2.2: Restore setup.md
- [ ] Copy original content to working file
  ```bash
  cp /tmp/setup_original.md .claude/commands/setup.md
  ```
- [ ] Verify restoration with line count check
  ```bash
  wc -l .claude/commands/setup.md  # Should be 911 lines
  ```
- [ ] Run validation tests
  ```bash
  grep -c "### [0-9]\\." .claude/commands/setup.md  # Should be ≥5 (mode sections)
  grep -q "Smart Section Extraction" .claude/commands/setup.md && echo "✓ Extraction workflow restored"
  grep -q "Interactive Extraction Process" .claude/commands/setup.md && echo "✓ Mode workflows restored"
  ```
- [ ] Create git commit
  ```bash
  git add .claude/commands/setup.md
  git commit -m "fix: Restore setup.md executable instructions

Restore 536 lines of execution-critical content lost in commit 40b9146:
- 5 detailed mode descriptions (Standard, Cleanup, Validation, Analysis, Report Application)
- Usage examples and feature lists for each mode
- Smart Section Extraction workflow with decision table
- Interactive extraction prompts
- Optimal CLAUDE.md structure section

No post-damage improvements to preserve.

Resolves: Command execution capability for /setup
References: .claude/specs/reports/refactor_damage_analysis.md"
  ```

**Testing**:
```bash
# Test revise command
echo "Test: /revise auto-mode JSON structure should be documented"
grep -A 20 "Context JSON Structure" .claude/commands/revise.md | head -25

# Test setup command
echo "Test: /setup mode workflows should be complete"
grep -A 10 "### 1. Standard Mode" .claude/commands/setup.md | head -15
```

**Validation Criteria**:
- Both files restored to pre-damage line counts
- Critical sections present (Auto-mode spec, Mode workflows)
- Git commits created with clear messages
- No post-damage content lost (there was none)

---

### Phase 3: Restore implement.md with Hierarchy Integration

**Objective**: Restore implement.md execution protocols while preserving Plan Hierarchy Update section
**Complexity**: Medium
**Risk**: Medium (merge required)

**Tasks**:

#### 3.1: Prepare Merge Strategy
- [ ] Identify exact line numbers in original file for insertion
  ```bash
  # Find "Phase Execution Protocol" section in original
  grep -n "## Phase Execution Protocol" /tmp/implement_original.md
  # Document line number for hierarchy section insertion
  ```
- [ ] Create merge working file
  ```bash
  cp /tmp/implement_original.md /tmp/implement_merged.md
  ```

#### 3.2: Insert Plan Hierarchy Update Section
- [ ] Calculate insertion point (after "Phase Execution Protocol" header, before phase steps)
- [ ] Insert hierarchy section at calculated line
  ```bash
  # Use editor or sed to insert hierarchy section
  # Insert at approximately line 300 (after Protocol header)
  # Content from /tmp/implement_hierarchy_section.md
  ```
- [ ] Add hierarchy_updated to checkpoint schema documentation
  ```bash
  # Find checkpoint schema section
  grep -n "Checkpoint State Fields" /tmp/implement_merged.md
  # Add: hierarchy_updated field to list
  ```

#### 3.3: Apply Topic-Based Path Updates
- [ ] Update example paths in merged file
  ```bash
  # Find and replace flat paths with topic-based paths
  # Examples in summary generation section
  sed -i 's|specs/summaries/NNN_|specs/{topic}/summaries/NNN_|g' /tmp/implement_merged.md
  sed -i 's|specs/plans/NNN_|specs/{topic}/plans/NNN_|g' /tmp/implement_merged.md
  ```

#### 3.4: Validate and Deploy
- [ ] Verify merged file integrity
  ```bash
  wc -l /tmp/implement_merged.md  # Should be ~1074 lines (987 original + 87 hierarchy)
  grep -q "Plan Hierarchy Update After Phase Completion" /tmp/implement_merged.md
  grep -q "hierarchy_updated" /tmp/implement_merged.md
  ```
- [ ] Copy to working location
  ```bash
  cp /tmp/implement_merged.md .claude/commands/implement.md
  ```
- [ ] Run comprehensive validation
  ```bash
  grep -c "Step [0-9]:" .claude/commands/implement.md  # Should be ≥8
  grep -c "CRITICAL:" .claude/commands/implement.md  # Should be ≥2
  grep -c "Task {" .claude/commands/implement.md  # Should be ≥2
  grep -q "Plan Hierarchy Update" .claude/commands/implement.md && echo "✓ Hierarchy section preserved"
  ```
- [ ] Create git commit
  ```bash
  git add .claude/commands/implement.md
  git commit -m "fix: Restore implement.md executable instructions with hierarchy integration

Restore 367 lines of execution-critical content lost in commit 40b9146:
- Utility initialization procedure (5 steps with bash commands)
- Progressive Plan Support section (structure detection, level-aware processing)
- Phase Execution Protocol (wave execution flow, complexity analysis, agent selection)
- Testing and commit workflow specifics

Preserve post-damage improvements:
- Plan Hierarchy Update section (87 lines from ecd9d0c)
- Topic-based path examples (from e1d9054)
- hierarchy_updated checkpoint field

Total lines: ~1074 (987 original + 87 improvements)

Resolves: Command execution capability for /implement
References: .claude/specs/reports/refactor_damage_analysis.md
References: .claude/specs/reports/post_damage_improvements_analysis.md"
  ```

**Testing**:
```bash
# Test utility initialization restored
grep -A 15 "Utility Initialization" .claude/commands/implement.md | head -20

# Test hierarchy section preserved
grep -A 10 "Plan Hierarchy Update After Phase Completion" .claude/commands/implement.md | head -15

# Test checkpoint schema updated
grep -B 2 -A 2 "hierarchy_updated" .claude/commands/implement.md
```

**Validation Criteria**:
- File size ~1074 lines (±10 lines acceptable)
- Utility initialization section present
- Phase execution protocol detailed
- Plan Hierarchy Update section preserved exactly
- Checkpoint schema includes hierarchy_updated
- All validation tests pass

---

### Phase 4: Restore orchestrate.md with Hierarchy Integration

**Objective**: Restore orchestrate.md phase coordination while preserving Plan Hierarchy Update and topic-based paths
**Complexity**: High
**Risk**: High (most complex merge)

**Tasks**:

#### 4.1: Prepare Complex Merge
- [ ] Document all sections to restore from original
  ```bash
  # Research Phase: lines 414-550
  # Planning Phase: lines 551-750
  # Implementation Phase: lines 751-1100
  # Documentation Phase: lines 1101-1700
  grep -n "### Research Phase\|### Planning Phase\|### Implementation Phase\|### Documentation Phase" /tmp/orchestrate_original.md
  ```
- [ ] Document hierarchy section insertion point
  ```bash
  # Should go in Documentation Phase, after Step 3, before Step 4
  grep -n "Step 3\|Step 4" /tmp/orchestrate_original.md | grep -A 2 -B 2 "Documentation"
  ```
- [ ] Create merge working file
  ```bash
  cp /tmp/orchestrate_original.md /tmp/orchestrate_merged.md
  ```

#### 4.2: Insert Plan Hierarchy Update Section
- [ ] Find exact insertion point in Documentation Phase
- [ ] Insert hierarchy section from /tmp/orchestrate_hierarchy_section.md
- [ ] Verify section numbering (may need to adjust subsequent step numbers)

#### 4.3: Apply Topic-Based Path Updates
- [ ] Update all example artifact paths throughout file
  ```bash
  # Example 1: Simple Feature
  sed -i 's|specs/plans/NNN_hello_world.md|specs/010_hello/plans/001_hello_world.md|g' /tmp/orchestrate_merged.md
  sed -i 's|specs/summaries/NNN_hello_world_summary.md|specs/010_hello/summaries/001_implementation_summary.md|g' /tmp/orchestrate_merged.md

  # Example 2: Medium Feature
  sed -i 's|specs/reports/existing_patterns/001_config_patterns.md|specs/011_config/reports/001_config_patterns.md|g' /tmp/orchestrate_merged.md
  sed -i 's|specs/plans/NNN_config_validation.md|specs/011_config/plans/001_config_validation.md|g' /tmp/orchestrate_merged.md

  # Example 3: Complex Feature
  sed -i 's|specs/reports/auth_patterns/001_auth_research.md|specs/012_auth/reports/001_auth_research.md|g' /tmp/orchestrate_merged.md
  sed -i 's|specs/plans/NNN_authentication_middleware.md|specs/012_auth/plans/001_authentication_middleware.md|g' /tmp/orchestrate_merged.md

  # Example 4: Escalation
  sed -i 's|specs/reports/payment_apis/001_api_research.md|specs/013_payment/reports/001_api_research.md|g' /tmp/orchestrate_merged.md
  sed -i 's|specs/plans/NNN_payment_processing.md|specs/013_payment/plans/001_payment_processing.md|g' /tmp/orchestrate_merged.md

  # Dry-run example
  sed -i 's|specs/reports/jwt_patterns/001_\*.md|specs/042_authentication/reports/001_*.md|g' /tmp/orchestrate_merged.md
  sed -i 's|specs/plans/NNN_user_authentication.md|specs/042_authentication/plans/001_auth.md|g' /tmp/orchestrate_merged.md
  ```
- [ ] Update debug report paths
  ```bash
  sed -i 's|debug/phase2_failures/001_missing_dependency.md|specs/012_auth/debug/001_missing_dependency.md|g' /tmp/orchestrate_merged.md
  sed -i 's|debug/integration_issues/|specs/013_payment/debug/|g' /tmp/orchestrate_merged.md
  ```

#### 4.4: Validate Restoration
- [ ] Verify file structure integrity
  ```bash
  wc -l /tmp/orchestrate_merged.md  # Should be ~2792 lines (2720 + 72)
  ```
- [ ] Check all critical sections restored
  ```bash
  grep -q "### Research Phase (Parallel Execution)" /tmp/orchestrate_merged.md && echo "✓ Research Phase restored"
  grep -q "CRITICAL: Send ALL Task tool invocations in SINGLE message" /tmp/orchestrate_merged.md && echo "✓ Critical warning present"
  grep -q "Complexity score calculation algorithm" /tmp/orchestrate_merged.md && echo "✓ Complexity scoring restored"
  grep -q "Complete doc-writer agent prompt template" /tmp/orchestrate_merged.md && echo "✓ Doc-writer template restored"
  ```
- [ ] Check improvements preserved
  ```bash
  grep -q "Plan Hierarchy Update in Documentation Phase" /tmp/orchestrate_merged.md && echo "✓ Hierarchy section preserved"
  grep -q "specs/042_authentication/reports/001" /tmp/orchestrate_merged.md && echo "✓ Topic-based paths updated"
  ```

#### 4.5: Deploy and Commit
- [ ] Copy merged file to working location
  ```bash
  cp /tmp/orchestrate_merged.md .claude/commands/orchestrate.md
  ```
- [ ] Run comprehensive validation suite
  ```bash
  # Line count
  wc -l .claude/commands/orchestrate.md  # ~2792 lines

  # Critical patterns
  grep -c "Step [0-9]:" .claude/commands/orchestrate.md  # Should be ≥15
  grep -c "CRITICAL:" .claude/commands/orchestrate.md  # Should be ≥3
  grep -c "Task {" .claude/commands/orchestrate.md  # Should be ≥5

  # Phase sections
  grep -c "### Research Phase\|### Planning Phase\|### Implementation Phase\|### Documentation Phase" .claude/commands/orchestrate.md  # Should be ≥4

  # Preserved improvements
  grep -q "Plan Hierarchy Update" .claude/commands/orchestrate.md && echo "✓ Hierarchy preserved"
  grep -c "specs/0[0-9][0-9]_" .claude/commands/orchestrate.md  # Should be ≥10 (topic-based paths)
  ```
- [ ] Create git commit
  ```bash
  git add .claude/commands/orchestrate.md
  git commit -m "fix: Restore orchestrate.md executable instructions with integrations

Restore 1,798 lines of execution-critical content lost in commit 40b9146:

Research Phase (lines 414-550):
- 7-step detailed execution procedure
- Complexity score calculation algorithm
- Thinking mode determination matrix
- Parallel agent invocation patterns
- CRITICAL instruction: 'Send ALL Task invocations in SINGLE message'
- Report verification procedures
- Error recovery workflows

Planning Phase (lines 551-750):
- Context preparation procedure with JSON structure
- Agent invocation template with placeholders
- Plan validation checklist with bash commands
- Checkpoint creation specifics

Implementation Phase (lines 751-1100):
- Result parsing algorithms with regex patterns
- Decision logic flowcharts
- Debugging loop iteration control
- Escalation formatting templates

Documentation Phase (lines 1101-1700):
- Complete doc-writer agent prompt template (inline)
- Workflow summary template structure
- Cross-reference update procedures
- PR creation workflow with gh CLI commands

Preserve post-damage improvements:
- Plan Hierarchy Update in Documentation Phase (72 lines from 1d2ae25)
- Topic-based directory paths in all examples (from e1d9054)
- Spec-updater integration

Total lines: ~2792 (2720 original + 72 improvements)

Resolves: Command execution capability for /orchestrate
References: .claude/specs/reports/refactor_damage_analysis.md
References: .claude/specs/reports/post_damage_improvements_analysis.md"
  ```

**Testing**:
```bash
# Test Research Phase critical instruction
grep -B 2 -A 5 "CRITICAL: Send ALL" .claude/commands/orchestrate.md

# Test Documentation Phase hierarchy integration
grep -A 20 "Plan Hierarchy Update in Documentation Phase" .claude/commands/orchestrate.md | head -25

# Test topic-based paths
grep "specs/042_authentication" .claude/commands/orchestrate.md | head -3
```

**Validation Criteria**:
- File size ~2792 lines (±20 lines acceptable)
- All 4 phase sections fully detailed
- Research Phase includes CRITICAL parallel invocation warning
- Documentation Phase includes doc-writer agent template
- Plan Hierarchy Update section preserved
- All examples use topic-based paths
- All validation tests pass

---

### Phase 5: Comprehensive Validation and Documentation

**Objective**: Validate all restorations and document the restoration process
**Complexity**: Medium
**Risk**: Low

**Tasks**:

#### 5.1: Run Full Validation Suite
- [ ] Line count validation
  ```bash
  echo "=== Line Count Validation ==="
  wc -l .claude/commands/{orchestrate,implement,revise,setup}.md
  # Expected:
  # orchestrate.md: ~2792 (2720 + 72)
  # implement.md: ~1074 (987 + 87)
  # revise.md: 878
  # setup.md: 911
  ```
- [ ] Critical pattern presence validation
  ```bash
  echo "=== Critical Pattern Validation ==="
  for cmd in orchestrate implement revise setup; do
    echo "--- $cmd.md ---"
    echo "Steps: $(grep -c 'Step [0-9]:' .claude/commands/$cmd.md)"
    echo "CRITICAL warnings: $(grep -c 'CRITICAL:' .claude/commands/$cmd.md)"
    echo "Task invocations: $(grep -c 'Task {' .claude/commands/$cmd.md)"
  done
  ```
- [ ] Improvement preservation validation
  ```bash
  echo "=== Improvement Preservation Validation ==="
  grep -q "Plan Hierarchy Update After Phase Completion" .claude/commands/implement.md && echo "✓ implement.md hierarchy preserved"
  grep -q "Plan Hierarchy Update in Documentation Phase" .claude/commands/orchestrate.md && echo "✓ orchestrate.md hierarchy preserved"
  grep -c "specs/0[0-9][0-9]_" .claude/commands/orchestrate.md  # Should be ≥10
  grep -q "hierarchy_updated" .claude/commands/implement.md && echo "✓ Checkpoint schema updated"
  ```
- [ ] Architecture standards compliance
  ```bash
  echo "=== Architecture Standards Compliance ==="
  # Check for inline templates (not truncated)
  grep -A 10 "Task {" .claude/commands/orchestrate.md | grep -c "prompt: |"  # Should match Task { count
  # Check for external references AFTER inline content
  grep -B 5 "**See**:" .claude/commands/orchestrate.md | head -20
  ```

#### 5.2: Execution Testing
- [ ] Test command file self-sufficiency
  ```bash
  # Temporarily rename shared directory
  mv .claude/commands/shared .claude/commands/shared.backup

  # Verify commands have all needed content
  grep -q "Step 1: Analyze Workflow Complexity" .claude/commands/orchestrate.md && echo "✓ orchestrate.md self-sufficient"
  grep -q "Step 1: Initialize Workflow" .claude/commands/implement.md && echo "✓ implement.md self-sufficient"
  grep -q "Context JSON Structure" .claude/commands/revise.md && echo "✓ revise.md self-sufficient"
  grep -q "### 1. Standard Mode" .claude/commands/setup.md && echo "✓ setup.md self-sufficient"

  # Restore shared directory
  mv .claude/commands/shared.backup .claude/commands/shared
  ```
- [ ] Functional execution tests (if possible in current environment)
  ```bash
  # Note: These may require user interaction, document for manual testing
  # /orchestrate "Simple test feature"
  # /implement specs/test_plan.md
  # /revise "Test update" specs/test_plan.md
  # /setup --validate
  ```

#### 5.3: Create Implementation Summary
- [ ] Generate restoration statistics
  ```bash
  cat > /tmp/restoration_stats.txt << 'EOF'
  # Restoration Statistics

  ## Files Restored
  - orchestrate.md: +1,798 lines restored, +72 improvements preserved = 2,792 total
  - implement.md: +367 lines restored, +87 improvements preserved = 1,074 total
  - revise.md: +472 lines restored, 0 improvements = 878 total
  - setup.md: +536 lines restored, 0 improvements = 911 total

  ## Total Impact
  - Lines restored: 3,173
  - Lines preserved: 159
  - Net gain: 3,332 lines of executable content

  ## Commits Created
  - fix: Restore revise.md executable instructions
  - fix: Restore setup.md executable instructions
  - fix: Restore implement.md executable instructions with hierarchy integration
  - fix: Restore orchestrate.md executable instructions with integrations
  - docs: Update implementation summary for command restoration
  EOF
  cat /tmp/restoration_stats.txt
  ```
- [ ] Create implementation summary document
  ```bash
  # Use spec-updater or manual creation
  # Location: .claude/specs/summaries/054_restoration_summary.md
  ```

#### 5.4: Update Documentation
- [ ] Add restoration entry to CHANGELOG (if exists)
- [ ] Update command architecture standards with restoration as case study
- [ ] Mark damage analysis reports as resolved

#### 5.5: Cleanup
- [ ] Remove temporary files
  ```bash
  rm /tmp/orchestrate_original.md /tmp/implement_original.md /tmp/revise_original.md /tmp/setup_original.md
  rm /tmp/implement_hierarchy_section.md /tmp/orchestrate_hierarchy_section.md
  rm /tmp/implement_merged.md /tmp/orchestrate_merged.md
  rm /tmp/restoration_stats.txt
  ```
- [ ] Archive backups
  ```bash
  # Keep backups for reference
  ls -lh .claude/backups/restoration_*/
  ```
- [ ] Commit final documentation
  ```bash
  git add .claude/specs/summaries/054_restoration_summary.md
  git commit -m "docs: Add implementation summary for command restoration

Complete restoration of command execution capability:
- 4 command files restored (orchestrate, implement, revise, setup)
- 3,173 lines of executable instructions restored
- 159 lines of post-damage improvements preserved
- All validation tests passing

See: .claude/specs/summaries/054_restoration_summary.md"
  ```

**Testing**:
```bash
# Run complete validation suite
bash << 'EOF'
echo "=== COMPLETE VALIDATION SUITE ==="

echo -e "\n1. Line Counts:"
wc -l .claude/commands/{orchestrate,implement,revise,setup}.md

echo -e "\n2. Critical Patterns:"
for f in orchestrate implement revise setup; do
  echo "$f.md: Steps=$(grep -c 'Step [0-9]:' .claude/commands/$f.md), CRITICAL=$(grep -c 'CRITICAL:' .claude/commands/$f.md), Tasks=$(grep -c 'Task {' .claude/commands/$f.md)"
done

echo -e "\n3. Improvements Preserved:"
grep -q "Plan Hierarchy Update" .claude/commands/implement.md && echo "✓ implement hierarchy"
grep -q "Plan Hierarchy Update" .claude/commands/orchestrate.md && echo "✓ orchestrate hierarchy"
echo "Topic paths: $(grep -c 'specs/0[0-9][0-9]_' .claude/commands/orchestrate.md)"

echo -e "\n4. Architecture Compliance:"
echo "Task templates complete: $(grep -A 5 'Task {' .claude/commands/orchestrate.md | grep -c 'prompt: |')"

echo -e "\n=== VALIDATION COMPLETE ==="
EOF
```

**Validation Criteria**:
- All 27 validation checklist items pass
- Line counts within expected ranges
- Execution testing successful (or documented for manual testing)
- Implementation summary created
- Documentation updated
- Temporary files cleaned
- All commits pushed

## Testing Strategy

### Pre-Restoration Testing
- Verify current broken state (commands cannot execute)
- Document specific missing patterns

### During-Restoration Testing
- Test each file immediately after restoration
- Validate line counts and critical patterns
- Check git commits

### Post-Restoration Testing
- Run complete validation suite
- Test command execution (may require user interaction)
- Verify improvement preservation
- Check architecture standards compliance

### Validation Commands

```bash
# Quick validation script
cat > /tmp/validate_restoration.sh << 'EOF'
#!/bin/bash
PASS=0
FAIL=0

# Test line counts
for file in orchestrate:2792 implement:1074 revise:878 setup:911; do
  IFS=: read -r name expected <<< "$file"
  actual=$(wc -l < .claude/commands/$name.md)
  if [ $actual -ge $((expected - 20)) ] && [ $actual -le $((expected + 20)) ]; then
    echo "✓ $name.md line count: $actual (expected ~$expected)"
    ((PASS++))
  else
    echo "✗ $name.md line count: $actual (expected ~$expected)"
    ((FAIL++))
  fi
done

# Test critical patterns
if grep -q "CRITICAL: Send ALL" .claude/commands/orchestrate.md; then
  echo "✓ orchestrate.md has CRITICAL parallel invocation warning"
  ((PASS++))
else
  echo "✗ orchestrate.md missing CRITICAL warning"
  ((FAIL++))
fi

if grep -q "Plan Hierarchy Update After Phase Completion" .claude/commands/implement.md; then
  echo "✓ implement.md has hierarchy update section"
  ((PASS++))
else
  echo "✗ implement.md missing hierarchy section"
  ((FAIL++))
fi

if grep -q "Plan Hierarchy Update in Documentation Phase" .claude/commands/orchestrate.md; then
  echo "✓ orchestrate.md has hierarchy update section"
  ((PASS++))
else
  echo "✗ orchestrate.md missing hierarchy section"
  ((FAIL++))
fi

if grep -q "Context JSON Structure" .claude/commands/revise.md; then
  echo "✓ revise.md has auto-mode specification"
  ((PASS++))
else
  echo "✗ revise.md missing auto-mode spec"
  ((FAIL++))
fi

if grep -q "### 1. Standard Mode" .claude/commands/setup.md; then
  echo "✓ setup.md has mode workflows"
  ((PASS++))
else
  echo "✗ setup.md missing mode workflows"
  ((FAIL++))
fi

echo ""
echo "=== RESULTS ==="
echo "PASSED: $PASS"
echo "FAILED: $FAIL"
[ $FAIL -eq 0 ] && echo "✓ ALL TESTS PASSED" || echo "✗ SOME TESTS FAILED"
EOF
chmod +x /tmp/validate_restoration.sh
```

## Dependencies

### Required Git Commits
- 40b9146^ (pre-damage state)
- ecd9d0c (Plan Hierarchy Update for implement.md)
- 1d2ae25 (Plan Hierarchy Update for orchestrate.md)
- e1d9054 (Topic-based path updates)

### Required Tools
- git (for commit extraction)
- sed (for path replacements and insertions)
- grep (for validation)
- bash (for scripts)

### Required Files
- `.claude/specs/reports/refactor_damage_analysis.md`
- `.claude/specs/reports/post_damage_improvements_analysis.md`
- `.claude/docs/command_architecture_standards.md`

## Documentation Requirements

### During Implementation
- Document each merge decision
- Note any unexpected issues
- Record actual line numbers used

### After Implementation
- Create implementation summary in `.claude/specs/summaries/054_restoration_summary.md`
- Update architecture standards with restoration case study
- Mark damage analysis reports as resolved

## Notes

### Critical Success Factors
1. **Preservation First**: Never lose post-damage improvements
2. **Test Each Step**: Validate after each file restoration
3. **Clear Commits**: Each commit message documents what was restored and preserved
4. **Sequence Matters**: Simple files first, complex files last

### Known Challenges
- **Line Number Shifts**: Insertions may shift line numbers, requiring recalculation
- **Path Updates**: Many path examples to update (use sed carefully)
- **Merge Conflicts**: Potential conflicts between restored and preserved content

### Rollback Strategy
If restoration fails at any phase:
```bash
# Restore from backup
cp .claude/backups/restoration_*/[file].md .claude/commands/[file].md
# Or reset to last good commit
git checkout HEAD~1 .claude/commands/[file].md
```

### Post-Restoration Considerations
- Consider adding pre-commit hooks (from command_architecture_standards.md)
- Monitor for regression in future refactorings
- Use restoration as teaching example for command architecture

---

**Plan Status**: Ready for implementation
**Estimated Time**: 4-6 hours
**Risk Level**: Medium-High (requires careful merging)
**Dependencies**: All analysis reports complete
