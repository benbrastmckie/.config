# Implementation Plan: Standards Alignment for Plan 080

## Metadata
- **Date**: 2025-10-21
- **Feature**: Align plan 080_orchestrate_enhancement.md and all subplan files with .claude/docs/ standards
- **Scope**: Update 8 plan files (1 main + 7 subplans) to achieve ≥90% imperative language ratio, add pattern cross-references, remove temporal markers, add verification checkpoints, and ensure execution enforcement compliance
- **Estimated Phases**: 6
- **Structure Level**: 0
- **Complexity Score**: 8.5/10 (High - 8 files, 10 alignment requirements, systematic validation)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Writing Standards**: /home/benjamin/.config/.claude/docs/concepts/writing-standards.md
- **Research Reports**: Command Architecture Standards, Pattern Documentation Standards, Plan 080 Structure Analysis, Writing and Documentation Standards
- **Plan Number**: 082

## Overview

This plan systematically aligns plan 080_orchestrate_enhancement.md and its 7 subplan files with established .claude/docs/ standards, addressing 10 critical alignment requirements identified through research analysis. The alignment ensures plan 080 serves as an exemplary reference for future plan development while maintaining technical accuracy and implementation feasibility.

### Current State

Plan 080 is a Level 1 expanded plan with 8 phases (0-7), all except Phase 2 expanded to separate files. The plan extensively references architectural patterns (20 occurrences) and CLAUDE.md sections (60 references) but exhibits several standards violations:

1. **Pattern References**: Pattern names mentioned without markdown links (20 occurrences)
2. **Language Weakness**: Weak imperative language ("should create" vs "MUST create") throughout
3. **Temporal Markers**: Historical commentary in Revision History section, temporal language in phase descriptions
4. **Missing Verification**: File operation tasks lack mandatory verification checkpoints
5. **Potential Duplication**: Phase 3 complexity documentation may duplicate CLAUDE.md adaptive_planning_config
6. **Incorrect References**: "progressive-planning.md" referenced but file doesn't exist (actual: adaptive-planning-guide.md)
7. **Testing Gaps**: Success criteria lack explicit testing validation checkboxes
8. **Behavioral Injection**: Pattern referenced but not consistently applied in all agent invocations
9. **Phase 0 Pattern**: Present but may lack complete path pre-calculation workflow
10. **Cross-Reference Completeness**: Pattern files may need updated [Used by:] tags

### Target State

All 8 plan files WILL conform to .claude/docs/ standards:

1. **Pattern Cross-References**: All pattern names converted to markdown links with format `[Pattern Name](.claude/docs/concepts/patterns/pattern-name.md)`
2. **Imperative Language**: ≥90% imperative ratio (MUST/WILL/SHALL replacing should/may/can)
3. **Present-Focused**: Zero temporal markers (New, Old, Updated, previously, recently, now supports)
4. **Verification Checkpoints**: Mandatory "VERIFICATION CHECKPOINT" blocks after all file creation operations with explicit `[ ! -f ]` checks
5. **No Duplication**: Phase 3 references CLAUDE.md adaptive_planning_config instead of duplicating content
6. **Correct References**: All file references point to existing files with accurate paths
7. **Testing Validation**: All success criteria include explicit test validation checkboxes
8. **Behavioral Injection**: All agent invocations use Task tool with explicit path injection
9. **Phase 0 Completeness**: Path pre-calculation workflow fully specified with all artifact paths
10. **Bidirectional Links**: Pattern files updated with [Used by: /orchestrate] tags

## Success Criteria

- [ ] All 8 plan files updated with imperative language (≥90% ratio verified)
- [ ] All 20+ pattern references converted to markdown links
- [ ] Zero temporal markers in all plan files (validated via grep)
- [ ] All file creation tasks include VERIFICATION CHECKPOINT blocks
- [ ] Phase 3 references CLAUDE.md adaptive_planning_config with no content duplication
- [ ] All file references corrected (progressive-planning.md → adaptive-planning-guide.md)
- [ ] All success criteria include test validation checkboxes
- [ ] All agent invocations specify Task tool with behavioral injection
- [ ] Phase 0 includes complete path pre-calculation workflow
- [ ] Pattern files updated with [Used by: /orchestrate] metadata tags
- [ ] Imperative language audit script executed with ≥90% pass rate
- [ ] Standards validation test suite passes (grep temporal markers, verify pattern links, check verification blocks)
- [ ] All 8 files committed with standardized commit message
- [ ] Cross-reference validation confirms bidirectional links working

## Technical Design

### Alignment Strategy

This plan uses a **systematic file-by-file approach** with consistent transformation patterns applied across all 8 files. Each alignment requirement maps to specific search-and-replace operations, ensuring reproducible and verifiable results.

### Transformation Patterns

#### Pattern 1: Convert Pattern References to Markdown Links

**Search Pattern**: `(Behavioral Injection|Forward Message|Metadata Extraction|Checkpoint Recovery|Parallel Execution|Hierarchical Supervision|Context Management|Verification and Fallback|Metadata-Only Passing|Recursive Supervision)( Pattern| pattern)?`

**Replace Pattern**: `[$1 Pattern](.claude/docs/concepts/patterns/KEBAB_CASE.md)`

**Kebab Case Mapping**:
- Behavioral Injection → behavioral-injection.md
- Forward Message → forward-message.md
- Metadata Extraction → metadata-extraction.md
- Checkpoint Recovery → checkpoint-recovery.md
- Parallel Execution → parallel-execution.md
- Hierarchical Supervision → hierarchical-supervision.md
- Context Management → context-management.md
- Verification and Fallback → verification-fallback.md

**Example**:
```markdown
# Before
This follows the behavioral injection pattern where agents receive paths.

# After
This follows the [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md) where agents receive paths.
```

#### Pattern 2: Replace Weak Language with Imperative

