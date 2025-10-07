---
allowed-tools: Read, Write, Edit, Bash, Glob
argument-hint: <phase-path> <stage-num>
description: Expand a stage to a separate file with optional agent-powered research (Level 1 → Level 2)
command-type: workflow
---

# Expand Stage to Separate File

I'll expand a stage from inline content in a phase file to a separate file, optionally using agent-powered research for complex stages to create detailed specifications.

## Arguments

- `$1` (required): Path to phase file or directory (e.g., `specs/plans/025_feature/phase_2_impl.md` or `specs/plans/025_feature/phase_2_impl/`)
- `$2` (required): Stage number to expand (e.g., `1`)

## Objective

Progressive stage expansion: Extract stage content from phase file to dedicated stage file, optionally using agent research for complex stages to create comprehensive 200-400 line specifications, and update three-way metadata (stage → phase → main plan).

**Operations**:
- Detect stage complexity using quantitative thresholds
- If complex: Invoke agent for research and synthesis
- Extract stage content from phase file
- Create phase directory if first expansion (Level 1 → 2)
- Write detailed stage file (200-400 lines for complex stages)
- Update three-way metadata (phase + main plan)
- Provide implementation guidance

## Process

### 1. Analyze Current Structure

Determine the current plan structure and locate files.

```bash
# Normalize phase path (accept both file and directory)
if [[ -f "$phase_path" ]] && [[ "$phase_path" == *.md ]]; then
  # File path provided - extract base name
  phase_file="$phase_path"
  phase_dir=$(dirname "$phase_file")
  phase_base=$(basename "$phase_file" .md)
elif [[ -d "$phase_path" ]]; then
  # Directory provided - locate phase file
  phase_base=$(basename "$phase_path")
  phase_file="$phase_path/$phase_base.md"
  phase_dir="$phase_path"

  [[ ! -f "$phase_file" ]] && error "Phase file not found: $phase_file"
else
  error "Invalid phase path: $phase_path"
fi

# Locate main plan
plan_dir=$(dirname "$phase_dir")
plan_base=$(basename "$plan_dir")

# Check if plan is at root or in subdirectory
if [[ -f "$plan_dir.md" ]]; then
  # Plan is Level 0 (single file)
  main_plan="$plan_dir.md"
elif [[ -f "$plan_dir/$plan_base.md" ]]; then
  # Plan is Level 1 (phase expansion)
  main_plan="$plan_dir/$plan_base.md"
else
  error "Cannot locate main plan file for: $plan_dir"
fi

# Extract phase number from filename
phase_num=$(echo "$phase_base" | grep -oP 'phase_\K\d+' | head -1)
[[ -z "$phase_num" ]] && error "Cannot extract phase number from: $phase_base"

echo "Phase file: $phase_file"
echo "Phase number: $phase_num"
echo "Main plan: $main_plan"

# Detect current structure level
source .claude/lib/parse-adaptive-plan.sh
structure_level=$(detect_structure_level "$(dirname "$main_plan")")

# Determine if this is first stage expansion
if [[ -d "$phase_dir/$phase_base" ]]; then
  is_first_expansion=false
  target_dir="$phase_dir/$phase_base"
  echo "Existing phase directory: $target_dir (Level 2)"
else
  is_first_expansion=true
  target_dir="$phase_dir/$phase_base"
  echo "First stage expansion - will create directory: $target_dir (Level 1 → 2)"
fi
```

**Validation**:
- [ ] Phase file exists and is readable
- [ ] Main plan file exists
- [ ] Phase number extracted correctly
- [ ] Structure level detected

### 2. Extract and Analyze Stage Content

Extract the stage content and determine complexity.

