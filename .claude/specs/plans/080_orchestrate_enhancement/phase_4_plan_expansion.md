# Phase 4: Plan Expansion - Hierarchical Structure and Automated Expansion

## Metadata
- **Phase Number**: 4
- **Parent Plan**: [080_orchestrate_enhancement.md](../080_orchestrate_enhancement.md)
- **Structure Level**: Level 1 (Phase Expansion)
- **Complexity Score**: 9/10
- **Expansion Reason**: Multi-level expansion logic with recursion, structural manipulation, and plan hierarchy integrity requiring detailed breakdown into stages
- **Dependencies**: depends_on: [phase_3]
- **Date**: 2025-10-21

## Objective

Implement automated plan expansion with expansion-specialist agent to create hierarchical plan structure based on complexity analysis. This phase establishes the foundation for progressive planning by enabling plans to automatically expand from Level 0 (inline phases) to Level 1 (separate phase files) to Level 2 (separate stage files) based on complexity thresholds.

## Complexity Analysis

**Why This Phase Needs Expansion (9/10 complexity)**:
- **Multi-Level Logic**: Implements both Level 1 (Phase → Stages) and Level 2 (Stage → Detailed Files) expansion with different patterns
- **Structural Manipulation**: Creates directories, moves files, updates parent plans with references and summaries
- **Recursive Evaluation**: Re-analyzes complexity after each expansion to determine if further expansion needed
- **Integrity Maintenance**: Must preserve all content, maintain cross-references, update metadata consistently
- **File Count**: 15+ file operations across different plan levels
- **Error Handling**: Complex rollback scenarios for over-expansion and structural conflicts

## Overview

This phase creates the expansion-specialist agent and implements the complete expansion workflow that:
1. Extracts high-complexity phases from Level 0 plans to separate files (Level 1)
2. Expands high-complexity stages within phases to separate files (Level 2)
3. Creates proper directory structures for hierarchical plans
4. Updates parent plans with summaries and reference links
5. Maintains metadata consistency across all plan levels
6. Integrates recursive complexity evaluation to prevent over/under-expansion
7. Adds expansion phase orchestration to orchestrate.md workflow

## Stage Breakdown

### Stage 1: Create expansion-specialist Agent Template
**Objective**: Create the expansion-specialist agent definition with complete behavioral guidelines, workflow steps, and output requirements.
**Complexity**: Medium (6/10)
**Estimated Time**: 45-60 minutes

This stage establishes the agent template that will be used by /orchestrate to perform all expansion operations. The agent must follow strict protocols to preserve content, maintain structure, and ensure cross-reference integrity.

#### Tasks

- [ ] **Create agent file structure**
 - Create `.claude/agents/expansion-specialist.md`
 - Add metadata section with agent role and purpose
 - Define agent responsibilities (extraction, structure creation, parent updates, metadata maintenance)
 - Document behavioral guidelines (read-only analysis, write-only expansion, content preservation)
 - Set constraints (no interpretation, strict progressive structure patterns)

- [ ] **Document expansion workflow for Phase Expansion (Level 0 → 1)**
 - **STEP 1 (Validation)**: Define validation requirements
  - Verify plan file exists and is readable
  - Verify phase number is valid (not already expanded)
  - Verify write permissions on target directory
  - Confirm current Structure Level is 0
  - Provide bash verification commands
 - **STEP 2 (Extraction)**: Define content extraction requirements
  - Read main plan file
  - Extract full phase content (heading to next heading or EOF)
  - Preserve all formatting, code blocks, checkboxes
  - Capture phase name from heading
  - Maintain exact indentation and markdown structure
 - **STEP 3 (File Creation)**: Define file structure creation
  - Create plan directory if Level 0 → 1 transition
  - Create phase file with extracted content
  - Verify file creation successful
  - Record file size and path for artifact
  - Provide fallback file creation method
 - **STEP 4 (Parent Update)**: Define parent plan update pattern
  - Replace phase content with summary in parent plan
  - Add `[See: phase_N_name.md]` marker
  - Update Structure Level metadata to 1
  - Add phase number to Expanded Phases list
  - Provide parent plan update template
 - **STEP 4.5 (Cross-Reference Verification)**: Define spec-updater invocation
  - Invoke spec-updater agent to verify links functional
  - Pass parent plan path and new phase file path
  - Verify all markdown links resolve to existing files
  - Fix any broken links immediately
  - Report verification results
 - **STEP 5 (Artifact Creation)**: Define expansion artifact requirements
  - Create artifact file at `specs/artifacts/{plan_name}/expansion_{N}.md`
  - Include all required sections (Metadata, Operation Summary, Files Created/Modified, Metadata Changes, Content Summary, Validation)
  - Populate all metadata fields
  - Complete validation checklist
  - Verify artifact creation with fallback