**Search-Replace Pairs**:
- `should create` → `MUST create`
- `should update` → `MUST update`
- `should verify` → `MUST verify`
- `should invoke` → `WILL invoke`
- `may include` → `WILL include`
- `can run` → `WILL run`
- `will need to` → `MUST`
- `consider adding` → `MUST add`
- `try to` → `WILL`
- `attempt to` → `WILL`

**Example**:
```markdown
# Before
The agent should create a report and may include cross-references.

# After
The agent MUST create a report and WILL include cross-references.
```

#### Pattern 3: Remove Temporal Markers

**Search Pattern**: `(New|Old|Updated|Deprecated|previously|recently|now supports|used to|no longer|migrated to|backward compatibility|breaking change)`

**Strategy**: Context-dependent removal:
- Revision History section: Remove entirely (present-focused documentation)
- Phase descriptions: Rewrite to present tense without temporal context
- Technical content: Replace with timeless present-focused descriptions

**Example**:
```markdown
# Before
## Revision History
### 2025-10-21 - Revision 2: Add Dedicated Testing Phase
**Changes**: Added Phase 6 (Testing)...

# After
[SECTION REMOVED - Present-focused documentation per writing-standards.md]
```

#### Pattern 4: Add Verification Checkpoints

**Template**:
```markdown
MANDATORY VERIFICATION CHECKPOINT:
```bash
if [ ! -f "{artifact_path}" ]; then
  echo "ERROR: Expected artifact not created at {artifact_path}"
  echo "FALLBACK: Agent failed to create file - command MUST create manually"
  # Create file with minimal template
fi
```
End verification. Proceed only if file exists.
```

**Insertion Points**: After every task involving:
- Agent file creation (reports, plans, summaries)
- Directory creation operations
- Configuration file generation
- Script file creation

**Example**:
```markdown
# Before
- [ ] Invoke research-synthesizer agent to create overview report
- [ ] Extract overview metadata

# After
- [ ] Invoke research-synthesizer agent to create overview report

MANDATORY VERIFICATION CHECKPOINT:
```bash
if [ ! -f "{artifact_paths.reports}/NNN_research_overview.md" ]; then
  echo "ERROR: Overview report not created by research-synthesizer agent"
  echo "FALLBACK: Creating minimal overview template"
  cat > "{artifact_paths.reports}/NNN_research_overview.md" <<'EOF'
# Research Overview
[Template created by fallback mechanism]
EOF
fi
```
End verification. Proceed only if file exists.

- [ ] Extract overview metadata
```

#### Pattern 5: Correct File References

**Search-Replace**:
- `progressive-planning.md` → `adaptive-planning-guide.md` (with verification of existence)
- Verify all pattern file references point to existing files in `.claude/docs/concepts/patterns/`
- Add relative path prefixes where missing

**Verification Script**:
```bash
# WILL execute after corrections to validate all links
grep -oP '\[.*?\]\(\K[^)]+' plan_file.md | while read -r path; do
  if [[ ! -f "$path" ]]; then
    echo "BROKEN LINK: $path"
  fi
done
```

#### Pattern 6: Add Testing Validation to Success Criteria

**Template**:
```markdown
- [ ] [Feature criterion]
- [ ] TESTING: [Specific test to validate criterion]
```

**Example**:
```markdown
# Before
- [ ] All research reports created in correct specs/NNN_topic/reports/ structure

# After
- [ ] All research reports created in correct specs/NNN_topic/reports/ structure
- [ ] TESTING: Execute artifact organization test suite - verify report paths match pattern specs/\d{3}_\w+/reports/
```

### Phase 0 Path Pre-Calculation Specification

The Phase 0 orchestrator pattern MUST include:

1. **Artifact Path Calculation Block** (before any agent invocations):
```yaml
# STEP 1 (REQUIRED BEFORE STEP 2): Calculate all artifact paths
ARTIFACT_PATHS:
  topic_path: "{project_root}/specs/{NNN_topic}/"
  reports: "{topic_path}/reports/"
  plans: "{topic_path}/plans/"
  summaries: "{topic_path}/summaries/"
  debug: "{topic_path}/debug/"
  scripts: "{topic_path}/scripts/"
  outputs: "{topic_path}/outputs/"
```

2. **Behavioral Injection Template** (passed to ALL subagents):
```yaml
# STEP 2 (REQUIRED BEFORE AGENT INVOCATION): Inject artifact context
AGENT_CONTEXT:
  topic_number: "{NNN}"
  topic_name: "{topic_name}"
  artifact_paths: {ARTIFACT_PATHS}
  instructions:
    - "MUST save all reports to {artifact_paths.reports}"
    - "MUST save all plans to {artifact_paths.plans}"
    - "MUST save debug artifacts to {artifact_paths.debug}"
```

3. **Verification After Agent Execution**:
```bash
# STEP 3 (REQUIRED AFTER AGENT COMPLETION): Verify artifact placement
if [ ! -f "{expected_artifact_path}" ]; then
  echo "ERROR: Agent did not create artifact at expected path"
  echo "FALLBACK: Command creates minimal template"
fi
```

### Duplication Prevention Strategy

Phase 3 (Complexity Evaluation) currently proposes creating `complexity-formula-spec.md` and `complexity-defaults.md`. This WILL be audited against CLAUDE.md adaptive_planning_config section to prevent duplication:

**Audit Checklist**:
- [ ] Compare proposed complexity threshold documentation vs CLAUDE.md adaptive_planning_config
- [ ] Identify overlapping content (thresholds, formulas, ranges)
- [ ] Decision: If >50% overlap, replace Phase 3 documentation tasks with "Reference CLAUDE.md adaptive_planning_config"
- [ ] Add explicit cross-reference to CLAUDE.md section instead of creating duplicate docs
- [ ] Update Phase 3 to only document NEW complexity factors not in CLAUDE.md

**Expected Outcome**: Phase 3 WILL reference existing CLAUDE.md configuration and only add NEW complexity evaluation logic (formula weights, factor definitions) not already documented.

### Bidirectional Link Updates