```bash
# Extract stage section from phase file
# Stage headings are #### (4 hashes)
stage_content=$(awk -v stage="$stage_num" '
  BEGIN { in_stage = 0; level = 0 }

  /^#### Stage / {
    # Check if this is our stage
    if ($3 == stage ":" || $3 == stage) {
      in_stage = 1
      match($0, /^#+/, m)
      level = length(m[0])
      print
      next
    } else if (in_stage) {
      # Hit next stage, stop
      exit
    }
  }

  in_stage && /^###/ {
    # Hit same-level or higher heading, stop
    match($0, /^#+/, m)
    if (length(m[0]) <= level) {
      exit
    }
  }

  in_stage { print }
' "$phase_file")

[[ -z "$stage_content" ]] && error "Stage $stage_num not found in phase file"

# Extract stage name from heading
stage_heading=$(echo "$stage_content" | head -1)
stage_name=$(echo "$stage_heading" | sed 's/^#### Stage [0-9]*: *//' | sed 's/^#### Stage [0-9]* *//')
stage_name_slug=$(echo "$stage_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//')

echo "Stage heading: $stage_heading"
echo "Stage name: $stage_name"

# Check if already expanded
if [[ -f "$target_dir/stage_${stage_num}_${stage_name_slug}.md" ]]; then
  error "Stage $stage_num already expanded: $target_dir/stage_${stage_num}_${stage_name_slug}.md"
fi
```

**Complexity Analysis**:

```bash
# === COMPLEXITY DETECTION ===
echo ""
echo "=== Stage Complexity Analysis ==="

# Count implementation steps (lines starting with task markers or numbered items)
implementation_count=$(echo "$stage_content" | grep -c '^\s*[-*] \|^[0-9]\+\.' || echo 0)

# Count file references (lines with file paths or file:line patterns)
file_refs=$(echo "$stage_content" | grep -oP '`[^`]*\.(lua|sh|md|txt|json|yaml|toml|js|ts|py|go|rs)`|[a-zA-Z0-9_/-]+\.(lua|sh|md|txt|json|yaml|toml|js|ts|py|go|rs):?\d*' | sort -u | wc -l)

# Count unique directories referenced
unique_dirs=$(echo "$stage_content" | grep -oP '[a-zA-Z0-9_/-]+/' | sed 's|/[^/]*$||' | sort -u | wc -l)

# Check for complexity keywords
has_complex_keywords=$(echo "$stage_content" | grep -ciE 'parallel|concurrent|distributed|integration|coordina' || echo 0)

# Word count
word_count=$(echo "$stage_content" | wc -w)

echo "Implementation steps: $implementation_count"
echo "File references: $file_refs"
echo "Unique directories: $unique_dirs"
echo "Complex keywords: $has_complex_keywords"
echo "Word count: $word_count"

# === COMPLEXITY THRESHOLD (Stage-Level) ===
# Stages are simpler than phases, so lower thresholds:
# - >3 implementation steps (vs >5 for phases)
# - ≥8 file references (vs ≥10 for phases)
# - >1 unique directory
# - Has complexity keywords

is_complex=false
complexity_reasons=()

if [[ $implementation_count -gt 3 ]]; then
  is_complex=true
  complexity_reasons+=("$implementation_count implementation steps (>3)")
fi

if [[ $file_refs -ge 8 ]]; then
  is_complex=true
  complexity_reasons+=("$file_refs file references (≥8)")
fi

if [[ $unique_dirs -gt 1 ]]; then
  is_complex=true
  complexity_reasons+=("$unique_dirs directories (>1)")
fi

if [[ $has_complex_keywords -gt 0 ]]; then
  is_complex=true
  complexity_reasons+=("complexity keywords present")
fi

if [[ "$is_complex" == true ]]; then
  echo ""
  echo "✓ Stage is COMPLEX (agent research recommended)"
  echo "  Reasons: ${complexity_reasons[*]}"
  echo ""
else
  echo ""
  echo "✓ Stage is SIMPLE (direct expansion sufficient)"
  echo ""
fi
```

**Extraction**:
- Parse stage section from phase file
- Extract stage name and create slug
- Analyze complexity using quantitative thresholds

### 3. Agent Research (Complex Stages Only)

If stage is complex, invoke agent for research and synthesis.

```bash
if [[ "$is_complex" == true ]]; then
  echo "=== Agent Research Phase ==="
  echo "Stage complexity warrants detailed research and specification."
  echo ""

  # Prepare research context
  cat > /tmp/stage_context.$$.md <<EOF
# Stage Expansion Research Context

## Stage Information
- **Plan**: $plan_base
- **Phase**: Phase $phase_num - $phase_name
- **Stage**: Stage $stage_num - $stage_name
- **Complexity**: $( IFS=", "; echo "${complexity_reasons[*]}" )

## Current Stage Content

$stage_content

## Research Objectives

Your task is to research this stage and create a comprehensive 200-400 line implementation specification.

### Focus Areas

1. **File Analysis**: Identify all files mentioned or implied by this stage
   - Use Glob to find relevant files
   - Read key files to understand current implementation
   - Document file structure and dependencies

2. **Implementation Details**: Expand each task into concrete steps
   - Break down high-level tasks into specific actions
   - Provide file:line references for code locations
   - Include code examples where helpful

3. **Dependencies**: Identify prerequisites and order
   - What must be done first?
   - What can run in parallel?
   - What external dependencies exist?

4. **Testing Strategy**: Define how to validate this stage
   - Unit tests needed
   - Integration tests needed
   - Manual verification steps

5. **Risk Assessment**: Identify potential issues
   - What could go wrong?
   - What are the edge cases?
   - What backward compatibility concerns exist?

### Output Format

Create a detailed markdown document with:

- **Objective**: Clear 2-3 sentence objective
- **Implementation Steps**: Numbered, detailed steps (200-400 lines total)
- **File References**: Specific file:line references
- **Code Examples**: Concrete code snippets
- **Testing Plan**: Specific tests to implement
- **Dependencies**: Explicit prerequisites
- **Risks**: Potential issues and mitigations

### Quality Standards

- Be specific: No vague "implement X" - say HOW to implement X
- Be concrete: Include file paths, line numbers, function names
- Be complete: Cover all tasks mentioned in original stage
- Be practical: Focus on actionable implementation details

---

Please research this stage and return a comprehensive implementation specification.
EOF

  # Invoke general-purpose agent with research focus
  echo "Invoking agent for stage research..."
  echo "Target: 200-400 line detailed specification"
  echo ""

  # Use Task tool to launch agent
  # Agent type: general-purpose (supports Read, Glob, Grep for research)
  research_result=$(cat /tmp/stage_context.$$.md | timeout 300 claude-agent-invoke general-purpose)

  # Check if agent succeeded
  if [[ $? -eq 0 ]] && [[ -n "$research_result" ]]; then
    echo "✓ Agent research completed"

    # Validate research quality
    research_word_count=$(echo "$research_result" | wc -w)
    echo "  Research output: $research_word_count words"

    if [[ $research_word_count -lt 300 ]]; then
      echo "⚠ Warning: Research output is short (<300 words). May need manual enhancement."
    fi

    # Store research for synthesis
    stage_spec="$research_result"

  else
    echo "⚠ Agent research failed or timed out"
    echo "  Falling back to direct expansion"
    is_complex=false
    stage_spec="$stage_content"
  fi

  # Cleanup
  rm -f /tmp/stage_context.$$.md

else
  # Simple stage - use original content
  stage_spec="$stage_content"
fi
```

**Agent Research**:
- Invoke general-purpose agent with research context
- Agent uses Read, Glob, Grep tools to analyze codebase
- Target: 200-400 line detailed specification
- Timeout: 5 minutes (300 seconds)
- Fallback to direct expansion on failure

### 4. Create Phase Directory Structure

If first expansion, create directory and move phase file.

```bash
if [[ "$is_first_expansion" == true ]]; then
  echo "=== Creating Phase Directory Structure ==="

  # Create directory
  mkdir -p "$target_dir"
  echo "✓ Created directory: $target_dir"

  # Move phase file into directory
  mv "$phase_file" "$target_dir/"
  echo "✓ Moved phase file: $phase_file → $target_dir/$phase_base.md"

  # Update reference
  phase_file="$target_dir/$phase_base.md"
fi
```

**Directory Creation**:
- Create phase directory if first expansion
- Move phase file into directory
- Update internal references

### 5. Create Stage File

Write the detailed stage specification to a new file.

```bash
echo "=== Creating Stage File ==="

# Construct stage filename
stage_file="$target_dir/stage_${stage_num}_${stage_name_slug}.md"

# Prepare stage file content
cat > "$stage_file" <<EOF
---
stage: $stage_num
phase: $phase_num
plan: $plan_base
parent: $phase_base.md
---

$stage_spec

## Metadata
- **Stage Number**: $stage_num
- **Parent Phase**: $phase_base.md
- **Status**: PENDING

## Update Reminder

When this stage is complete:
1. Mark Stage $stage_num as [COMPLETED] in phase file: \`$phase_base.md\`
2. Update phase metadata if needed
3. Consider running tests before marking complete

To collapse this stage back: \`/collapse-stage $target_dir $stage_num\`
EOF

echo "✓ Created stage file: $stage_file"

# Validate file was written
if [[ ! -f "$stage_file" ]]; then
  error "Failed to create stage file: $stage_file"
fi

# Report file size
file_lines=$(wc -l < "$stage_file")
echo "  File size: $file_lines lines"

if [[ "$is_complex" == true ]] && [[ $file_lines -lt 100 ]]; then
  echo "⚠ Warning: Complex stage spec is short (<100 lines). May need enhancement."
fi
```

**Stage File Creation**:
- Add YAML frontmatter with metadata
- Include full stage specification (original or agent-researched)
- Add metadata section
- Add update reminder
- Validate file creation

### 6. Update Phase File

Replace stage content in phase file with summary and link.

```bash
echo "=== Updating Phase File ==="

# Create stage summary for phase file
stage_summary="#### Stage $stage_num: $stage_name
**Objective**: $(echo "$stage_spec" | grep -A2 "^\\*\\*Objective\\*\\*:" | tail -1 | sed 's/^[[:space:]]*//')

For detailed implementation steps, see [Stage $stage_num Details](stage_${stage_num}_${stage_name_slug}.md)"

# Replace stage content with summary
# Use awk to replace section
awk -v stage="$stage_num" -v summary="$stage_summary" '
  BEGIN { in_stage = 0; level = 0; printed_summary = 0 }

  /^#### Stage / {
    # Check if this is our stage
    match($0, /Stage ([0-9]+)/, m)
    if (m[1] == stage) {
      in_stage = 1
      match($0, /^#+/, h)
      level = length(h[0])

      # Print summary instead
      print summary
      print ""
      printed_summary = 1
      next
    }
  }

  in_stage && /^###/ {
    # Hit same-level or higher heading, stop replacing
    match($0, /^#+/, h)
    if (length(h[0]) <= level) {
      in_stage = 0
      print
      next
    }
  }

  !in_stage { print }
' "$phase_file" > "${phase_file}.tmp"

# Replace phase file
mv "${phase_file}.tmp" "$phase_file"
echo "✓ Updated phase file with stage summary"
```

**Phase File Update**:
- Extract stage objective for summary
- Replace full stage content with summary + link
- Preserve other stages and content

### 7. Update Metadata (Three-Way Synchronization)

Update metadata in phase file and main plan.

```bash
echo "=== Updating Metadata (Three-Way Sync) ==="

# === PART 1: Update Phase File Metadata ===

# Source shared utilities
source .claude/lib/progressive-planning-utils.sh

# Update phase file Expanded Stages
phase_updated=$(update_expansion_metadata "$phase_file" "expand" "stage" "$stage_num")
echo "$phase_updated" > "${phase_file}.tmp"
mv "${phase_file}.tmp" "$phase_file"

echo "✓ Phase file metadata updated (Stage $stage_num added)"

# === PART 2: Update Main Plan Metadata ===

# Backup main plan
backup_main="${main_plan}.backup.$$"
cp "$main_plan" "$backup_main"

# Update main plan's Expanded Stages dictionary
# Format: - **Expanded Stages**: {2: [1, 3], 5: [1]}

# Check if Expanded Stages exists
if grep -q "^- \*\*Expanded Stages\*\*:" "$main_plan"; then
  # Update existing dictionary
  awk -v phase="$phase_num" -v stage="$stage_num" '
    /^- \*\*Expanded Stages\*\*:/ {
      # Extract dictionary content
      match($0, /\{(.*)\}/, arr)
      dict = arr[1]

      # Check if phase exists in dict
      pattern = phase ": \\[([^]]*)\\]"
      if (match(dict, pattern, m)) {
        # Phase exists - add stage to list
        old_list = m[1]

        # Check if stage already in list
        if (!match(old_list, "(^|, )" stage "($|, )")) {
          # Add stage
          if (old_list == "") {
            new_list = stage
          } else {
            new_list = old_list ", " stage
          }

          # Replace in dict
          gsub(phase ": \\[[^]]*\\]", phase ": [" new_list "]", dict)
        }
      } else {
        # Phase not in dict - add new entry
        if (dict == "" || dict == " ") {
          dict = phase ": [" stage "]"
        } else {
          dict = dict ", " phase ": [" stage "]"
        }
      }

      print "- **Expanded Stages**: {" dict "}"
      next
    }
    { print }
  ' "$main_plan" > "${main_plan}.tmp"

else
  # Add Expanded Stages metadata
  awk -v phase="$phase_num" -v stage="$stage_num" '
    /^## Metadata/ {
      print
      getline
      print
      print "- **Expanded Stages**: {" phase ": [" stage "]}"
      next
    }
    { print }
  ' "$main_plan" > "${main_plan}.tmp"
fi

mv "${main_plan}.tmp" "$main_plan"
echo "✓ Main plan metadata updated (Phase $phase_num: Stage $stage_num added)"

# Update Structure Level to 2 if needed
if ! grep -q "^- \*\*Structure Level\*\*: 2$" "$main_plan"; then
  sed -i 's/^- \*\*Structure Level\*\*: [0-9]$/- \*\*Structure Level\*\*: 2/' "$main_plan"
  echo "✓ Main plan Structure Level set to 2"
fi

# Remove backup
rm -f "$backup_main"
```

**Three-Way Metadata Updates**:
1. Update phase file Expanded Stages list
2. Update main plan Expanded Stages dictionary (add phase:stage entry)
3. Update main plan Structure Level to 2
4. Use atomic operations with backup

### 8. Validation and Summary

Verify the expansion completed successfully.

```bash
echo ""
echo "=== Expansion Validation ==="

# Validate phase directory
[[ -d "$target_dir" ]] && echo "✓ Phase directory exists: $target_dir"

# Validate phase file
[[ -f "$phase_file" ]] && echo "✓ Phase file exists: $phase_file"

# Validate stage file
[[ -f "$stage_file" ]] && echo "✓ Stage file exists: $stage_file"

# Validate phase metadata
phase_expanded=$(grep "^- \*\*Expanded Stages\*\*:" "$phase_file" || echo "")
if [[ -n "$phase_expanded" ]] && [[ "$phase_expanded" == *"$stage_num"* ]]; then
  echo "✓ Phase metadata includes Stage $stage_num"
else
  echo "⚠ Phase metadata may not be updated correctly"
fi

# Validate main plan metadata
main_expanded=$(grep "^- \*\*Expanded Stages\*\*:" "$main_plan" || echo "")
if [[ -n "$main_expanded" ]] && [[ "$main_expanded" == *"$phase_num"* ]]; then
  echo "✓ Main plan metadata includes Phase $phase_num"
else
  echo "⚠ Main plan metadata may not be updated correctly"
fi

# Check Structure Level
structure=$(grep "^- \*\*Structure Level\*\*:" "$main_plan" || echo "- **Structure Level**: 0")
if [[ "$structure" == *"2"* ]]; then
  echo "✓ Structure Level: 2"
else
  echo "⚠ Structure Level not set to 2"
fi

echo ""
echo "✅ Stage $stage_num expanded successfully"
echo ""
echo "=== Next Steps ==="
echo "1. Review stage file: $stage_file"
if [[ "$is_complex" == true ]]; then
  echo "2. Agent research created detailed spec - verify completeness"
  echo "3. Enhance specification if needed (add examples, refine steps)"
else
  echo "2. Simple stage - enhance with details as needed"
fi
echo "3. Implement stage tasks"
echo "4. Mark stage complete in phase file when done"
echo "5. To collapse: /collapse-stage $target_dir $stage_num"
```

**Validation Checks**:
- [ ] Phase directory exists
- [ ] Phase file exists and updated
- [ ] Stage file created with content
- [ ] Phase metadata updated
- [ ] Main plan metadata updated
- [ ] Structure Level set to 2

## Quality Checklist

Before completing the expansion operation, verify:

- [ ] Stage content extracted completely
- [ ] Complexity analysis performed correctly
- [ ] Agent research invoked for complex stages (if applicable)
- [ ] Stage spec is 200-400 lines for complex stages
- [ ] Phase directory created if first expansion
- [ ] Stage file created with proper metadata
- [ ] Phase file updated with summary and link
- [ ] Three-way metadata synchronized (phase + main plan)
- [ ] Structure Level updated to 2
- [ ] All files validated and exist
- [ ] Update reminder included in stage file

## Error Handling

### Scenario 1: Stage Not Found

**Symptom**: Cannot locate stage in phase file

**Recovery**:
```bash
echo "Error: Stage $stage_num not found in phase file"
echo ""
echo "Available stages:"
grep "^#### Stage " "$phase_file" | sed 's/^#### /  /'
echo ""
echo "Verify stage number and try again"
exit 1
```

### Scenario 2: Stage Already Expanded

**Symptom**: Stage file already exists

**Recovery**:
```bash
echo "Error: Stage $stage_num already expanded"
echo "Existing file: $stage_file"
echo ""
echo "Options:"
echo "1. Work with existing stage file"
echo "2. Collapse and re-expand: /collapse-stage $target_dir $stage_num"
echo "3. Manually delete stage file and re-run"
exit 1
```

### Scenario 3: Agent Research Timeout

**Symptom**: Agent fails to complete research within 5 minutes

**Recovery**:
```bash
echo "Warning: Agent research timed out"
echo "Falling back to direct expansion (simple stage spec)"
echo ""
echo "You can manually enhance the stage file after expansion:"
echo "  Edit: $stage_file"
echo "  Add details, code examples, file references"
# Continue with direct expansion
is_complex=false
stage_spec="$stage_content"
```

### Scenario 4: Metadata Update Failure

**Symptom**: Cannot update phase or main plan metadata

**Recovery**:
```bash
echo "Error: Metadata update failed"
echo "Rolling back changes..."

# Restore from backup
[[ -f "$backup_main" ]] && mv "$backup_main" "$main_plan"

# Remove created files
rm -f "$stage_file"

# Restore phase file if moved
if [[ "$is_first_expansion" == true ]]; then
  mv "$target_dir/$phase_base.md" "$phase_file"
  rmdir "$target_dir"
fi

echo "Changes rolled back"
exit 1
```

### Scenario 5: Insufficient Disk Space

**Symptom**: Cannot write stage file

**Recovery**:
```bash
echo "Error: Failed to write stage file"
echo "Check disk space: df -h"
echo ""
echo "If space is available, check file permissions:"
echo "  ls -la $target_dir"
echo ""
echo "Manual intervention may be required"
exit 1
```

## Validation Examples

### Example 1: Simple Stage Expansion (Direct)

**Stage Content (Simple)**:
```markdown
#### Stage 1: Setup Configuration

**Objective**: Create basic configuration files

Tasks:
- [ ] Create config.lua
- [ ] Add default settings
- [ ] Document configuration options
```

**Analysis**:
- Implementation steps: 3 (≤3, threshold not met)
- File references: 1 (<8)
- Complex keywords: 0
- **Conclusion**: SIMPLE stage - direct expansion

**Command**:
```bash
/expand-stage specs/plans/025_feature/phase_2_impl.md 1
```

**Output**:
```
Phase file: specs/plans/025_feature/phase_2_impl.md
Phase number: 2
Main plan: specs/plans/025_feature.md

=== Stage Complexity Analysis ===
Implementation steps: 3
File references: 1
Unique directories: 1
Complex keywords: 0
Word count: 45

✓ Stage is SIMPLE (direct expansion sufficient)

=== Creating Phase Directory Structure ===
✓ Created directory: specs/plans/025_feature/phase_2_impl
✓ Moved phase file: specs/plans/025_feature/phase_2_impl.md → specs/plans/025_feature/phase_2_impl/phase_2_impl.md

=== Creating Stage File ===
✓ Created stage file: specs/plans/025_feature/phase_2_impl/stage_1_setup_configuration.md
  File size: 35 lines

=== Updating Phase File ===
✓ Updated phase file with stage summary

=== Updating Metadata (Three-Way Sync) ===
✓ Phase file metadata updated (Stage 1 added)
✓ Main plan metadata updated (Phase 2: Stage 1 added)
✓ Main plan Structure Level set to 2

=== Expansion Validation ===
✓ Phase directory exists
✓ Phase file exists
✓ Stage file exists
✓ Phase metadata includes Stage 1
✓ Main plan metadata includes Phase 2
✓ Structure Level: 2

✅ Stage 1 expanded successfully
```

### Example 2: Complex Stage Expansion (Agent Research)

**Stage Content (Complex)**:
```markdown
#### Stage 2: Parallel Processing Implementation

**Objective**: Implement concurrent task processing with worker pool

Tasks:
- [ ] Design worker pool architecture (lib/workers/, lib/queue/, lib/coordinator/)
- [ ] Implement task queue with priority support
- [ ] Create worker threads with graceful shutdown
- [ ] Add monitoring and metrics collection
- [ ] Implement error handling and retry logic
- [ ] Add integration tests for parallel scenarios
- [ ] Optimize for multi-core performance
- [ ] Document architecture and usage patterns

Files: lib/workers/pool.lua, lib/workers/worker.lua, lib/queue/priority.lua,
       lib/coordinator/scheduler.lua, lib/metrics/collector.lua,
       tests/integration/parallel_tests.lua, docs/architecture.md
```

**Analysis**:
- Implementation steps: 8 (>3, threshold met)
- File references: 10 (≥8, threshold met)
- Unique directories: 5 (>1, threshold met)
- Complex keywords: "parallel", "concurrent" (threshold met)
- **Conclusion**: COMPLEX stage - agent research recommended

**Command**:
```bash
/expand-stage specs/plans/025_feature/phase_2_impl/ 2
```

**Output**:
```
Phase file: specs/plans/025_feature/phase_2_impl/phase_2_impl.md
Phase number: 2
Main plan: specs/plans/025_feature.md
Existing phase directory: specs/plans/025_feature/phase_2_impl (Level 2)

=== Stage Complexity Analysis ===
Implementation steps: 8
File references: 10
Unique directories: 5
Complex keywords: 2
Word count: 120

✓ Stage is COMPLEX (agent research recommended)
  Reasons: 8 implementation steps (>3) 10 file references (≥8) 5 directories (>1) complexity keywords present

=== Agent Research Phase ===
Stage complexity warrants detailed research and specification.

Invoking agent for stage research...
Target: 200-400 line detailed specification

✓ Agent research completed
  Research output: 1850 words (~280 lines)

=== Creating Stage File ===
✓ Created stage file: specs/plans/025_feature/phase_2_impl/stage_2_parallel_processing_implementation.md
  File size: 312 lines

=== Updating Phase File ===
✓ Updated phase file with stage summary

=== Updating Metadata (Three-Way Sync) ===
✓ Phase file metadata updated (Stage 2 added)
✓ Main plan metadata updated (Phase 2: Stage 2 added)

=== Expansion Validation ===
✓ Phase directory exists
✓ Phase file exists
✓ Stage file exists
✓ Phase metadata includes Stage 2
✓ Main plan metadata includes Phase 2
✓ Structure Level: 2

✅ Stage 2 expanded successfully

=== Next Steps ===
1. Review stage file: specs/plans/025_feature/phase_2_impl/stage_2_parallel_processing_implementation.md
2. Agent research created detailed spec - verify completeness
3. Enhance specification if needed (add examples, refine steps)
4. Implement stage tasks
5. Mark stage complete in phase file when done
6. To collapse: /collapse-stage specs/plans/025_feature/phase_2_impl 2
```

### Example 3: Subsequent Expansion (Level 2 → Level 2)

**Before**:
```
specs/plans/025_feature/
├── 025_feature.md
└── phase_2_impl/
    ├── phase_2_impl.md
    └── stage_1_setup.md   # Already expanded
```

**Command**:
```bash
/expand-stage specs/plans/025_feature/phase_2_impl/ 3
```

**After**:
```
specs/plans/025_feature/
├── 025_feature.md
└── phase_2_impl/
    ├── phase_2_impl.md
    ├── stage_1_setup.md
    └── stage_3_testing.md   # Newly expanded
```

**Output**:
```
Phase file: specs/plans/025_feature/phase_2_impl/phase_2_impl.md
Phase number: 2
Main plan: specs/plans/025_feature.md
Existing phase directory: specs/plans/025_feature/phase_2_impl (Level 2)

[... complexity analysis ...]

=== Creating Stage File ===
✓ Created stage file: specs/plans/025_feature/phase_2_impl/stage_3_testing.md

[... updates ...]

=== Updating Metadata (Three-Way Sync) ===
✓ Phase file metadata updated (Stage 3 added)
✓ Main plan metadata updated (Phase 2: Stage 3 added)

✅ Stage 3 expanded successfully
```

## Complexity Thresholds

Stage-level complexity detection uses lower thresholds than phase-level:

| Metric | Phase Threshold | Stage Threshold | Rationale |
|--------|----------------|-----------------|-----------|
| Implementation steps | >5 tasks | >3 steps | Stages are smaller units |
| File references | ≥10 files | ≥8 files | Stages focus on subset |
| Unique directories | >2 dirs | >1 dir | Stages usually single-directory |
| Keywords | parallel, distributed, integration | Same | Complexity keywords universal |

**Complex Keywords**: `parallel`, `concurrent`, `distributed`, `integration`, `coordinat`

## Agent Integration

### When Agents Are Used

- **Complex stages only**: Triggered by complexity thresholds
- **Research focus**: Analyze codebase, provide detailed implementation steps
- **Synthesis goal**: Transform brief stage outline into 200-400 line specification

### Agent Behavior

- **Tool usage**: Read, Glob, Grep for codebase analysis
- **Output format**: Markdown with file:line references, code examples, testing plans
- **Timeout**: 5 minutes (300 seconds)
- **Fallback**: Direct expansion if agent fails

### Agent Prompt Structure

```markdown
# Stage Expansion Research Context

## Stage Information
[Stage metadata and context]

## Current Stage Content
[Brief stage outline from phase file]

## Research Objectives
1. File Analysis (Glob, Read)
2. Implementation Details (specific steps, code examples)
3. Dependencies (prerequisites, order)
4. Testing Strategy (unit, integration, validation)
5. Risk Assessment (edge cases, compatibility)

## Output Format
- Objective (2-3 sentences)
- Implementation Steps (numbered, detailed, 200-400 lines)
- File References (file:line)
- Code Examples (concrete snippets)
- Testing Plan (specific tests)
- Dependencies (explicit prerequisites)
- Risks (issues and mitigations)

## Quality Standards
- Specific (HOW, not just WHAT)
- Concrete (file paths, line numbers, function names)
- Complete (cover all tasks)
- Practical (actionable implementation details)
```

## Key Principles

1. **Progressive Complexity**: Start simple, expand only when needed
2. **Intelligent Research**: Use agents for complex stages to improve quality
3. **Content Preservation**: Maintain all information during expansion
4. **Three-Way Synchronization**: Update stage → phase → main plan atomically
5. **Clean Transitions**: Properly update metadata for Level 1→2 or Level 2→2
6. **Reversibility**: Expansion can be undone via `/collapse-stage`

## Integration with Other Commands

### Uses Shared Utilities
- `update_expansion_metadata()` - Update phase file metadata
- `parse-adaptive-plan.sh` - Structure detection functions

### Uses Agents
- `general-purpose` - Research and synthesis for complex stages

### Complementary Commands
- `/expand-phase` - Expand phases (precursor to stage expansion)
- `/collapse-stage` - Reverse the expansion (opposite operation)
- `/list-plans` - Show expansion status
- `/implement` - May trigger expansion during implementation

## Standards Applied

Following CLAUDE.md Code Standards:
- **Indentation**: 2 spaces, expandtab (in code examples)
- **Error Handling**: Comprehensive validation and rollback
- **Documentation**: Clear operation description with examples
- **File Operations**: Safe atomic operations with temp files
- **Agent Usage**: Behavioral injection pattern for research

## Notes

- Stage files are named `stage_N_name.md` where name is derived from stage heading
- Original task completion status is preserved during extraction
- Phase file becomes a summary/index after first stage expansion
- Expansion is reversible via `/collapse-stage`
- Multiple stages can be expanded independently
- Main plan metadata tracks which phases have stage expansions
- Agent research is optional - complexity detection determines usage
- Simple stages expand directly without agent overhead
- Complex stages benefit from detailed agent research (200-400 lines)
- Three-way metadata synchronization is complex - uses backups with rollback