- [ ] **Document expansion workflow for Stage Expansion (Level 1 → 2)**
 - **STEP 1 (Validation)**: Adapt validation for stage expansion
  - Verify phase file exists and is readable
  - Verify stage number is valid (not already expanded)
  - Confirm current Structure Level is 1
 - **STEP 2 (Extraction)**: Define stage content extraction
  - Read phase file
  - Extract full stage content (#### Stage heading to next stage or EOF)
  - Preserve all formatting
  - Capture stage name from heading
 - **STEP 3 (File Creation)**: Define stage file structure
  - Create phase subdirectory if first stage expansion
  - Create phase overview file (if first stage expansion)
  - Create stage file with extracted content
  - Verify file creation successful
 - **STEP 4 (Parent Update)**: Define phase file update for stages
  - Replace stage content with summary in phase file
  - Add `[See: stage_M_name.md]` marker
  - Add stage to Expanded Stages list in phase file
  - Update main plan Structure Level to 2
 - **STEP 4.5 (Cross-Reference Verification)**: Invoke spec-updater for stage links
 - **STEP 5 (Artifact Creation)**: Create stage expansion artifact

- [ ] **Define artifact format template**
 - Document exact artifact structure (must match template exactly)
 - Mark all REQUIRED sections
 - Define metadata fields that must be populated
 - Define validation checklist items (all must be checked)
 - Provide example artifacts for both phase and stage expansion

- [ ] **Define metadata update requirements**
 - Document Structure Level transitions (0 → 1 → 2)
 - Define Expanded Phases list format: `[1, 3, 5]`
 - Define Expanded Stages list format: `Phase 1: [2, 3]`
 - Provide bash commands for metadata updates (sed patterns)

- [ ] **Define error handling protocols**
 - Document validation checks (all mandatory before operation)
 - Define error response format (structured markdown)
 - Provide error types: validation, permission, not_found, structural_conflict
 - Define recovery suggestions for each error type
 - Document rollback procedures for failed expansions

- [ ] **Define completion criteria**
 - List all file operations that must succeed
 - List all metadata updates that must be applied
 - Define cross-reference integrity requirements
 - Define artifact creation requirements
 - Define return format (exact structure for orchestrator parsing)

- [ ] **Add examples section**
 - Provide phase expansion example (input/output)
 - Provide stage expansion example (input/output)
 - Show directory structure before/after expansion
 - Show parent plan content before/after expansion

#### Testing

```bash
# Verify agent file created
test -f /home/benjamin/.config/.claude/agents/expansion-specialist.md
echo "✓ Agent file exists"

# Verify agent has all required sections
grep -q "## Expansion Workflow" /home/benjamin/.config/.claude/agents/expansion-specialist.md
grep -q "### Phase Expansion (Level 0 → 1)" /home/benjamin/.config/.claude/agents/expansion-specialist.md
grep -q "### Stage Expansion (Level 1 → 2)" /home/benjamin/.config/.claude/agents/expansion-specialist.md
grep -q "## Artifact Format" /home/benjamin/.config/.claude/agents/expansion-specialist.md
grep -q "## Metadata Updates" /home/benjamin/.config/.claude/agents/expansion-specialist.md
grep -q "## Error Handling" /home/benjamin/.config/.claude/agents/expansion-specialist.md
grep -q "## COMPLETION CRITERIA" /home/benjamin/.config/.claude/agents/expansion-specialist.md
echo "✓ All required sections present"

# Verify STEP 4.5 spec-updater integration present
grep -q "STEP 4.5.*Verify Cross-References" /home/benjamin/.config/.claude/agents/expansion-specialist.md
echo "✓ Cross-reference verification integrated"

# Verify artifact template has all REQUIRED sections
grep -q "## Metadata (REQUIRED)" /home/benjamin/.config/.claude/agents/expansion-specialist.md
grep -q "## Operation Summary (REQUIRED)" /home/benjamin/.config/.claude/agents/expansion-specialist.md
grep -q "## Files Created (REQUIRED - Minimum 1)" /home/benjamin/.config/.claude/agents/expansion-specialist.md
grep -q "## Validation (ALL REQUIRED - Must be checked)" /home/benjamin/.config/.claude/agents/expansion-specialist.md
echo "✓ Artifact template complete"
```

#### Expected Outcomes
- expansion-specialist.md created with complete workflow documentation
- All 5 steps defined for both phase and stage expansion
- Artifact format template with all REQUIRED sections
- Error handling protocols for all failure scenarios
- Completion criteria clearly defined for orchestrator validation
- spec-updater integration at STEP 4.5 for cross-reference verification

---

### Stage 2: Implement Level 1 Expansion Logic (Phase → Stages)
**Objective**: Implement the core logic for expanding high-complexity phases from Level 0 plans into separate Level 1 files with detailed stage breakdown.
**Complexity**: High (8/10)
**Estimated Time**: 90-120 minutes

This stage implements the most common expansion pattern: taking a phase with 10+ tasks or complexity >8.0 and breaking it into a separate file with multiple stages.

#### Tasks

- [ ] **Create expansion validation utility**
 - Script: `.claude/lib/expansion-validation.sh`
 - Function: `validate_phase_expansion_request(plan_path, phase_num)`
  - Check plan file exists and is readable
  - Parse plan metadata to get current Structure Level
  - Verify Structure Level is 0 (inline phases)
  - Check if phase already expanded (grep "Expanded Phases:.*\[$phase_num\]")
  - Verify write permissions on plan directory
  - Return: validation status (pass/fail) + error message if failed
 - Function: `validate_stage_expansion_request(phase_path, stage_num)`
  - Check phase file exists and is readable
  - Verify Structure Level is 1
  - Check if stage already expanded
  - Verify write permissions
  - Return: validation status + error message

- [ ] **Create content extraction utility**
 - Script: `.claude/lib/content-extraction.sh`
 - Function: `extract_phase_content(plan_path, phase_num)`
  - Parse plan file to find phase heading (### Phase {N}:)
  - Extract from heading to next phase heading or EOF
  - Preserve all formatting, indentation, code blocks, checkboxes
  - Capture phase name from heading (remove "### Phase N: " prefix)
  - Return: extracted content + phase name + start/end line numbers
 - Function: `extract_stage_content(phase_path, stage_num)`
  - Parse phase file to find stage heading (#### Stage {M}:)
  - Extract from heading to next stage heading or EOF
  - Preserve all formatting
  - Capture stage name from heading
  - Return: extracted content + stage name + line numbers

- [ ] **Implement directory structure creation**
 - Function: `create_plan_directory_structure(plan_path)`
  - Extract plan name from path (basename without .md)
  - Create directory: `$(dirname plan_path)/{plan_name}/`
  - Move original Level 0 plan into directory (mv plan_path to directory)
  - Verify directory creation successful
  - Return: new plan directory path + moved plan path
 - Function: `create_phase_directory_structure(phase_path)`
  - Extract phase name from path
  - Create subdirectory: `$(dirname phase_path)/{phase_name}/`
  - Create phase overview file: `{phase_name}_overview.md`
  - Verify structure created
  - Return: new phase directory path + overview file path

- [ ] **Implement phase file creation**
 - Function: `create_phase_file(plan_dir, phase_num, phase_name, phase_content)`
  - Sanitize phase name (lowercase, replace spaces with underscores)
  - Generate filename: `phase_{phase_num}_{sanitized_name}.md`
  - Write content to file with proper formatting
  - Add metadata section at top:
   ```markdown
   ## Metadata
   - **Phase Number**: {phase_num}
   - **Parent Plan**: [{plan_name}.md](../{plan_name}.md)
   - **Structure Level**: Level 1 (Phase Expansion)
   - **Complexity Score**: {from complexity-estimator}
   - **Expansion Reason**: {reason from complexity analysis}
   - **Dependencies**: {parse from original phase content}
   ```
  - Verify file creation with fallback method (echo > file if cat fails)
  - Return: phase file path + file size

- [ ] **Implement parent plan update for Level 1 expansion**
 - Function: `update_parent_plan_phase_summary(plan_path, phase_num, phase_name, phase_file_relative_path, complexity_score, task_count)`
  - Generate summary content:
   ```markdown
   ### Phase {N}: {Phase Name} [See: {phase_file_relative_path}]

   **Summary**: {1-2 sentence description extracted from phase objective}
   **Complexity**: {score}/10 - {complexity justification}
   **Tasks**: {task_count} implementation tasks
   **Status**: Expanded to detailed phase plan

   This phase has been expanded due to high complexity. See detailed phase plan for complete implementation stages.
   ```
  - Use sed/awk to replace detailed phase content with summary in plan file
  - Preserve heading and basic structure
  - Verify replacement successful
  - Return: updated plan content excerpt

- [ ] **Implement metadata updates for Level 1**
 - Function: `update_metadata_structure_level(plan_path, new_level)`
  - Use sed to update Structure Level line: `s/^- \*\*Structure Level\*\*:.*/- **Structure Level**: {new_level}/`
  - Verify update applied
  - Return: success/failure
 - Function: `update_expanded_phases_list(plan_path, phase_num)`
  - Extract current Expanded Phases list (grep + sed)
  - Append phase_num to list: `[1, 3] → [1, 3, 5]`
  - Update plan file with new list
  - Create Expanded Phases line if doesn't exist
  - Verify update applied
  - Return: new expanded phases list

- [ ] **Implement expansion artifact creation**
 - Function: `create_expansion_artifact(artifacts_dir, phase_num, operation_type, files_created, files_modified, metadata_changes, content_summary)`
  - Create artifacts directory: `specs/artifacts/{plan_name}/`
  - Generate artifact filename: `expansion_{phase_num}.md` or `expansion_phase{P}_stage{S}.md`
  - Populate artifact template with all REQUIRED sections:
   - Metadata (operation, item, timestamp, complexity score)
   - Operation Summary (action taken, reason)
   - Files Created (list with sizes)
   - Files Modified (list with changes)
   - Metadata Changes (structure level transition, expanded lists)
   - Content Summary (lines extracted, task/test counts)
   - Validation checklist (all items checked)
  - Verify artifact creation with fallback
  - Return: artifact file path

- [ ] **Integrate all utilities into expansion workflow**
 - Create main expansion function: `expand_phase_to_level1(plan_path, phase_num, complexity_score)`
  - STEP 1: Validate request (validate_phase_expansion_request)
  - STEP 2: Extract content (extract_phase_content)
  - STEP 3: Create structure (create_plan_directory_structure + create_phase_file)
  - STEP 4: Update parent (update_parent_plan_phase_summary + update metadata)
  - STEP 4.5: Invoke spec-updater for cross-reference verification
  - STEP 5: Create artifact (create_expansion_artifact)
  - Return: expansion report with all file paths and metadata changes
 - Handle errors at each step with rollback if needed
 - Log all operations for debugging

#### Testing

```bash
# Create test plan for expansion testing
cat > /tmp/test_expansion_plan.md <<'EOF'
# Test Plan

## Metadata
- **Structure Level**: 0
- **Expanded Phases**: []

### Phase 1: Simple Phase
**Objective**: Simple phase, should not expand
Tasks: 3 tasks

### Phase 2: Complex Phase
**Objective**: High complexity phase with many tasks
Tasks: 15 tasks across multiple categories
- [ ] Task 1
- [ ] Task 2
... (15 tasks total)

### Phase 3: Another Simple Phase
Tasks: 4 tasks
EOF

# Test validation utility
source /home/benjamin/.config/.claude/lib/expansion-validation.sh
validate_phase_expansion_request "/tmp/test_expansion_plan.md" 2
echo "✓ Validation passed for phase 2"

# Test content extraction
source /home/benjamin/.config/.claude/lib/content-extraction.sh
CONTENT=$(extract_phase_content "/tmp/test_expansion_plan.md" 2)
echo "$CONTENT" | grep -q "Complex Phase"
echo "✓ Content extraction successful"

# Test directory creation
PLAN_DIR=$(create_plan_directory_structure "/tmp/test_expansion_plan.md")
test -d "$PLAN_DIR"
echo "✓ Plan directory created: $PLAN_DIR"

# Test phase file creation
PHASE_FILE=$(create_phase_file "$PLAN_DIR" 2 "Complex Phase" "$CONTENT")
test -f "$PHASE_FILE"
echo "✓ Phase file created: $PHASE_FILE"

# Test parent plan update
update_parent_plan_phase_summary "$PLAN_DIR/test_expansion_plan.md" 2 "Complex Phase" "phase_2_complex_phase.md" 8.5 15
grep -q "\[See: phase_2_complex_phase.md\]" "$PLAN_DIR/test_expansion_plan.md"
echo "✓ Parent plan updated with reference"

# Test metadata updates
update_metadata_structure_level "$PLAN_DIR/test_expansion_plan.md" 1
grep -q "Structure Level.*: 1" "$PLAN_DIR/test_expansion_plan.md"
echo "✓ Structure level updated"

update_expanded_phases_list "$PLAN_DIR/test_expansion_plan.md" 2
grep -q "Expanded Phases:.*\[2\]" "$PLAN_DIR/test_expansion_plan.md"
echo "✓ Expanded phases list updated"

# Test artifact creation
ARTIFACT=$(create_expansion_artifact "specs/artifacts/test_plan" 2 "Phase Expansion" "$PHASE_FILE" "$PLAN_DIR/test_expansion_plan.md" "0→1, [2]" "15 tasks")
test -f "$ARTIFACT"
echo "✓ Artifact created: $ARTIFACT"

# Test complete expansion workflow
expand_phase_to_level1 "/tmp/test_expansion_plan.md" 2 8.5
# Verify: Phase file created, parent updated, metadata updated, artifact created
test -f "$PLAN_DIR/phase_2_complex_phase.md"
grep -q "\[See: phase_2_complex_phase.md\]" "$PLAN_DIR/test_expansion_plan.md"
grep -q "Structure Level.*: 1" "$PLAN_DIR/test_expansion_plan.md"
test -f "specs/artifacts/test_plan/expansion_2.md"
echo "✓ Complete Level 1 expansion workflow successful"

# Cleanup
rm -rf /tmp/test_expansion_plan.md "$PLAN_DIR" specs/artifacts/test_plan
```

#### Expected Outcomes
- All expansion utilities implemented and tested
- Phase content extracted with exact formatting preservation
- Plan directory structure created correctly
- Phase files created with proper metadata
- Parent plans updated with summaries and references
- Metadata updates applied (Structure Level 0→1, Expanded Phases list)
- Expansion artifacts created with all required sections
- Complete expansion workflow functional for Level 1

---

### Stage 3: Implement Level 2 Expansion Logic (Stage → Detailed Files)
**Objective**: Implement logic for expanding high-complexity stages within Level 1 phase files into separate Level 2 stage files.
**Complexity**: High (8/10)
**Estimated Time**: 90-120 minutes

This stage implements the second level of expansion for phases that have stages with complexity >8.0 or >10 tasks.

#### Tasks

- [ ] **Implement stage file creation**
 - Function: `create_stage_file(phase_dir, phase_name, stage_num, stage_name, stage_content)`
  - Sanitize stage name (lowercase, replace spaces with underscores)
  - Generate filename: `stage_{stage_num}_{sanitized_name}.md`
  - Write content to file with proper formatting
  - Add metadata section:
   ```markdown
   ## Metadata
   - **Stage Number**: {stage_num}
   - **Parent Phase**: [{phase_name}.md](../{phase_name}.md)
   - **Structure Level**: Level 2 (Stage Expansion)
   - **Complexity Score**: {from complexity-estimator}
   - **Expansion Reason**: {reason}
   - **Dependencies**: {parse from stage content}
   ```
  - Verify file creation
  - Return: stage file path + file size

- [ ] **Implement phase overview file creation**
 - Function: `create_phase_overview_file(phase_dir, phase_name, phase_num, stages_list)`
  - Generate overview filename: `{phase_name}_overview.md`
  - Create overview content:
   ```markdown
   # Phase {N} Overview

   This phase has been expanded into multiple stages due to high complexity.

   ## Stage Structure
   {list of stages with links}
   - [Stage 1: {Name}](stage_1_{name}.md)
   - [Stage 2: {Name}](stage_2_{name}.md)

   ## Dependencies
   {dependency graph between stages}

   ## Overall Objective
   {phase objective from parent plan}
   ```
  - Write overview file
  - Verify creation
  - Return: overview file path

- [ ] **Implement parent phase update for Level 2 expansion**
 - Function: `update_phase_file_stage_summary(phase_path, stage_num, stage_name, stage_file_relative_path, complexity_score)`
  - Generate stage summary:
   ```markdown
   #### Stage {M}: {Stage Name} [See: {stage_file_relative_path}]

   **Summary**: {1-2 sentence description}
   **Complexity**: {score}/10
   **Status**: Expanded to detailed stage file
   ```
  - Replace detailed stage content with summary in phase file
  - Preserve heading structure
  - Verify replacement
  - Return: success/failure

- [ ] **Implement expanded stages list management**
 - Function: `update_expanded_stages_list(phase_path, stage_num)`
  - Extract current Expanded Stages list for this phase
  - Create new entry if doesn't exist: `Phase {N}: [stage_num]`
  - Append to existing entry: `Phase {N}: [1, 3] → [1, 3, 5]`
  - Update phase file with new list
  - Return: updated stages list
 - Function: `update_main_plan_structure_level_to_2(main_plan_path)`
  - Update Structure Level in main Level 0 plan to 2
  - Verify update applied
  - Return: success/failure

- [ ] **Implement recursive directory structure for Level 2**
 - Function: `create_stage_directory_structure(phase_path)`
  - Extract phase name from path
  - Create subdirectory: `{phase_name}/`
  - Move phase file into subdirectory (if first stage expansion for this phase)
  - Verify structure created
  - Return: new phase directory path

- [ ] **Integrate Level 2 expansion workflow**
 - Create main expansion function: `expand_stage_to_level2(phase_path, stage_num, complexity_score)`
  - STEP 1: Validate request (validate_stage_expansion_request)
  - STEP 2: Extract content (extract_stage_content)
  - STEP 3: Create structure (create_stage_directory_structure + create_stage_file + create_phase_overview if first)
  - STEP 4: Update parent phase (update_phase_file_stage_summary + update_expanded_stages_list)
  - STEP 4: Update main plan (update_main_plan_structure_level_to_2)
  - STEP 4.5: Invoke spec-updater for cross-reference verification
  - STEP 5: Create artifact (create_expansion_artifact for stage)
  - Return: expansion report
 - Handle errors with rollback

- [ ] **Implement expansion depth limiting**
 - Function: `check_expansion_depth(plan_path)`
  - Read Structure Level from plan metadata
  - Return: current_level (0, 1, or 2)
 - Function: `can_expand_further(current_level)`
  - Maximum depth: 2 (Level 0 → 1 → 2)
  - Return: true if level < 2, false otherwise
  - Log warning if expansion requested beyond max depth
 - Integrate depth check into all expansion functions
 - Prevent Level 2 → Level 3 expansion (error message)

#### Testing

```bash
# Create test Level 1 phase file with complex stages
mkdir -p /tmp/test_plan_dir
cat > /tmp/test_plan_dir/phase_2_complex.md <<'EOF'
## Metadata
- **Phase Number**: 2
- **Structure Level**: Level 1
- **Expanded Stages**: []

### Phase 2: Complex Phase

#### Stage 1: Simple Stage
Tasks: 3 tasks

#### Stage 2: Very Complex Stage
**Objective**: High complexity stage with many tasks
Tasks: 15 detailed tasks
- [ ] Task 1
- [ ] Task 2
... (15 tasks total)

#### Stage 3: Another Simple Stage
Tasks: 4 tasks
EOF

# Test stage content extraction
source /home/benjamin/.config/.claude/lib/content-extraction.sh
STAGE_CONTENT=$(extract_stage_content "/tmp/test_plan_dir/phase_2_complex.md" 2)
echo "$STAGE_CONTENT" | grep -q "Very Complex Stage"
echo "✓ Stage content extraction successful"

# Test stage directory creation
STAGE_DIR=$(create_stage_directory_structure "/tmp/test_plan_dir/phase_2_complex.md")
test -d "$STAGE_DIR"
echo "✓ Stage directory created: $STAGE_DIR"

# Test stage file creation
STAGE_FILE=$(create_stage_file "$STAGE_DIR" "phase_2_complex" 2 "Very Complex Stage" "$STAGE_CONTENT")
test -f "$STAGE_FILE"
echo "✓ Stage file created: $STAGE_FILE"

# Test phase overview creation
OVERVIEW=$(create_phase_overview_file "$STAGE_DIR" "phase_2_complex" 2 "1,2,3")
test -f "$OVERVIEW"
grep -q "Stage Structure" "$OVERVIEW"
echo "✓ Phase overview created"

# Test parent phase update
update_phase_file_stage_summary "/tmp/test_plan_dir/phase_2_complex.md" 2 "Very Complex Stage" "stage_2_very_complex_stage.md" 9.2
grep -q "\[See: stage_2_very_complex_stage.md\]" "/tmp/test_plan_dir/phase_2_complex.md"
echo "✓ Parent phase updated with stage reference"

# Test expanded stages list update
update_expanded_stages_list "/tmp/test_plan_dir/phase_2_complex.md" 2
grep -q "Expanded Stages:.*\[2\]" "/tmp/test_plan_dir/phase_2_complex.md"
echo "✓ Expanded stages list updated"

# Test depth limiting
echo "- **Structure Level**: 2" > /tmp/test_depth.md
LEVEL=$(check_expansion_depth "/tmp/test_depth.md")
[[ "$LEVEL" == "2" ]] && echo "✓ Depth detection works"

CAN_EXPAND=$(can_expand_further 2)
[[ "$CAN_EXPAND" == "false" ]] && echo "✓ Depth limiting prevents Level 3 expansion"

# Test complete Level 2 expansion workflow
expand_stage_to_level2 "/tmp/test_plan_dir/phase_2_complex.md" 2 9.2
# Verify: Stage file created, phase updated, overview created, artifact created
test -f "$STAGE_DIR/stage_2_very_complex_stage.md"
grep -q "\[See: stage_2_very_complex_stage.md\]" "/tmp/test_plan_dir/phase_2_complex.md"
test -f "$STAGE_DIR/phase_2_complex_overview.md"
test -f "specs/artifacts/test_plan/expansion_phase2_stage2.md"
echo "✓ Complete Level 2 expansion workflow successful"

# Cleanup
rm -rf /tmp/test_plan_dir /tmp/test_depth.md specs/artifacts/test_plan
```

#### Expected Outcomes
- Stage extraction and file creation working
- Phase subdirectories created for Level 2 expansion
- Phase overview files generated with stage structure
- Parent phase files updated with stage summaries and references
- Expanded Stages lists maintained correctly
- Main plan Structure Level updated to 2
- Expansion depth limited to Level 2 maximum
- Complete Level 2 expansion workflow functional

---

### Stage 4: Implement Parent Plan Update Logic
**Objective**: Implement robust logic for updating parent plans at all levels with summaries, references, and metadata after expansion.
**Complexity**: Medium (7/10)
**Estimated Time**: 60-90 minutes

This stage ensures that when phases or stages are expanded, parent plans are correctly updated with summaries, reference links, and maintained structural integrity.

#### Tasks

- [ ] **Implement summary generation from phase/stage content**
 - Function: `generate_phase_summary(phase_content, max_sentences=2)`
  - Parse phase objective section
  - Extract key points from task list
  - Generate concise summary (1-2 sentences)
  - Include: what will be implemented, why, and key technologies
  - Return: generated summary text
 - Function: `generate_stage_summary(stage_content, max_sentences=2)`
  - Similar to phase summary
  - Focus on stage-specific goals
  - Return: generated summary text

- [ ] **Implement relative path calculation for references**
 - Function: `calculate_relative_path(parent_file_path, child_file_path)`
  - Calculate relative path from parent to child
  - Handle different directory levels (same dir, subdir, parent dir)
  - Return: relative path string for markdown links
 - Examples:
  - Parent: `plans/027_auth.md`, Child: `plans/027_auth/phase_2.md` → `027_auth/phase_2.md`
  - Parent: `plans/027_auth/phase_2.md`, Child: `plans/027_auth/phase_2/stage_1.md` → `phase_2/stage_1.md`

- [ ] **Implement markdown content replacement**
 - Function: `replace_phase_with_summary(plan_path, phase_num, summary_block)`
  - Identify phase section (### Phase {N}: to next phase or EOF)
  - Extract phase heading
  - Replace entire phase content with summary block
  - Preserve heading line
  - Use awk/sed for precise replacement
  - Verify replacement successful (check line counts before/after)
  - Return: success/failure + modified content preview
 - Function: `replace_stage_with_summary(phase_path, stage_num, summary_block)`
  - Similar to phase replacement but for stages (#### Stage headings)
  - Preserve stage heading
  - Return: success/failure

- [ ] **Implement complexity metadata injection**
 - Function: `inject_complexity_metadata(file_path, item_type, item_num, complexity_score, task_count, file_count)`
  - Add complexity metadata to phase/stage heading:
   ```markdown
   ### Phase {N}: {Name}
   **Complexity**: {score}/10 ({rating})
   **Tasks**: {count} tasks
   **Files Referenced**: {count} files
   **Expansion Status**: Expanded to Level {N}
   ```
  - Insert after heading, before summary
  - Use appropriate rating: Low (0-5), Medium (5-8), High (8-10), Very High (10+)
  - Return: success/failure

- [ ] **Implement expansion history tracking**
 - Function: `add_expansion_history_entry(plan_path, item_type, item_num, complexity_score, reason)`
  - Create or update Expansion History section in metadata:
   ```markdown
   ## Expansion History
   - **{ISO_DATE}**: Phase {N} expanded to Level 1 (complexity {score}/10, reason: {reason})
   - **{ISO_DATE}**: Phase {N} Stage {M} expanded to Level 2 (complexity {score}/10, reason: {reason})
   ```
  - Append to existing history (chronological order)
  - Create section if doesn't exist
  - Return: updated history content

- [ ] **Implement bidirectional linking**
 - Function: `add_parent_link_to_child(child_file_path, parent_file_path, parent_type, parent_num)`
  - Add parent reference in child file metadata:
   ```markdown
   ## Metadata
   - **Parent {Type}**: [{parent_name}.md]({relative_path_to_parent})
   ```
  - Use correct parent type: Plan, Phase, Stage
  - Calculate relative path for link
  - Insert in metadata section
  - Return: success/failure
 - Ensure: Parent → Child link (in summary) AND Child → Parent link (in metadata)

- [ ] **Implement parent update transaction handling**
 - Function: `update_parent_with_rollback(parent_path, update_operations[])`
  - Create backup of parent file before modifications
  - Execute all update operations (summary replacement, metadata updates, link additions)
  - Verify all operations successful
  - If any operation fails: rollback to backup
  - If all succeed: delete backup, commit changes
  - Return: transaction result (success/failure) + operations log
 - Supports: Multiple updates to same parent in single transaction

- [ ] **Add parent update validation**
 - Function: `validate_parent_update(parent_path)`
  - Check all markdown links are valid (no broken references)
  - Verify Structure Level metadata consistent with actual structure
  - Verify Expanded Phases/Stages lists match actual expanded items
  - Check no duplicate entries in metadata lists
  - Verify all summaries have corresponding child files
  - Return: validation report with any issues found

#### Testing

```bash
# Test summary generation
cat > /tmp/test_phase.md <<'EOF'
### Phase 2: Backend Implementation
**Objective**: Implement backend authentication system with JWT tokens
Tasks: Database schema, API endpoints, token handling, password hashing
EOF

source /home/benjamin/.config/.claude/lib/parent-updates.sh
SUMMARY=$(generate_phase_summary "$(cat /tmp/test_phase.md)")
echo "$SUMMARY" | grep -q "authentication"
echo "✓ Summary generation works"

# Test relative path calculation
REL_PATH=$(calculate_relative_path "plans/027_auth.md" "plans/027_auth/phase_2.md")
[[ "$REL_PATH" == "027_auth/phase_2.md" ]] && echo "✓ Relative path calculation correct"

# Test content replacement
cat > /tmp/test_plan.md <<'EOF'
### Phase 1: Setup
Content here

### Phase 2: Implementation
Long detailed content
Many lines
Many tasks

### Phase 3: Testing
More content
EOF

SUMMARY_BLOCK="**Summary**: Brief summary\n**Complexity**: 8/10\n[See: phase_2.md]"
replace_phase_with_summary "/tmp/test_plan.md" 2 "$SUMMARY_BLOCK"
grep -q "\[See: phase_2.md\]" "/tmp/test_plan.md"
echo "✓ Content replacement works"

# Test complexity metadata injection
inject_complexity_metadata "/tmp/test_plan.md" "phase" 2 8.5 15 12
grep -q "Complexity.*8.5/10" "/tmp/test_plan.md"
echo "✓ Complexity metadata injected"

# Test expansion history tracking
add_expansion_history_entry "/tmp/test_plan.md" "phase" 2 8.5 "High task count"
grep -q "Expansion History" "/tmp/test_plan.md"
grep -q "Phase 2 expanded" "/tmp/test_plan.md"
echo "✓ Expansion history tracked"

# Test bidirectional linking
cat > /tmp/child_phase.md <<'EOF'
## Metadata
- **Phase Number**: 2
EOF

add_parent_link_to_child "/tmp/child_phase.md" "/tmp/test_plan.md" "Plan" "027"
grep -q "Parent Plan:" "/tmp/child_phase.md"
echo "✓ Bidirectional links created"

# Test transaction handling with rollback
cp /tmp/test_plan.md /tmp/test_plan_backup.md
RESULT=$(update_parent_with_rollback "/tmp/test_plan.md" "replace_phase 2" "update_metadata")
echo "$RESULT" | grep -q "success"
echo "✓ Transaction handling works"

# Test validation
validate_parent_update "/tmp/test_plan.md"
echo "✓ Parent update validation works"

# Cleanup
rm /tmp/test_*.md
```

#### Expected Outcomes
- Summary generation creates concise 1-2 sentence descriptions
- Relative path calculation accurate for all directory levels
- Content replacement preserves structure and updates correctly
- Complexity metadata added to all expanded items
- Expansion history tracked chronologically
- Bidirectional linking (parent ↔ child) functional
- Transaction handling with rollback prevents partial updates
- Validation catches broken links and inconsistent metadata

---

### Stage 5: Integrate Recursive Complexity Evaluation
**Objective**: Implement recursive complexity re-evaluation after each expansion to determine if further expansion needed, with loop prevention.
**Complexity**: Medium (7/10)
**Estimated Time**: 60-90 minutes

This stage ensures that after expanding a phase, we re-analyze the expanded file to see if any stages within it also need expansion.

#### Tasks

- [ ] **Implement post-expansion complexity re-evaluation**
 - Function: `reevaluate_complexity_after_expansion(expanded_file_path, expansion_level)`
  - Invoke complexity-estimator agent on expanded file
  - Parse complexity scores for all phases (if Level 1) or stages (if Level 2)
  - Compare scores to expansion threshold (default 8.0)
  - Identify items exceeding threshold
  - Return: list of items needing further expansion + complexity report
 - Integration: Call after every expansion operation

- [ ] **Implement expansion recommendation engine**
 - Function: `generate_expansion_recommendations(complexity_report, current_level, max_level=2)`
  - Parse complexity report
  - Filter items by expansion threshold (from CLAUDE.md config)
  - Check current level < max level
  - Generate recommendations:
   ```yaml
   recommendations:
    - item_type: "phase" | "stage"
     item_num: N
     current_complexity: X.X
     threshold: 8.0
     reason: "High task count (15 tasks)"
     expand: true
   ```
  - Return: recommendations list
 - Respect max depth: No recommendations if level == 2

- [ ] **Implement expansion loop prevention**
 - Function: `track_expansion_attempt(plan_path, item_type, item_num)`
  - Create expansion tracking file: `.claude/data/expansion_tracking.json`
  - Record: plan path, item type, item num, timestamp, attempt count
  - Increment attempt count for duplicate expansion requests
  - Return: current attempt count
 - Function: `check_expansion_loop(plan_path, item_type, item_num, max_attempts=2)`
  - Query expansion tracking
  - Check attempt count < max_attempts
  - Return: can_expand (true/false) + warning message if loop detected
 - Integrate into expansion validation

- [ ] **Implement recursive expansion orchestration**
 - Function: `recursive_expand_plan(plan_path, complexity_threshold=8.0, max_depth=2)`
  - Initialize: depth = 0, pending_expansions = []
  - While pending_expansions not empty AND depth < max_depth:
   1. Evaluate complexity of current plan/phase
   2. Generate expansion recommendations
   3. For each recommendation:
     - Check expansion loop prevention
     - If safe: expand item
     - Re-evaluate expanded item
     - Add new recommendations to pending_expansions
   4. Increment depth
  - Return: expansion summary (items expanded, depth reached, final structure)
 - Prevents infinite loops with max_depth limit
 - Tracks all expansions in single recursive session

- [ ] **Implement expansion threshold configuration reading**
 - Function: `read_expansion_config_from_claude_md(claude_md_path)`
  - Parse CLAUDE.md file
  - Extract adaptive_planning_config section
  - Read thresholds:
   - expansion_threshold (default 8.0)
   - task_count_threshold (default 10)
   - file_reference_threshold (default 10)
  - Return: config object with thresholds
 - Use config in complexity evaluation and recommendation generation

- [ ] **Implement expansion decision logging**
 - Function: `log_expansion_decision(plan_path, item, decision, reason)`
  - Log file: `.claude/data/logs/expansion-decisions.log`
  - Format: `{timestamp} | {plan_path} | {item} | {decision} | {reason}`
  - Decisions: EXPAND, SKIP_THRESHOLD, SKIP_DEPTH, SKIP_LOOP
  - Examples:
   - `2025-10-21T10:30:00Z | 027_auth.md | phase_2 | EXPAND | complexity 8.5 > threshold 8.0`
   - `2025-10-21T10:31:00Z | phase_2.md | stage_1 | SKIP_DEPTH | max depth 2 reached`
  - Return: log entry confirmation
 - Enables debugging of expansion decisions

- [ ] **Add expansion summary reporting**
 - Function: `generate_expansion_summary_report(plan_path, expansions_performed)`
  - Create summary report:
   ```markdown
   # Expansion Summary

   ## Plan: {plan_path}

   ## Expansions Performed
   - Phase 2: Expanded to Level 1 (complexity 8.5, 15 tasks)
    - Stage 1: Expanded to Level 2 (complexity 9.2, 12 tasks)

   ## Final Structure
   - Structure Level: 2
   - Expanded Phases: [2, 4]
   - Expanded Stages: Phase 2: [1], Phase 4: [2, 3]

   ## Artifacts Created
   - specs/artifacts/027_auth/expansion_2.md
   - specs/artifacts/027_auth/expansion_phase2_stage1.md

   ## Recommendations
   - No further expansion needed (all items below threshold)
   ```
  - Save report to: `specs/artifacts/{plan_name}/expansion_summary.md`
  - Return: report path

#### Testing

```bash
# Create test plan with nested complexity
cat > /tmp/test_nested_plan.md <<'EOF'
## Metadata
- **Structure Level**: 0
- **Expanded Phases**: []

### Phase 1: Simple
Tasks: 3

### Phase 2: Complex (will expand to L1 with complex stages)
Tasks: 15
Stages will include high-complexity backend and integration stages

### Phase 3: Simple
Tasks: 4
EOF

# Test complexity re-evaluation after expansion
source /home/benjamin/.config/.claude/lib/recursive-expansion.sh
expand_phase_to_level1 "/tmp/test_nested_plan.md" 2 8.5
COMPLEXITY=$(reevaluate_complexity_after_expansion "/tmp/test_nested_plan/phase_2_complex.md" 1)
echo "$COMPLEXITY" | grep -q "stage"
echo "✓ Post-expansion re-evaluation works"

# Test expansion recommendations
RECOMMENDATIONS=$(generate_expansion_recommendations "$COMPLEXITY" 1 2)
echo "$RECOMMENDATIONS" | grep -q "expand: true"
echo "✓ Expansion recommendations generated"

# Test loop prevention
track_expansion_attempt "/tmp/test_nested_plan.md" "phase" 2
track_expansion_attempt "/tmp/test_nested_plan.md" "phase" 2
CAN_EXPAND=$(check_expansion_loop "/tmp/test_nested_plan.md" "phase" 2 2)
[[ "$CAN_EXPAND" == "false" ]] && echo "✓ Expansion loop detected and prevented"

# Test recursive expansion orchestration
SUMMARY=$(recursive_expand_plan "/tmp/test_nested_plan.md" 8.0 2)
echo "$SUMMARY" | grep -q "depth reached: 2"
echo "✓ Recursive expansion works with depth limit"

# Test configuration reading
cat > /tmp/test_claude.md <<'EOF'
## Adaptive Planning Configuration
- **Expansion Threshold**: 7.0
- **Task Count Threshold**: 8
EOF

CONFIG=$(read_expansion_config_from_claude_md "/tmp/test_claude.md")
echo "$CONFIG" | grep -q "7.0"
echo "✓ Configuration reading works"

# Test expansion decision logging
log_expansion_decision "/tmp/test_nested_plan.md" "phase_2" "EXPAND" "complexity 8.5 > threshold 8.0"
grep -q "phase_2.*EXPAND" ".claude/data/logs/expansion-decisions.log"
echo "✓ Expansion decisions logged"

# Test expansion summary report
REPORT=$(generate_expansion_summary_report "/tmp/test_nested_plan.md" "phase_2,phase_2_stage_1")
test -f "$REPORT"
grep -q "Expansions Performed" "$REPORT"
echo "✓ Expansion summary report generated"

# Cleanup
rm -rf /tmp/test_nested_plan* /tmp/test_claude.md
```

#### Expected Outcomes
- Complexity re-evaluated after each expansion
- Expansion recommendations generated based on re-evaluation
- Loop prevention stops repeated expansion attempts (max 2)
- Recursive expansion orchestrates multi-level expansions automatically
- Configuration read from CLAUDE.md for thresholds
- Expansion decisions logged for debugging
- Summary reports generated showing all expansions performed

---

### Stage 6: Add Expansion Phase to orchestrate.md
**Objective**: Integrate the expansion workflow into the /orchestrate command as Phase 2.5 (Expansion), invoked after complexity evaluation in Phase 2 (Planning).
**Complexity**: Medium (6/10)
**Estimated Time**: 45-60 minutes

This final stage adds the expansion orchestration to the /orchestrate workflow, ensuring plans are automatically expanded when complexity thresholds exceeded.

#### Tasks

- [ ] **Add Phase 2.5 section to orchestrate.md**
 - Insert new phase between Planning (Phase 2) and Implementation (Phase 3)
 - Phase heading: `## Phase 2.5: Plan Expansion (Conditional)`
 - Mark as conditional: Only runs if complexity evaluation found items exceeding threshold
 - Document phase objective: Expand high-complexity phases/stages to hierarchical structure

- [ ] **Document expansion trigger logic**
 - Add conditional logic:
  ```markdown
  ## Phase 2.5: Plan Expansion (Conditional)

  **Trigger**: This phase runs ONLY if Phase 2 (Planning) complexity evaluation identified phases with:
  - Complexity score > 8.0 (expansion_threshold from CLAUDE.md)
  - OR task count > 10 (task_count_threshold from CLAUDE.md)

  **Skip Condition**: If no phases exceed thresholds, skip to Phase 3 (Implementation)
  ```
 - Reference complexity report from Phase 2

- [ ] **Add expansion-specialist agent invocation**
 - Document Task tool invocation:
  ```markdown
  ### Invoke expansion-specialist

  Use Task tool (NOT SlashCommand) to invoke expansion-specialist agent:

  Task {
   subagent_type: "general-purpose"
   description: "Expand high-complexity phases based on complexity analysis"
   prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/expansion-specialist.md

    You are acting as an Expansion Specialist.

    EXPANSION TASK: Recursive Plan Expansion

    CONTEXT:
    - Plan Path: {plan_path from Phase 2}
    - Complexity Report: {complexity_report from Phase 2}
    - Phases to expand: {list of phase numbers exceeding threshold}
    - Expansion threshold: {threshold from CLAUDE.md config}
    - Max depth: 2 (Level 0 → 1 → 2)

    YOUR TASK:
    1. For each phase in expansion list:
      - Expand phase to Level 1 (separate file with stages)
      - Re-evaluate complexity of expanded phase
      - If any stages exceed threshold, expand to Level 2
    2. Respect max depth limit (no Level 3 expansion)
    3. Create expansion artifacts for each operation
    4. Update parent plans with summaries and references
    5. Maintain cross-reference integrity (invoke spec-updater)
    6. Return expansion summary report

    REQUIRED OUTPUT:
    - Files created: List of all phase/stage files
    - Artifacts created: List of all expansion artifacts
    - Final structure level: {0|1|2}
    - Expansion summary path: {path to expansion_summary.md}
  }
  ```

- [ ] **Add expansion result extraction**
 - Document how to parse expansion-specialist response:
  ```markdown
  ### Extract Expansion Results

  From expansion-specialist response, extract:
  - `files_created`: List of new phase/stage files
  - `final_structure_level`: Updated structure level (1 or 2)
  - `expansion_summary_path`: Path to expansion summary report
  - `expansions_performed`: Count of expansions

  Update workflow state:
  - `plan_structure_level`: {final_structure_level}
  - `plan_is_hierarchical`: true if level > 0
  ```

  **MANDATORY VERIFICATION CHECKPOINT:**
  ```bash
  # Verify expansion-specialist created required artifacts
  EXPANSION_SUMMARY="${expansion_summary_path}"

  if [ ! -f "$EXPANSION_SUMMARY" ]; then
    echo "ERROR: Expansion summary not created at $EXPANSION_SUMMARY"
    echo "FALLBACK: expansion-specialist failed - creating minimal expansion summary"

    # Create fallback expansion summary
    cat > "$EXPANSION_SUMMARY" <<'EOF'
# Expansion Summary

## Summary
Minimal expansion summary created by fallback mechanism.

## Files Created
- (Manual expansion required - agent failed)

## Recommendation
Review complexity report and manually expand high-complexity phases.
EOF
  fi

  # Verify phase/stage files from files_created list
  for phase_file in "${files_created[@]}"; do
    if [ ! -f "$phase_file" ]; then
      echo "WARNING: Expected phase/stage file missing: $phase_file"
      echo "FALLBACK: Creating minimal phase file"

      # Extract phase number from filename
      phase_num=$(basename "$phase_file" | sed 's/phase_\([0-9]*\).*/\1/')

      # Create minimal phase file
      cat > "$phase_file" <<EOF
# Phase $phase_num

## Overview
Minimal phase file created by fallback mechanism.
Manual expansion required.

## Tasks
- [ ] Review complexity analysis
- [ ] Manually break down this phase
EOF
    fi
  done

  echo "Verification complete: Expansion artifacts validated"
  ```
  End verification. Proceed only if expansion summary exists.

- [ ] **Add expansion validation**
 - Document validation steps after expansion:
  ```markdown
  ### Validate Expansion Results

  1. Verify all expected phase/stage files exist
  2. Verify parent plan updated with references
  3. Verify Structure Level metadata updated
  4. Verify Expanded Phases/Stages lists accurate
  5. Verify all expansion artifacts created
  6. Read expansion summary report for overview
  ```

- [ ] **Update Phase 3 (Implementation) to handle hierarchical plans**
 - Document how implementer-coordinator detects hierarchical structure:
  ```markdown
  ## Phase 3: Implementation

  ### Detect Plan Structure

  Before invoking implementer-coordinator, detect plan structure:
  - If `plan_structure_level` == 0: Plan is flat (all phases inline)
  - If `plan_structure_level` == 1: Plan has separate phase files
  - If `plan_structure_level` == 2: Plan has separate phase and stage files

  Pass structure information to implementer-coordinator for proper traversal.
  ```

- [ ] **Add expansion phase to workflow diagram**
 - Update orchestrate.md workflow diagram to include Phase 2.5
 - Show conditional branching (skip if no expansion needed)
 - Example:
  ```
  Phase 0: Location Determination
   ↓
  Phase 1: Research (parallel agents)
   ↓
  Phase 2: Planning + Complexity Evaluation
   ↓
  Phase 2.5: Expansion (conditional) ← NEW
   ↓
  Phase 3: Implementation (wave-based)
   ...
  ```

- [ ] **Update TodoWrite task list in orchestrate.md**
 - Add expansion phase to orchestrate.md task list:
  ```markdown
  - [ ] Phase 2: Planning complete
  - [ ] Phase 2.5: Expansion (if needed)
  - [ ] Phase 3: Implementation started
  ```

#### Testing

```bash
# Test orchestrate.md has expansion phase
grep -q "Phase 2.5: Plan Expansion" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Expansion phase added to orchestrate.md"

# Test expansion trigger logic documented
grep -q "Trigger.*complexity.*> 8.0" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Expansion trigger logic documented"

# Test expansion-specialist invocation pattern present
grep -q "expansion-specialist.md" /home/benjamin/.config/.claude/commands/orchestrate.md
grep -q "Task tool.*NOT SlashCommand" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Expansion-specialist invocation documented"

# Test expansion result extraction documented
grep -q "Extract Expansion Results" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Result extraction documented"

# Test validation steps present
grep -q "Validate Expansion Results" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Validation steps documented"

# Test hierarchical plan handling in Phase 3
grep -q "Detect Plan Structure" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Hierarchical plan handling documented"

# Test workflow diagram updated
grep -q "Phase 2.5.*Expansion" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Workflow diagram updated"

# End-to-end test: Run orchestrate with complex feature
# /orchestrate "Implement authentication system with OAuth, JWT, database, API endpoints, frontend integration, testing, and documentation"
# Expected: Phase 2 creates plan, Phase 2.5 expands high-complexity phases, Phase 3 implements hierarchical plan
# Verify: Plan directory created, phase files created, parent plan updated, expansion artifacts created
```

#### Expected Outcomes
- Phase 2.5 (Expansion) added to orchestrate.md workflow
- Expansion trigger logic clearly documented (conditional execution)
- expansion-specialist agent invocation using Task tool (NOT SlashCommand)
- Expansion result extraction and validation documented
- Phase 3 (Implementation) updated to handle hierarchical plans
- Workflow diagram includes expansion phase
- End-to-end orchestrate workflow functional with expansion

---

## Phase Completion Checklist

After all 6 stages are complete:

- [ ] **Verify all stage tasks completed**
 - [ ] Stage 1: expansion-specialist agent template created
 - [ ] Stage 2: Level 1 expansion logic implemented and tested
 - [ ] Stage 3: Level 2 expansion logic implemented and tested
 - [ ] Stage 4: Parent plan update logic implemented and tested
 - [ ] Stage 5: Recursive complexity evaluation integrated
 - [ ] Stage 6: Expansion phase added to orchestrate.md

- [ ] **Run comprehensive integration tests**
 - [ ] Test Level 1 expansion (Phase → Stages)
 - [ ] Test Level 2 expansion (Stage → Detailed Files)
 - [ ] Test recursive expansion (L0 → L1 → L2 in one operation)
 - [ ] Test expansion loop prevention (max 2 attempts)
 - [ ] Test depth limiting (no Level 3 expansion)
 - [ ] Test complete orchestrate workflow with expansion

- [ ] **Verify all artifacts created**
 - [ ] expansion-specialist.md agent file
 - [ ] Expansion utilities in .claude/lib/
 - [ ] Expansion tracking in .claude/data/
 - [ ] Expansion decision logs
 - [ ] Expansion artifacts for test plans

- [ ] **Update documentation**
 - [ ] Update .claude/agents/README.md with expansion-specialist
 - [ ] Update .claude/docs/workflows/adaptive-planning-guide.md with expansion details
 - [ ] Add expansion examples to documentation
 - [ ] Document expansion configuration in CLAUDE.md

- [ ] **Update this phase file**
 - [ ] Mark all stage tasks as [x] complete
 - [ ] Add completion timestamp to metadata
 - [ ] Update parent plan (080_orchestrate_enhancement.md)
 - [ ] Update Phase 4 summary in parent plan with completion status

- [ ] **Create git commit**
 - [ ] Commit message: `feat(080): complete Phase 4 - Plan Expansion (Hierarchical Structure and Automated Expansion)`
 - [ ] Include all modified files (agent, utilities, orchestrate.md)
 - [ ] Include commit hash in completion report

- [ ] **Create phase checkpoint**
 - [ ] Save checkpoint to .claude/data/checkpoints/080_phase_4_complete.json
 - [ ] Include: completion timestamp, files created, tests passed, next phase

- [ ] **Invoke spec-updater**
 - [ ] Update cross-references between this phase and parent plan
 - [ ] Update 080_orchestrate_enhancement summary with Phase 4 completion
 - [ ] Validate all links functional

## Dependencies

**Depends On**:
- Phase 3 (Complexity Evaluation): Provides complexity scores and expansion recommendations

**Blocks**:
- Phase 5 (Wave-Based Implementation): Needs hierarchical plan structure for wave detection
- Phase 7 (Progress Tracking): Needs plan hierarchy for checkbox propagation

## Notes

### Key Design Decisions

1. **Two-Level Expansion Maximum**: Limited to Level 0 → 1 → 2 to prevent over-expansion and maintain navigability
2. **Recursive Evaluation**: After each expansion, re-evaluate to catch nested complexity
3. **Loop Prevention**: Max 2 expansion attempts per item prevents infinite expansion loops
4. **Transaction-Based Updates**: Parent plan updates use transaction pattern with rollback for atomicity
5. **spec-updater Integration**: STEP 4.5 ensures cross-references always verified after expansion

### Integration with Other Phases

- **Phase 2 (Planning)**: Receives complexity report, triggers expansion if thresholds exceeded
- **Phase 3 (Complexity Evaluation)**: Provides scores that determine expansion decisions
- **Phase 5 (Wave-Based Implementation)**: Reads hierarchical plan structure created by expansion
- **Phase 7 (Progress Tracking)**: Uses plan hierarchy for checkbox propagation

### Context Reduction

Expansion maintains <30% context usage by:
- Returning metadata-only summaries (not full expanded content)
- Creating artifacts with detailed results (read on-demand)
- Using [Forward Message Pattern](../../../docs/concepts/patterns/forward-message.md) (no re-summarization)
- Pruning expansion tracking data after completion

### Rollback Strategy

If expansion fails:
1. Restore parent plan from backup (created before expansion)
2. Delete partially created phase/stage files
3. Revert metadata changes (Structure Level, Expanded lists)
4. Log failure in expansion-decisions.log
5. Return error report to orchestrator for user notification