Pattern files in `.claude/docs/concepts/patterns/` MUST be updated with [Used by:] metadata:

**Files to Update**:
1. behavioral-injection.md → Add [Used by: /orchestrate]
2. forward-message.md → Add [Used by: /orchestrate]
3. metadata-extraction.md → Add [Used by: /orchestrate]
4. checkpoint-recovery.md → Add [Used by: /orchestrate]
5. parallel-execution.md → Add [Used by: /orchestrate]
6. hierarchical-supervision.md → Add [Used by: /orchestrate]
7. context-management.md → Add [Used by: /orchestrate]
8. verification-fallback.md → Add [Used by: /orchestrate]

**Update Format**:
```markdown
# Pattern Name

[Used by: /orchestrate, /implement, /plan]
```

## Implementation Phases

### Phase 1: Pattern Cross-Reference Conversion [COMPLETED]
**Objective**: Convert all pattern name mentions to markdown links in all 8 plan files
**Complexity**: 6/10 (Medium - systematic replacement, 20+ occurrences)
**Dependencies**: None

**Tasks**:

- [x] STEP 1 (REQUIRED BEFORE STEP 2): Create pattern reference mapping file
  ```bash
  # Create mapping of pattern names to file paths
  cat > /tmp/pattern_mapping.txt <<'EOF'
Behavioral Injection=.claude/docs/concepts/patterns/behavioral-injection.md
Forward Message=.claude/docs/concepts/patterns/forward-message.md
Metadata Extraction=.claude/docs/concepts/patterns/metadata-extraction.md
Checkpoint Recovery=.claude/docs/concepts/patterns/checkpoint-recovery.md
Parallel Execution=.claude/docs/concepts/patterns/parallel-execution.md
Hierarchical Supervision=.claude/docs/concepts/patterns/hierarchical-supervision.md
Context Management=.claude/docs/concepts/patterns/context-management.md
Verification and Fallback=.claude/docs/concepts/patterns/verification-fallback.md
EOF
  ```

MANDATORY VERIFICATION CHECKPOINT:
```bash
if [ ! -f "/tmp/pattern_mapping.txt" ]; then
  echo "ERROR: Pattern mapping file not created"
  exit 1
fi
# Verify all referenced pattern files exist
while IFS='=' read -r pattern file; do
  if [ ! -f "/home/benjamin/.config/$file" ]; then
    echo "ERROR: Pattern file does not exist: $file"
  fi
done < /tmp/pattern_mapping.txt
```
End verification. Proceed only if all pattern files exist.

- [x] STEP 2 (REQUIRED BEFORE STEP 3): Update main plan file (080_orchestrate_enhancement.md)
  - Apply pattern reference conversion using mapping
  - Convert all pattern mentions to markdown links
  - Verify relative paths resolve correctly
  - Count conversions (expect ~8-10 in main file)

- [x] STEP 3 (REQUIRED BEFORE STEP 4): Update Phase 0 subplan (phase_0_critical_remove_command_invocations.md)
  - Apply pattern reference conversion
  - Verify behavioral injection pattern link added
  - Count conversions (expect 2-3)

- [x] STEP 4 (REQUIRED BEFORE STEP 5): Update Phase 1 subplan (phase_1_foundation_location_specialist.md)
  - Apply pattern reference conversion
  - Verify behavioral injection and verification-fallback links added
  - Count conversions (expect 2-3)

- [x] STEP 5 (REQUIRED BEFORE STEP 6): Update Phase 3 subplan (phase_3_complexity_evaluation.md)
  - Apply pattern reference conversion
  - Add context management pattern link
  - Count conversions (expect 1-2)

- [x] STEP 6 (REQUIRED BEFORE STEP 7): Update Phase 4 subplan (phase_4_plan_expansion.md)
  - Apply pattern reference conversion
  - Verify hierarchical supervision link added
  - Count conversions (expect 2-3)

- [x] STEP 7 (REQUIRED BEFORE STEP 8): Update Phase 5 subplan (phase_5_wave_based_implementation.md)
  - Apply pattern reference conversion
  - Verify parallel execution and checkpoint recovery links added
  - Count conversions (expect 3-4)

- [x] STEP 8 (REQUIRED BEFORE STEP 9): Update Phase 6 subplan (phase_6_comprehensive_testing.md)
  - Apply pattern reference conversion
  - Add metadata extraction pattern link
  - Count conversions (expect 1-2)

- [x] STEP 9 (REQUIRED BEFORE STEP 10): Update Phase 7 subplan (phase_7_progress_tracking.md)
  - Apply pattern reference conversion
  - Verify forward message pattern link added
  - Count conversions (expect 1-2)

- [x] STEP 10: Validate all pattern links
  ```bash
  # Execute link validation script
  for file in /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md; do
    echo "Validating links in $(basename "$file")..."
    grep -oP '\[.*?\]\(\K[^)]+' "$file" | while read -r path; do
      # Convert relative path to absolute
      abs_path="/home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/$path"
      if [[ ! -f "$abs_path" ]]; then
        echo "  BROKEN LINK: $path"
      fi
    done
  done
  ```

- [x] TESTING: Verify ≥20 pattern references converted to markdown links across all 8 files
- [x] TESTING: Execute link validation - zero broken links expected

**Expected Outcomes**:
- 20+ pattern mentions converted to markdown links
- All links verified to point to existing files
- Consistent markdown link format across all plan files
- Zero broken links in validation test

---

### Phase 2: Imperative Language Transformation [COMPLETED]
**Objective**: Replace weak language (should/may/can) with imperative language (MUST/WILL/SHALL) achieving ≥90% ratio
**Complexity**: 7/10 (Medium-High - systematic replacement, context-sensitive)
**Dependencies**: depends_on: [phase_1]

**Tasks**:

- [x] STEP 1 (REQUIRED BEFORE STEP 2): Create weak language detection script
  ```bash
  cat > /home/benjamin/.config/.claude/lib/tmp/detect_weak_language.sh <<'EOF'
#!/bin/bash
# Detect weak imperative language in plan files

file="$1"
weak_count=0
strong_count=0

# Count weak patterns
weak_count=$(grep -iE '\b(should|may|can|might|could|try to|attempt to|consider|will need to)\b' "$file" | wc -l)

# Count strong patterns
strong_count=$(grep -E '\b(MUST|WILL|SHALL)\b' "$file" | wc -l)

total=$((weak_count + strong_count))
if [ $total -gt 0 ]; then
  ratio=$((strong_count * 100 / total))
else
  ratio=0
fi

echo "File: $(basename "$file")"
echo "  Weak: $weak_count | Strong: $strong_count | Ratio: $ratio%"
EOF
  chmod +x /home/benjamin/.config/.claude/lib/tmp/detect_weak_language.sh
  ```

MANDATORY VERIFICATION CHECKPOINT:
```bash
if [ ! -x "/home/benjamin/.config/.claude/lib/tmp/detect_weak_language.sh" ]; then
  echo "ERROR: Detection script not created or not executable"
  exit 1
fi
```
End verification. Proceed only if script exists and is executable.

- [x] STEP 2 (REQUIRED BEFORE STEP 3): Baseline audit - measure current imperative ratio
  ```bash
  for file in /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md; do
    /home/benjamin/.config/.claude/lib/tmp/detect_weak_language.sh "$file"
  done > /tmp/baseline_imperative_audit.txt
  ```

- [x] STEP 3 (REQUIRED BEFORE STEP 4): Apply systematic replacements to all 8 files
  - `should create` → `MUST create`
  - `should update` → `MUST update`
  - `should verify` → `MUST verify`
  - `should invoke` → `WILL invoke`
  - `should include` → `MUST include`
  - `may include` → `WILL include`
  - `may reference` → `WILL reference`
  - `can run` → `WILL run`
  - `can execute` → `WILL execute`
  - `will need to` → `MUST`
  - `consider adding` → `MUST add`
  - `try to` → `WILL`
  - `attempt to` → `WILL`

- [x] STEP 4 (REQUIRED BEFORE STEP 5): Context-sensitive review of replacements
  - Review each file for grammatical correctness after replacements
  - Ensure MUST used for requirements, WILL used for outcomes/behaviors
  - Verify SHALL used for specifications (rare, mostly MUST/WILL)

- [x] STEP 5: Post-transformation audit - verify ≥90% imperative ratio
  ```bash
  for file in /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md; do
    /home/benjamin/.config/.claude/lib/tmp/detect_weak_language.sh "$file"
  done > /tmp/final_imperative_audit.txt

  # Check if all files meet ≥90% threshold
  awk '/Ratio:/ { if ($NF < 90) print "FAILED: " FILENAME " has ratio " $NF }' /tmp/final_imperative_audit.txt
  ```

- [x] TESTING: Execute imperative language audit - all 8 files MUST show ≥90% ratio
- [x] TESTING: Grep for remaining weak language - expect <10 occurrences total across all files

**Expected Outcomes**:
- All 8 files achieve ≥90% imperative language ratio
- Weak language (should/may/can) reduced by 90%+
- Grammatically correct imperative language throughout
- Audit log shows before/after comparison

---

### Phase 3: Temporal Marker Removal and Present-Focused Rewriting
**Objective**: Remove all temporal markers and historical commentary, rewrite to present-focused documentation
**Complexity**: 5/10 (Medium - mostly Revision History section removal, some phase description rewrites)
**Dependencies**: depends_on: [phase_2]

**Tasks**:

- [ ] STEP 1 (REQUIRED BEFORE STEP 2): Identify temporal markers across all files
  ```bash
  grep -nE '\b(New|Old|Updated|Deprecated|previously|recently|now supports|used to|no longer|migrated to|backward compatibility|breaking change|Revision History)\b' \
    /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md \
    > /tmp/temporal_markers.txt
  ```

- [ ] STEP 2 (REQUIRED BEFORE STEP 3): Remove Revision History section from main plan (080_orchestrate_enhancement.md)
  - Delete entire section starting at "## Revision History"
  - Replace with brief note: "Plan structure optimized for clarity and standards compliance per writing-standards.md"
  - RATIONALE: Revision history is temporal by nature, provides no current value

- [ ] STEP 3 (REQUIRED BEFORE STEP 4): Rewrite Phase 6 description (references "NEW Phase 6")
  - BEFORE: "NEW Phase 6 (Testing): Dedicated test suite execution..."
  - AFTER: "Phase 6 (Testing): Dedicated test suite execution between Implementation and Debugging..."
  - Remove "NEW" marker, focus on what phase does (not when it was added)

- [ ] STEP 4 (REQUIRED BEFORE STEP 5): Review Technical Design sections for temporal language
  - Search for "now supports", "previously", "used to", "breaking change"
  - Rewrite to present tense: "System supports X" instead of "System now supports X"
  - Example: "Plans now include complexity metadata" → "Plans include complexity metadata"

- [ ] STEP 5 (REQUIRED BEFORE STEP 6): Review subplan files for temporal markers
  - Check all 7 subplan files for temporal language
  - Rewrite any historical commentary to present-focused statements
  - Example: "This phase was added to address gap" → "This phase addresses gap"

- [ ] STEP 6: Final temporal marker scan
  ```bash
  # Expect zero matches after cleanup
  grep -nE '\b(New|Old|Updated|Deprecated|previously|recently|now supports|used to|no longer|migrated to|backward compatibility|breaking change|Revision History)\b' \
    /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md
  ```

- [ ] TESTING: Grep temporal markers - expect zero matches across all 8 files
- [ ] TESTING: Manual review of 2-3 random sections - verify present-focused language

**Expected Outcomes**:
- Revision History section removed from main plan
- Zero temporal markers in all 8 files
- All historical commentary rewritten to present tense
- Documentation focused on current state and behavior

---

### Phase 4: Verification Checkpoints and Execution Enforcement
**Objective**: Add mandatory verification checkpoints after all file creation operations with fallback mechanisms
**Complexity**: 8/10 (High - requires analyzing each task, adding verification blocks)
**Dependencies**: depends_on: [phase_3]

**Tasks**:

- [ ] STEP 1 (REQUIRED BEFORE STEP 2): Identify file creation operations in all plans
  ```bash
  # Find tasks involving agent file creation, directory creation, config generation
  grep -nE '(create|invoke.*agent|generate.*file|save.*to|mkdir|directory structure)' \
    /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md \
    > /tmp/file_operations.txt
  ```

- [ ] STEP 2 (REQUIRED BEFORE STEP 3): Create verification checkpoint template
  ```bash
  cat > /tmp/verification_template.txt <<'EOF'

MANDATORY VERIFICATION CHECKPOINT:
```bash
if [ ! -f "{artifact_path}" ]; then
  echo "ERROR: Expected artifact not created at {artifact_path}"
  echo "FALLBACK: Agent failed to create file - command MUST create manually"
  # Create file with minimal template
  cat > "{artifact_path}" <<'TEMPLATE'
# [Template Title]
[Minimal template created by fallback mechanism]
TEMPLATE
fi
```
End verification. Proceed only if file exists.
EOF
  ```

- [ ] STEP 3 (REQUIRED BEFORE STEP 4): Add verification to Phase 1 subplan (location-specialist agent invocation)
  - After task "Invoke location-specialist agent to create topic directory"
  - Insert verification checkpoint for directory existence
  - Fallback: mkdir -p if directory not created by agent

- [ ] STEP 4 (REQUIRED BEFORE STEP 5): Add verification to Phase 2 inline plan (research-synthesizer agent)
  - After task "Invoke research-synthesizer agent to create overview report"
  - Insert verification checkpoint for overview report file
  - Fallback: Create minimal overview template

- [ ] STEP 5 (REQUIRED BEFORE STEP 6): Add verification to Phase 3 subplan (complexity-estimator output)
  - After task "Invoke complexity-estimator agent"
  - Insert verification for complexity report artifact
  - Fallback: Manual complexity scoring if agent fails

- [ ] STEP 6 (REQUIRED BEFORE STEP 7): Add verification to Phase 4 subplan (expansion-specialist operations)
  - After task "Invoke expansion-specialist to expand high-complexity phases"
  - Insert verification for expanded phase files
  - Fallback: Manual phase expansion if agent fails

- [ ] STEP 7 (REQUIRED BEFORE STEP 8): Add verification to Phase 5 subplan (implementation-executor agents)
  - After task "Invoke parallel implementation-executor agents"
  - Insert verification for implementation artifacts (code files, tests)
  - Fallback: Sequential implementation if parallel execution fails

- [ ] STEP 8 (REQUIRED BEFORE STEP 9): Add verification to Phase 6 subplan (test-specialist output)
  - After task "Invoke test-specialist agent for comprehensive testing"
  - Insert verification for test results artifact
  - Fallback: Direct test execution if agent fails

- [ ] STEP 9 (REQUIRED BEFORE STEP 10): Add verification to Phase 7 subplan (spec-updater operations)
  - After task "Invoke spec-updater agent for hierarchy updates"
  - Insert verification for updated plan files
  - Fallback: Manual plan updates if agent fails

- [ ] STEP 10: Count verification checkpoints added
  ```bash
  grep -c "MANDATORY VERIFICATION CHECKPOINT" \
    /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md
  # Expect 10-15 verification blocks across all files
  ```

- [ ] TESTING: Verify each file creation task has corresponding VERIFICATION CHECKPOINT
- [ ] TESTING: Verify all checkpoints include explicit [ ! -f ] or [ ! -d ] checks
- [ ] TESTING: Verify all checkpoints include FALLBACK mechanisms

**Expected Outcomes**:
- 10-15 verification checkpoints added across all plan files
- All file/directory creation tasks protected with verification
- All verifications include explicit fallback mechanisms
- Execution enforcement standards compliance achieved

---

### Phase 5: Duplication Audit and Cross-Reference Correction
**Objective**: Audit Phase 3 for duplication with CLAUDE.md, correct file references, add testing validation checkboxes
**Complexity**: 7/10 (Medium-High - requires content analysis, decision-making)
**Dependencies**: depends_on: [phase_4]

**Tasks**:

- [ ] STEP 1 (REQUIRED BEFORE STEP 2): Extract CLAUDE.md adaptive_planning_config section
  ```bash
  sed -n '/<!-- SECTION: adaptive_planning_config -->/,/<!-- END_SECTION: adaptive_planning_config -->/p' \
    /home/benjamin/.config/CLAUDE.md \
    > /tmp/claude_adaptive_config.txt
  ```

- [ ] STEP 2 (REQUIRED BEFORE STEP 3): Extract Phase 3 proposed documentation tasks
  ```bash
  grep -A 10 "complexity-formula-spec.md\|complexity-defaults.md\|progressive-planning.md" \
    /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/phase_3_complexity_evaluation.md \
    > /tmp/phase3_proposed_docs.txt
  ```

- [ ] STEP 3 (REQUIRED BEFORE STEP 4): Analyze overlap between Phase 3 docs and CLAUDE.md config
  - Compare complexity thresholds: CLAUDE.md defines expansion threshold (8.0), task count (10), file references (10)
  - Compare complexity factors: CLAUDE.md lists factors influencing complexity
  - Decision matrix:
    - IF overlap >50%: Replace Phase 3 documentation tasks with "Reference CLAUDE.md adaptive_planning_config"
    - IF overlap <50%: Keep Phase 3 docs but add explicit cross-reference to CLAUDE.md
  - Document decision in /tmp/duplication_audit_decision.txt

MANDATORY VERIFICATION CHECKPOINT:
```bash
if [ ! -f "/tmp/duplication_audit_decision.txt" ]; then
  echo "ERROR: Duplication audit decision not documented"
  echo "FALLBACK: Default to referencing CLAUDE.md (avoid duplication)"
  echo "DEFAULT: Reference CLAUDE.md adaptive_planning_config" > /tmp/duplication_audit_decision.txt
fi
```
End verification. Proceed only if decision documented.

- [ ] STEP 4 (REQUIRED BEFORE STEP 5): Update Phase 3 based on duplication audit decision
  - If referencing CLAUDE.md: Replace documentation tasks with cross-reference
  - Add markdown link to CLAUDE.md section: `[adaptive_planning_config](../../../CLAUDE.md#adaptive_planning_config)`
  - Remove proposed file creation tasks for duplicative documentation

- [ ] STEP 5 (REQUIRED BEFORE STEP 6): Correct all file references in plan 080
  ```bash
  # Find progressive-planning.md references
  grep -n "progressive-planning.md" \
    /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md

  # Replace with adaptive-planning-guide.md
  # Verify file exists first
  ls -la /home/benjamin/.config/.claude/docs/guides/adaptive-planning-guide.md
  ```

- [ ] STEP 6 (REQUIRED BEFORE STEP 7): Correct progressive-planning.md → adaptive-planning-guide.md
  - Search all 8 files for "progressive-planning.md"
  - Replace with correct filename: "adaptive-planning-guide.md"
  - Update relative paths if needed

- [ ] STEP 7 (REQUIRED BEFORE STEP 8): Add testing validation checkboxes to success criteria
  - For each success criterion in main plan, add corresponding TESTING checkbox
  - Format: `- [ ] TESTING: [Specific test command or validation script]`
  - Example: "All research reports created in correct structure" → Add "TESTING: Validate report paths match specs/\d{3}_\w+/reports/"

- [ ] STEP 8: Validate all success criteria have testing checkboxes
  ```bash
  # Count success criteria vs testing checkboxes
  success_count=$(grep -c '^\- \[ \]' /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/080_orchestrate_enhancement.md | head -1)
  testing_count=$(grep -c 'TESTING:' /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/080_orchestrate_enhancement.md)

  echo "Success criteria: $success_count"
  echo "Testing checkboxes: $testing_count"
  # Testing checkboxes should be ~50% of success criteria (one test per 2 criteria)
  ```

- [ ] TESTING: Verify Phase 3 either references CLAUDE.md or adds only non-duplicate content
- [ ] TESTING: Verify zero references to "progressive-planning.md" (corrected to adaptive-planning-guide.md)
- [ ] TESTING: Verify all success criteria have at least one TESTING validation checkbox

**Expected Outcomes**:
- Phase 3 duplication eliminated (references CLAUDE.md or adds only new content)
- All file references corrected (progressive-planning.md → adaptive-planning-guide.md)
- All success criteria include TESTING validation checkboxes
- Duplication audit decision documented

---

### Phase 6: Behavioral Injection Verification and Bidirectional Links
**Objective**: Verify Phase 0 path pre-calculation completeness, ensure Task tool usage, update pattern files with [Used by:] tags
**Complexity**: 6/10 (Medium - verification and metadata updates)
**Dependencies**: depends_on: [phase_5]

**Tasks**:

- [ ] STEP 1 (REQUIRED BEFORE STEP 2): Audit Phase 0 for complete path pre-calculation workflow
  - Verify Phase 0 includes ARTIFACT_PATHS calculation block (all 6 paths: reports, plans, summaries, debug, scripts, outputs)
  - Verify AGENT_CONTEXT injection template specified
  - Verify behavioral injection instructions included ("MUST save to {artifact_paths.reports}")
  - Verify verification checkpoint after path calculation

- [ ] STEP 2 (REQUIRED BEFORE STEP 3): Add missing path pre-calculation elements to Phase 0 if needed
  - If ARTIFACT_PATHS incomplete: Add all 6 paths
  - If AGENT_CONTEXT template missing: Add complete injection template
  - If verification missing: Add checkpoint to verify directory structure created

- [ ] STEP 3 (REQUIRED BEFORE STEP 4): Verify all agent invocations use Task tool (not SlashCommand)
  ```bash
  # Search for potential SlashCommand violations
  grep -nE '(SlashCommand|invoke.*\/[a-z\-]+)' \
    /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md \
    > /tmp/potential_command_invocations.txt

  # Review each match - ensure only Task tool invocations present
  ```

- [ ] STEP 4 (REQUIRED BEFORE STEP 5): Update all agent invocations to specify Task tool explicitly
  - Search for "Invoke [agent-name]" patterns
  - Add explicit "via Task tool" specification
  - Example: "Invoke research-synthesizer agent" → "Invoke research-synthesizer agent via Task tool with behavioral injection"

- [ ] STEP 5 (REQUIRED BEFORE STEP 6): Update pattern files with [Used by: /orchestrate] tags
  - Update behavioral-injection.md metadata header
  - Update forward-message.md metadata header
  - Update metadata-extraction.md metadata header
  - Update checkpoint-recovery.md metadata header
  - Update parallel-execution.md metadata header
  - Update hierarchical-supervision.md metadata header
  - Update context-management.md metadata header
  - Update verification-fallback.md metadata header

- [ ] STEP 6 (REQUIRED BEFORE STEP 7): Verify pattern file updates
  ```bash
  # Check each pattern file has [Used by:] tag including /orchestrate
  for pattern in behavioral-injection forward-message metadata-extraction checkpoint-recovery parallel-execution hierarchical-supervision context-management verification-fallback; do
    if ! grep -q "\[Used by:.*\/orchestrate" "/home/benjamin/.config/.claude/docs/concepts/patterns/${pattern}.md"; then
      echo "MISSING: /orchestrate not in [Used by:] tag for $pattern.md"
    fi
  done
  ```

MANDATORY VERIFICATION CHECKPOINT:
```bash
# Verify all 8 pattern files updated
expected_patterns=("behavioral-injection" "forward-message" "metadata-extraction" "checkpoint-recovery" "parallel-execution" "hierarchical-supervision" "context-management" "verification-fallback")
for pattern in "${expected_patterns[@]}"; do
  file="/home/benjamin/.config/.claude/docs/concepts/patterns/${pattern}.md"
  if [ ! -f "$file" ]; then
    echo "ERROR: Pattern file not found: $file"
  elif ! grep -q "\[Used by:.*\/orchestrate" "$file"; then
    echo "ERROR: Pattern file missing [Used by: /orchestrate] tag: $file"
  fi
done
```
End verification. Proceed only if all pattern files updated.

- [ ] STEP 7: Validate bidirectional links
  - Verify plan 080 links to all 8 pattern files (forward direction)
  - Verify all 8 pattern files include /orchestrate in [Used by:] tags (backward direction)
  - Create cross-reference validation report

- [ ] TESTING: Verify Phase 0 includes complete ARTIFACT_PATHS block (all 6 paths)
- [ ] TESTING: Grep for SlashCommand tool usage - expect zero matches in all plan files
- [ ] TESTING: Verify all 8 pattern files include [Used by: /orchestrate] metadata
- [ ] TESTING: Execute bidirectional link validation - zero broken links

**Expected Outcomes**:
- Phase 0 includes complete path pre-calculation workflow
- All agent invocations explicitly specify Task tool
- All 8 pattern files updated with [Used by: /orchestrate] tags
- Bidirectional links validated (plan → patterns, patterns → plan)
- Behavioral injection pattern compliance verified

---

## Testing Strategy

### Validation Scripts

**Script 1: Imperative Language Audit**
```bash
#!/bin/bash
# Location: .claude/lib/tmp/validate_imperative_language.sh

for file in /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md; do
  weak=$(grep -icE '\b(should|may|can|might|could)\b' "$file")
  strong=$(grep -cE '\b(MUST|WILL|SHALL)\b' "$file")
  total=$((weak + strong))

  if [ $total -gt 0 ]; then
    ratio=$((strong * 100 / total))
    echo "$(basename "$file"): $ratio% imperative (weak: $weak, strong: $strong)"

    if [ $ratio -lt 90 ]; then
      echo "  FAILED: Below 90% threshold"
      exit 1
    fi
  fi
done

echo "All files pass ≥90% imperative language threshold"
```

**Script 2: Temporal Marker Detection**
```bash
#!/bin/bash
# Location: .claude/lib/tmp/validate_temporal_markers.sh

markers=$(grep -nE '\b(New|Old|Updated|Deprecated|previously|recently|now supports|used to|no longer|Revision History)\b' \
  /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md)

if [ -n "$markers" ]; then
  echo "FAILED: Temporal markers detected:"
  echo "$markers"
  exit 1
else
  echo "PASSED: Zero temporal markers detected"
fi
```

**Script 3: Verification Checkpoint Count**
```bash
#!/bin/bash
# Location: .claude/lib/tmp/validate_verification_checkpoints.sh

checkpoint_count=$(grep -c "MANDATORY VERIFICATION CHECKPOINT" \
  /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md)

if [ $checkpoint_count -lt 10 ]; then
  echo "FAILED: Only $checkpoint_count verification checkpoints found (expected ≥10)"
  exit 1
else
  echo "PASSED: $checkpoint_count verification checkpoints found"
fi
```

**Script 4: Pattern Link Validation**
```bash
#!/bin/bash
# Location: .claude/lib/tmp/validate_pattern_links.sh

base_dir="/home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement"

for file in "$base_dir"/*.md; do
  echo "Validating links in $(basename "$file")..."

  grep -oP '\[.*?\]\(\K[^)]+\.md' "$file" | while read -r link; do
    # Convert relative path to absolute
    abs_link="$base_dir/$link"

    if [[ ! -f "$abs_link" ]]; then
      echo "  BROKEN LINK: $link"
      exit 1
    fi
  done
done

echo "PASSED: All pattern links valid"
```

**Script 5: SlashCommand Invocation Detection**
```bash
#!/bin/bash
# Location: .claude/lib/tmp/validate_no_slashcommand.sh

violations=$(grep -nE '(SlashCommand|invoke.*\/[a-z\-]+)' \
  /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md)

if [ -n "$violations" ]; then
  echo "FAILED: Potential SlashCommand invocations detected:"
  echo "$violations"
  exit 1
else
  echo "PASSED: Zero SlashCommand invocations detected"
fi
```

### Integration Testing

**Test 1: Complete Standards Validation Suite**
```bash
#!/bin/bash
# Execute all validation scripts in sequence

cd /home/benjamin/.config/.claude/lib/tmp

echo "=== Running Standards Validation Suite for Plan 080 ==="

./validate_imperative_language.sh || exit 1
./validate_temporal_markers.sh || exit 1
./validate_verification_checkpoints.sh || exit 1
./validate_pattern_links.sh || exit 1
./validate_no_slashcommand.sh || exit 1

echo "=== All validation tests PASSED ==="
```

**Test 2: Manual Review Checklist**
- [ ] Review 2-3 random sections from each file - verify readability and grammar
- [ ] Verify pattern links resolve correctly when clicked
- [ ] Verify verification checkpoints include realistic fallback mechanisms
- [ ] Verify success criteria testing checkboxes are specific and actionable
- [ ] Verify Phase 3 duplication elimination effective

### Regression Testing

**Test 3: Plan 080 Technical Accuracy**
- [ ] Verify technical content unchanged (no functionality altered by standards alignment)
- [ ] Verify agent descriptions accurate and complete
- [ ] Verify complexity scores unchanged
- [ ] Verify dependency relationships preserved

### Performance Validation

**Test 4: File Size and Readability**
```bash
# Measure file sizes before/after alignment
for file in /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/*.md; do
  wc -l "$file"
done

# Verify files not excessively bloated by verification checkpoints
# Expect <10% file size increase
```

## Documentation Requirements

### Plan Documentation Updates

This alignment process WILL update the following documentation:

1. **Plan 080 Files** (8 files):
   - Main plan: 080_orchestrate_enhancement.md
   - 7 subplan files (phase_0 through phase_7)

2. **Pattern Files** (8 files):
   - All pattern files with [Used by:] tag updates

3. **Audit Logs** (generated during implementation):
   - /tmp/baseline_imperative_audit.txt
   - /tmp/final_imperative_audit.txt
   - /tmp/duplication_audit_decision.txt
   - /tmp/temporal_markers.txt
   - /tmp/file_operations.txt

### Standards Reference Documentation

No new standards documentation WILL be created. This plan references existing standards:

- CLAUDE.md (adaptive_planning_config section)
- .claude/docs/concepts/writing-standards.md
- .claude/docs/reference/command_architecture_standards.md
- .claude/docs/concepts/patterns/*.md (8 pattern files)

### Commit Documentation

All changes WILL be committed with standardized message:

```
feat: align plan 080 with .claude/docs/ standards

Systematically align 080_orchestrate_enhancement.md and 7 subplan files with
established standards: imperative language (≥90% ratio), pattern cross-references
(20+ markdown links), temporal marker removal, verification checkpoints (10+),
duplication elimination, and bidirectional link updates.

Standards compliance verified via 5 validation scripts.
```

## Dependencies

### External Dependencies

- **Pattern Files**: 8 pattern files in .claude/docs/concepts/patterns/ (must exist)
- **CLAUDE.md**: adaptive_planning_config section (referenced, not duplicated)
- **Writing Standards**: .claude/docs/concepts/writing-standards.md (referenced)
- **Command Architecture Standards**: .claude/docs/reference/command_architecture_standards.md (referenced)

### Internal Dependencies

- Phase 2 depends on Phase 1 (pattern links must exist before language transformation)
- Phase 3 depends on Phase 2 (temporal removal after imperative transformation)
- Phase 4 depends on Phase 3 (verification after core content stable)
- Phase 5 depends on Phase 4 (duplication audit after verification complete)
- Phase 6 depends on Phase 5 (bidirectional links after all content finalized)

### Tool Dependencies

- **Bash**: For validation scripts (grep, sed, awk)
- **Git**: For commit after alignment complete
- **Edit Tool**: For systematic file modifications

## Risk Assessment

### High Risk: None

This alignment process is low-risk as it modifies documentation (not executable code) and follows systematic, reversible transformations.

### Medium Risk

- **Over-Correction**: Excessive imperative language may reduce readability
  - **Mitigation**: Context-sensitive review in Phase 2, grammatical validation
  - **Fallback**: Manual review and adjustment of awkward phrasing

- **Link Breakage**: Pattern file reorganization could break markdown links
  - **Mitigation**: Link validation script execution after each phase
  - **Fallback**: Correct broken links immediately when detected

### Low Risk

- **Verification Bloat**: Adding 10+ verification checkpoints may increase file size
  - **Mitigation**: Use concise template format, avoid verbose explanations
  - **Acceptable**: 10% file size increase is acceptable for execution enforcement

- **Pattern File Conflicts**: Multiple simultaneous updates to pattern files
  - **Mitigation**: Coordinate pattern file updates in single phase (Phase 6)
  - **Fallback**: Git merge if conflicts occur

## Notes

### Alignment Philosophy

This plan follows the established [Writing Standards](.claude/docs/concepts/writing-standards.md) principle: **Clean, coherent systems over backward compatibility**. The alignment systematically transforms plan 080 to match current standards without preserving historical artifacts (Revision History section removed) or legacy language patterns.

### Imperative Language Rationale

Imperative language (MUST/WILL/SHALL) ensures clarity in execution requirements. The ≥90% threshold balances:
- **Clarity**: Unambiguous requirements for command execution
- **Readability**: Avoids excessive formality in descriptive sections
- **Standards Compliance**: Matches [Command Architecture Standards](.claude/docs/reference/command_architecture_standards.md) requirements

### Verification Checkpoint Pattern

The mandatory verification checkpoint pattern follows the [Verification and Fallback Pattern](.claude/docs/concepts/patterns/verification-fallback.md), implementing:

1. **Explicit Verification**: `[ ! -f "{path}" ]` checks after agent operations
2. **Fallback Mechanism**: Command creates minimal template if agent fails
3. **Error Reporting**: Clear error messages indicating failure point
4. **Continuation Safety**: Ensures workflow can proceed despite agent failures

This pattern addresses the critical gap in execution enforcement where agent-dependent file creation operations could fail silently.

### Duplication Prevention Strategy

Phase 5 implements a systematic duplication audit comparing proposed Phase 3 documentation against existing CLAUDE.md adaptive_planning_config section. The decision matrix prioritizes:

1. **Reference over Duplication**: If >50% overlap, reference CLAUDE.md
2. **Extend over Replace**: If <50% overlap, keep docs but add cross-reference
3. **Document Decisions**: Audit decision logged for transparency

This approach maintains single-source-of-truth for configuration while allowing domain-specific extensions.

### Bidirectional Link Importance

Bidirectional links between plan files and pattern files enable:

- **Discoverability**: Patterns show which commands use them ([Used by:] tags)
- **Validation**: Plans link to authoritative pattern definitions
- **Maintenance**: Pattern updates can identify affected commands
- **Context**: Readers understand pattern application scope

The [Pattern Documentation Standards](.claude/docs/concepts/patterns/README.md) require these bidirectional links for pattern catalog integrity.

### Testing Philosophy

The testing strategy emphasizes **automated validation** over manual review:

- 5 validation scripts provide reproducible, objective measurements
- Scripts integrated into integration test suite for regression prevention
- Manual review reserved for context-sensitive evaluation (readability, grammar)
- Performance validation ensures alignment doesn't degrade usability (file size, readability)

This approach enables confident, repeatable standards enforcement across all plan files.
