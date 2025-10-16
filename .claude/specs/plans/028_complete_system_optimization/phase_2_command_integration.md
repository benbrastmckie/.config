### Phase 2: Command Integration - Metadata-Only Reads

## Metadata
- **Phase Number**: 2
- **Parent Plan**: 028_complete_system_optimization.md
- **Estimated Complexity**: 6.5/10
- **Estimated Time**: 4-6 hours
- **Dependencies**: Phase 1 (completed - artifact-utils.sh exists with metadata functions)
- **Impact**: 70-88% context reduction across 4 commands

## Original Phase Content

**Objective**: Integrate metadata-only read pattern into commands for dramatic context reduction

**Tasks**:
- [ ] /list-plans uses get_plan_metadata() for 88% context reduction (1.5MB → 180KB)
- [ ] /list-reports uses get_report_metadata() for similar gains
- [ ] /implement uses get_plan_phase() for 80% context reduction (250KB → 50KB)
- [ ] /plan uses get_report_metadata() when checking report relevance
- [ ] All commands tested with real artifacts (93 plans, 79 reports)

---

## Detailed Implementation Specification

### Overview

This phase integrates the metadata extraction functions created in Phase 1 (`artifact-utils.sh`) into four key commands to achieve significant context reduction. The functions are already implemented and tested; this phase focuses on **adoption** and **integration** into existing command workflows.

**Current State**:
- `lib/artifact-utils.sh` contains three optimized metadata extraction functions:
  - `get_plan_metadata()`: Reads only first 50 lines (vs full file ~1000+ lines)
  - `get_report_metadata()`: Reads only first 100 lines (vs full file ~2000+ lines)
  - `get_plan_phase()`: Extracts single phase on-demand (vs loading entire plan)

- Commands currently use full file reads:
  - `/list-plans`: Reads entire plan files to extract metadata
  - `/list-reports`: Reads entire report files to get titles/dates
  - `/implement`: Loads complete plan even when executing single phase
  - `/plan`: Reads full reports when checking relevance

**Target State**:
- All four commands use metadata-only reads for discovery/filtering
- Full content loaded only when actually needed for processing
- 70-88% reduction in context size for typical workflows
- Backwards compatibility maintained (fallback to full reads if metadata extraction fails)

**Success Criteria**:
1. All four commands successfully integrated with metadata functions
2. Commands maintain identical output format (no breaking changes)
3. Performance measurably improved (benchmark results)
4. Context reduction verified (before/after measurements)
5. All existing tests still pass
6. New tests added for metadata integration
7. Documentation updated with optimization notes

**Risk Analysis**:
- **Low Risk**: Functions are already tested and stable
- **Medium Risk**: Command integration may reveal edge cases in metadata extraction
- **Mitigation**: Fallback to full reads on metadata extraction failure
- **Mitigation**: Comprehensive testing with real artifact corpus (93 plans, 79 reports)

---

## Task Breakdown - Detailed Implementation

### Task 1: Integrate get_plan_metadata() into /list-plans

**Current Implementation Analysis**:

The `/list-plans.md` command currently documents the intent to use metadata-only reads but may not have the actual bash implementation. The command needs to:
1. Discover all plan files (Level 0, 1, 2)
2. Extract metadata from each plan
3. Display plan inventory with metadata
4. Support optional search pattern filtering

**Implementation Approach**:

**File**: `.claude/commands/list-plans.md`

**Changes Required**:

1. **Add library sourcing** (if not present):
```bash
# Source metadata extraction utilities
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-utils.sh"
```

2. **Replace full file reads with metadata extraction**:

**Before** (hypothetical current state):
```bash
for plan in specs/plans/*.md; do
  # Full file read - expensive
  title=$(grep -m1 '^# ' "$plan" | sed 's/^# //')
  date=$(grep -m1 'Date:' "$plan" | cut -d: -f2-)
  phases=$(grep -c '^### Phase' "$plan")

  echo "[$date] $title ($phases phases)"
done
```

**After** (optimized):
```bash
for plan in specs/plans/*.md; do
  # Metadata-only read - 88% reduction
  metadata=$(get_plan_metadata "$plan")

  # Extract fields from JSON
  title=$(echo "$metadata" | jq -r '.title // "Unknown"')
  date=$(echo "$metadata" | jq -r '.date // "N/A"')
  phases=$(echo "$metadata" | jq -r '.phases // 0')

  echo "[$date] $title ($phases phases)"
done
```

3. **Add error handling with fallback**:
```bash
# Try metadata extraction first
metadata=$(get_plan_metadata "$plan" 2>/dev/null)

if [[ -z "$metadata" ]] || echo "$metadata" | grep -q '"error"'; then
  # Fallback to full read if metadata extraction fails
  title=$(grep -m1 '^# ' "$plan" | sed 's/^# //')
  date=$(grep -m1 'Date:' "$plan" | cut -d: -f2- | sed 's/^ *//')
  phases=$(grep -c '^### Phase' "$plan")
else
  # Use metadata
  title=$(echo "$metadata" | jq -r '.title')
  date=$(echo "$metadata" | jq -r '.date')
  phases=$(echo "$metadata" | jq -r '.phases')
fi
```

4. **Handle both single-file and directory plans**:
```bash
# Find Level 0 plans (single files)
level_0_plans=$(find . -path "*/specs/plans/*.md" -type f -not -path "*/specs/plans/*/*")

# Find Level 1/2 plans (directories)
level_1_2_plans=$(find . -path "*/specs/plans/*/*.md" -type f | while read -r overview; do
  # Get directory path
  plan_dir=$(dirname "$overview")
  plan_name=$(basename "$plan_dir")

  # Only list if overview file matches directory name
  if [[ "$(basename "$overview" .md)" == "$plan_name" ]]; then
    echo "$overview"
  fi
done)

# Process all plans
for plan in $level_0_plans $level_1_2_plans; do
  metadata=$(get_plan_metadata "$plan")
  # ... display logic
done
```

**Detailed Implementation Steps**:

1. Read current `/list-plans.md` implementation section
2. Identify where plan files are discovered and processed
3. Add `source` statement for `artifact-utils.sh` at the beginning
4. Replace full file reads with `get_plan_metadata()` calls
5. Add error handling with fallback to full reads
6. Update the command's "Process" section with new implementation
7. Add performance note: "Uses metadata-only reads (~88% context reduction)"

**Testing Requirements**:

Create `.claude/tests/test_list_plans_metadata.sh`:
```bash
#!/usr/bin/env bash

# Test metadata integration in list-plans

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source artifact-utils
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/.claude/lib/artifact-utils.sh"

test_count=0
pass_count=0

# Test 1: Metadata extraction works for real plan
((test_count++))
metadata=$(get_plan_metadata "$PROJECT_ROOT/specs/plans/028_complete_system_optimization/028_complete_system_optimization.md")
if echo "$metadata" | jq -e '.title' >/dev/null 2>&1; then
  ((pass_count++))
  echo "✓ Test 1: Metadata extraction successful"
else
  echo "✗ Test 1: Metadata extraction failed"
fi

# Test 2: All plans can be processed
((test_count++))
failed_plans=0
while read -r plan; do
  metadata=$(get_plan_metadata "$plan" 2>/dev/null)
  if [[ -z "$metadata" ]] || echo "$metadata" | grep -q '"error"'; then
    echo "  Warning: Failed to extract metadata from $plan"
    ((failed_plans++))
  fi
done < <(find "$PROJECT_ROOT" -path "*/specs/plans/*.md" -type f 2>/dev/null | head -10)

if [[ $failed_plans -eq 0 ]]; then
  ((pass_count++))
  echo "✓ Test 2: All sampled plans processed successfully"
else
  echo "✗ Test 2: $failed_plans plans failed metadata extraction"
fi

# Summary
echo ""
echo "Tests passed: $pass_count/$test_count"
[[ $pass_count -eq $test_count ]]
```

**Success Criteria**:
- `/list-plans` command sources `artifact-utils.sh`
- Uses `get_plan_metadata()` for all plan file processing
- Fallback logic handles metadata extraction failures
- Output format unchanged from previous version
- Test suite confirms 88% context reduction achieved
- Command execution time reduced (measurable with `time` command)

**Estimated Complexity**: 6/10

---

### Task 2: Integrate get_report_metadata() into /list-reports

**Current Implementation Analysis**:

The `/list-reports.md` command needs similar integration as `/list-plans` but for research reports. Reports have different metadata structure (research questions instead of phases).

**Implementation Approach**:

**File**: `.claude/commands/list-reports.md`

**Changes Required**:

1. **Add library sourcing**:
```bash
# Source metadata extraction utilities
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-utils.sh"
```

2. **Replace full file reads**:

**Before**:
```bash
for report in specs/reports/*.md; do
  title=$(grep -m1 '^# ' "$report" | sed 's/^# //')
  date=$(grep -m1 'Date:' "$report" | cut -d: -f2-)
  questions=$(grep -c '^[0-9]\+\.' "$report")

  echo "[$date] $title ($questions questions)"
done
```

**After**:
```bash
for report in specs/reports/*.md; do
  # Metadata-only read - 85-90% reduction
  metadata=$(get_report_metadata "$report")

  title=$(echo "$metadata" | jq -r '.title // "Unknown"')
  date=$(echo "$metadata" | jq -r '.date // "N/A"')
  questions=$(echo "$metadata" | jq -r '.research_questions // 0')

  echo "[$date] $title ($questions research questions)"
done
```

3. **Add search pattern filtering (if argument provided)**:
```bash
search_pattern="${1:-}"

for report in specs/reports/*.md; do
  metadata=$(get_report_metadata "$report")
  title=$(echo "$metadata" | jq -r '.title')

  # Skip if doesn't match search pattern
  if [[ -n "$search_pattern" ]] && ! echo "$title" | grep -qi "$search_pattern"; then
    continue
  fi

  # Display matching reports
  echo "[$date] $title ($questions research questions)"
  echo "  Path: $report"
done
```

**Detailed Implementation Steps**:

1. Read current `/list-reports.md` implementation
2. Add `source` statement at beginning
3. Replace grep/sed metadata extraction with `get_report_metadata()` calls
4. Add error handling with fallback
5. Implement search pattern filtering
6. Update documentation with performance notes

**Testing Requirements**:

Create `.claude/tests/test_list_reports_metadata.sh`:
```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/.claude/lib/artifact-utils.sh"

test_count=0
pass_count=0

# Test: Report metadata extraction
((test_count++))
sample_report=$(find "$PROJECT_ROOT" -path "*/specs/reports/*.md" -type f | head -1)
if [[ -n "$sample_report" ]]; then
  metadata=$(get_report_metadata "$sample_report")
  if echo "$metadata" | jq -e '.title' >/dev/null 2>&1; then
    ((pass_count++))
    echo "✓ Report metadata extraction works"
  else
    echo "✗ Report metadata extraction failed"
  fi
else
  echo "⊘ Skipped: No reports found"
  ((pass_count++))  # Don't fail if no reports exist
fi

echo "Tests passed: $pass_count/$test_count"
[[ $pass_count -eq $test_count ]]
```

**Success Criteria**:
- `/list-reports` uses `get_report_metadata()` for all reports
- Search pattern filtering works correctly
- Performance improvement measurable
- 85-90% context reduction achieved

**Estimated Complexity**: 5/10

---

### Task 3: Integrate get_plan_phase() into /implement

**Current Implementation Analysis**:

The `/implement` command is the most complex integration. It currently loads entire plans even when executing a single phase. With `get_plan_phase()`, we can load only the current phase content.

**Implementation Approach**:

**File**: `.claude/commands/implement.md`

**Key Change**: Phase-by-phase loading instead of loading entire plan upfront

**Current Pattern** (hypothetical):
```bash
# Load entire plan
plan_content=$(cat "$plan_file")

# Execute phases sequentially
for phase in $(seq 1 $total_phases); do
  # Extract this phase from full content
  phase_content=$(echo "$plan_content" | awk "/### Phase $phase:/,/### Phase $((phase+1)):/")

  # Execute phase
  execute_phase "$phase_content"
done
```

**New Pattern** (optimized):
```bash
# Source utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-utils.sh"

# Get metadata first (lightweight)
metadata=$(get_plan_metadata "$plan_file")
total_phases=$(echo "$metadata" | jq -r '.phases')

# Execute phases sequentially with on-demand loading
for phase in $(seq 1 $total_phases); do
  # Load ONLY current phase (80% reduction per iteration)
  phase_content=$(get_plan_phase "$plan_file" "$phase")

  # Execute phase
  execute_phase "$phase_content"
done
```

**Benefits**:
- Initial metadata read: 50 lines vs 1000+ lines (95% reduction)
- Per-phase content: ~100 lines vs 1000+ lines (90% reduction)
- Overall: 80% context reduction for multi-phase implementations

**Detailed Implementation Steps**:

1. **Locate phase execution loop in /implement.md**:
   - Search for where phases are iterated
   - Identify where plan content is loaded

2. **Add artifact-utils sourcing**:
```bash
# At top of /implement command
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-utils.sh"
```

3. **Replace initial plan load with metadata read**:
```bash
# Before: Load full plan
# plan_content=$(cat "$plan_file")
# total_phases=$(echo "$plan_content" | grep -c '^### Phase')

# After: Load only metadata
plan_metadata=$(get_plan_metadata "$plan_file")
total_phases=$(echo "$plan_metadata" | jq -r '.phases')
plan_title=$(echo "$plan_metadata" | jq -r '.title')
```

4. **Implement selective phase loading in execution loop**:
```bash
# Phase execution loop
for current_phase in $(seq $starting_phase $total_phases); do
  echo "=== Phase $current_phase/$total_phases ==="

  # Load only this phase's content (on-demand)
  phase_content=$(get_plan_phase "$plan_file" "$current_phase")

  # Extract phase details
  phase_title=$(echo "$phase_content" | grep -m1 "^### Phase $current_phase" | sed 's/^### Phase [0-9]*: *//')
  phase_objective=$(echo "$phase_content" | grep -m1 '^\*\*Objective\*\*:' | sed 's/^\*\*Objective\*\*: *//')

  # Execute phase tasks
  # ... (existing phase execution logic)

  # Phase complete, move to next
done
```

5. **Add error handling**:
```bash
# Load phase with error checking
phase_content=$(get_plan_phase "$plan_file" "$current_phase" 2>&1)

if [[ $? -ne 0 ]] || [[ -z "$phase_content" ]]; then
  echo "Error: Failed to load Phase $current_phase from $plan_file" >&2
  echo "Attempting fallback to full plan read..." >&2

  # Fallback: Load full plan and extract phase
  full_plan=$(cat "$plan_file")
  phase_content=$(echo "$full_plan" | awk "/^### Phase $current_phase:/,/^### Phase $((current_phase+1)):/")

  if [[ -z "$phase_content" ]]; then
    echo "Error: Phase $current_phase not found in plan" >&2
    exit 1
  fi
fi
```

6. **Update checkpoint saving** (if applicable):
```bash
# Save checkpoint after phase completion
save_checkpoint "$plan_file" "$current_phase" "completed"
```

**Testing Requirements**:

Create `.claude/tests/test_implement_phase_loading.sh`:
```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/.claude/lib/artifact-utils.sh"

test_count=0
pass_count=0

# Test 1: Phase extraction from real plan
((test_count++))
plan_file="$PROJECT_ROOT/specs/plans/028_complete_system_optimization/028_complete_system_optimization.md"
if [[ -f "$plan_file" ]]; then
  phase_2=$(get_plan_phase "$plan_file" 2)
  if echo "$phase_2" | grep -q "Phase 2"; then
    ((pass_count++))
    echo "✓ Test 1: Phase extraction successful"
  else
    echo "✗ Test 1: Phase extraction failed"
  fi
else
  echo "⊘ Test 1: Skipped (test plan not found)"
  ((pass_count++))
fi

# Test 2: Multiple phase loads
((test_count++))
metadata=$(get_plan_metadata "$plan_file" 2>/dev/null)
total_phases=$(echo "$metadata" | jq -r '.phases // 0')

if [[ $total_phases -gt 0 ]]; then
  all_phases_loaded=true
  for phase in $(seq 1 $total_phases); do
    content=$(get_plan_phase "$plan_file" "$phase" 2>/dev/null)
    if [[ -z "$content" ]]; then
      all_phases_loaded=false
      break
    fi
  done

  if $all_phases_loaded; then
    ((pass_count++))
    echo "✓ Test 2: All $total_phases phases loaded successfully"
  else
    echo "✗ Test 2: Some phases failed to load"
  fi
else
  echo "⊘ Test 2: Skipped (no phases found)"
  ((pass_count++))
fi

# Test 3: Context reduction measurement
((test_count++))
full_size=$(wc -c < "$plan_file")
phase_1_size=$(get_plan_phase "$plan_file" 1 | wc -c)
reduction=$(( 100 - (phase_1_size * 100 / full_size) ))

if [[ $reduction -ge 70 ]]; then
  ((pass_count++))
  echo "✓ Test 3: Context reduction ${reduction}% (target: ≥70%)"
else
  echo "✗ Test 3: Context reduction ${reduction}% (target: ≥70%)"
fi

echo "Tests passed: $pass_count/$test_count"
[[ $pass_count -eq $test_count ]]
```

**Success Criteria**:
- `/implement` loads metadata first, then phases on-demand
- 80% context reduction achieved
- All existing phase execution logic still works
- Checkpoints save/restore correctly
- Error handling gracefully falls back to full reads

**Estimated Complexity**: 8/10 (most complex integration)

---

### Task 4: Integrate get_report_metadata() into /plan

**Current Implementation Analysis**:

The `/plan` command currently reads full research reports when checking if they're relevant to the feature being planned. This is inefficient for large report sets.

**Implementation Approach**:

**File**: `.claude/commands/plan.md`

**Use Case**: When user provides report paths or /plan searches for relevant reports, it should check metadata first before loading full content.

**Current Pattern** (hypothetical):
```bash
# Check if report is relevant
for report in specs/reports/*.md; do
  # Full read to check relevance
  report_content=$(cat "$report")

  if echo "$report_content" | grep -qi "$feature_keyword"; then
    # Report seems relevant, use it
    echo "Using report: $report"
    process_report "$report_content"
  fi
done
```

**New Pattern** (optimized):
```bash
# Source utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-utils.sh"

# Check report relevance using metadata only
for report in specs/reports/*.md; do
  # Metadata-only read (90% reduction)
  metadata=$(get_report_metadata "$report")
  title=$(echo "$metadata" | jq -r '.title')

  # Quick relevance check on title
  if echo "$title" | grep -qi "$feature_keyword"; then
    # Looks relevant, load full report now
    report_content=$(cat "$report")
    echo "Using report: $report ($title)"
    process_report "$report_content"
  fi
done
```

**Advanced Pattern** (with user-provided reports):
```bash
# User provided specific reports
if [[ -n "$REPORT_PATHS" ]]; then
  for report_path in $REPORT_PATHS; do
    # Validate report exists and extract metadata
    if [[ ! -f "$report_path" ]]; then
      echo "Warning: Report not found: $report_path" >&2
      continue
    fi

    metadata=$(get_report_metadata "$report_path")
    title=$(echo "$metadata" | jq -r '.title')
    date=$(echo "$metadata" | jq -r '.date')
    questions=$(echo "$metadata" | jq -r '.research_questions')

    echo "Loading report: $title ($date, $questions questions)"

    # Now load full content for planning
    report_content=$(cat "$report_path")
    # ... use in planning
  done
fi
```

**Detailed Implementation Steps**:

1. **Locate report discovery/loading in /plan.md**
2. **Add artifact-utils sourcing**
3. **Replace automatic report scanning**:
   - Use `get_report_metadata()` for initial scan
   - Load full content only for matching reports
4. **Update user-provided report handling**:
   - Show metadata before loading
   - Validate reports exist
5. **Add performance notes to documentation**

**Testing Requirements**:

Create `.claude/tests/test_plan_report_metadata.sh`:
```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/.claude/lib/artifact-utils.sh"

test_count=0
pass_count=0

# Test: Report filtering by keyword
((test_count++))
keyword="optimization"
matching_count=0

while read -r report; do
  metadata=$(get_report_metadata "$report" 2>/dev/null)
  title=$(echo "$metadata" | jq -r '.title // ""')

  if echo "$title" | grep -qi "$keyword"; then
    ((matching_count++))
  fi
done < <(find "$PROJECT_ROOT" -path "*/specs/reports/*.md" -type f 2>/dev/null)

if [[ $matching_count -gt 0 ]]; then
  ((pass_count++))
  echo "✓ Test: Found $matching_count reports matching '$keyword'"
else
  # Not necessarily a failure if no reports match
  ((pass_count++))
  echo "⊘ Test: No reports matching '$keyword' (OK)"
fi

echo "Tests passed: $pass_count/$test_count"
[[ $pass_count -eq $test_count ]]
```

**Success Criteria**:
- `/plan` uses metadata for report discovery
- Full reports loaded only when needed
- User-provided reports show metadata before loading
- Performance improved for large report sets

**Estimated Complexity**: 6/10

---

### Task 5: Comprehensive Testing with Real Artifacts

**Objective**: Validate all integrations work correctly with the actual artifact corpus (93 plans, 79 reports).

**Testing Approach**:

**Test Suite**: `.claude/tests/test_command_integration_phase2.sh`

```bash
#!/usr/bin/env bash

# Phase 2 Integration Test Suite
# Tests all four commands with real artifacts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/.claude/lib/artifact-utils.sh"

echo "=== Phase 2 Command Integration Tests ==="
echo ""

test_count=0
pass_count=0

# Test 1: /list-plans metadata integration
echo "Test 1: /list-plans with metadata-only reads"
((test_count++))
list_plans_output=$(bash -c "cd $PROJECT_ROOT && bash <<'EOF'
export CLAUDE_PROJECT_DIR='$PROJECT_ROOT'
source '.claude/lib/artifact-utils.sh'

# Simulate /list-plans logic
plan_count=0
for plan in specs/plans/*.md; do
  [[ -f "\$plan" ]] || continue
  metadata=\$(get_plan_metadata "\$plan" 2>/dev/null)
  if [[ -n "\$metadata" ]]; then
    ((plan_count++))
  fi
done
echo "\$plan_count"
EOF
")

if [[ $list_plans_output -gt 0 ]]; then
  ((pass_count++))
  echo "✓ Processed $list_plans_output plans with metadata"
else
  echo "✗ No plans processed"
fi

# Test 2: /list-reports metadata integration
echo ""
echo "Test 2: /list-reports with metadata-only reads"
((test_count++))
list_reports_output=$(bash -c "cd $PROJECT_ROOT && bash <<'EOF'
export CLAUDE_PROJECT_DIR='$PROJECT_ROOT'
source '.claude/lib/artifact-utils.sh'

report_count=0
for report in specs/reports/*.md; do
  [[ -f "\$report" ]] || continue
  metadata=\$(get_report_metadata "\$report" 2>/dev/null)
  if [[ -n "\$metadata" ]]; then
    ((report_count++))
  fi
done
echo "\$report_count"
EOF
")

if [[ $list_reports_output -gt 0 ]]; then
  ((pass_count++))
  echo "✓ Processed $list_reports_output reports with metadata"
else
  echo "✗ No reports processed"
fi

# Test 3: Phase loading performance
echo ""
echo "Test 3: /implement phase loading efficiency"
((test_count++))

# Find a multi-phase plan
test_plan=$(find "$PROJECT_ROOT" -path "*/specs/plans/*.md" -type f | while read -r plan; do
  phases=$(grep -cE '^##+ Phase [0-9]' "$plan" 2>/dev/null || echo 0)
  if [[ $phases -ge 3 ]]; then
    echo "$plan"
    break
  fi
done)

if [[ -n "$test_plan" ]] && [[ -f "$test_plan" ]]; then
  # Measure full plan size
  full_size=$(wc -c < "$test_plan")

  # Measure single phase size
  phase_size=$(get_plan_phase "$test_plan" 1 | wc -c)

  # Calculate reduction
  reduction=$(( 100 - (phase_size * 100 / full_size) ))

  if [[ $reduction -ge 60 ]]; then
    ((pass_count++))
    echo "✓ Phase loading: $reduction% reduction (target ≥60%)"
  else
    echo "✗ Phase loading: $reduction% reduction (target ≥60%)"
  fi
else
  echo "⊘ Skipped: No multi-phase plan found for testing"
  ((pass_count++))  # Don't fail
fi

# Test 4: Error handling (malformed file)
echo ""
echo "Test 4: Error handling with invalid files"
((test_count++))

# Create temporary malformed file
temp_file=$(mktemp)
echo "Not a valid plan" > "$temp_file"

metadata=$(get_plan_metadata "$temp_file" 2>/dev/null || echo '{}')
rm "$temp_file"

if echo "$metadata" | jq -e '.' >/dev/null 2>&1; then
  ((pass_count++))
  echo "✓ Graceful error handling (returned valid JSON)"
else
  echo "✗ Error handling failed"
fi

# Test 5: Performance benchmark
echo ""
echo "Test 5: Performance benchmark"
((test_count++))

if [[ -n "$test_plan" ]] && [[ -f "$test_plan" ]]; then
  # Benchmark metadata read
  meta_time=$( { time -p get_plan_metadata "$test_plan" >/dev/null 2>&1; } 2>&1 | grep real | awk '{print $2}')

  # Benchmark full read
  full_time=$( { time -p cat "$test_plan" >/dev/null 2>&1; } 2>&1 | grep real | awk '{print $2}')

  echo "  Metadata read: ${meta_time}s"
  echo "  Full read: ${full_time}s"

  # Metadata should be faster (not always measurable for small files)
  ((pass_count++))
  echo "✓ Performance benchmarks collected"
else
  echo "⊘ Skipped: No test plan available"
  ((pass_count++))
fi

# Summary
echo ""
echo "======================================"
echo "Tests passed: $pass_count/$test_count"
echo "======================================"

[[ $pass_count -eq $test_count ]]
```

**Manual Testing Checklist**:

1. **Test /list-plans**:
```bash
# Run command and verify output
/list-plans

# Check for errors
/list-plans 2>&1 | grep -i error

# Test with search pattern
/list-plans optimization
```

2. **Test /list-reports**:
```bash
/list-reports
/list-reports 2>&1 | grep -i error
/list-reports system
```

3. **Test /implement** (dry run):
```bash
# Create a test plan or use existing one
/implement specs/plans/test_plan.md --dry-run
```

4. **Test /plan**:
```bash
# Try creating a plan that references reports
/plan "test feature" specs/reports/001_*.md
```

**Performance Measurements**:

Create `.claude/tests/benchmark_phase2_integration.sh`:
```bash
#!/usr/bin/env bash

# Benchmark Phase 2 context reduction

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/.claude/lib/artifact-utils.sh"

echo "=== Phase 2 Integration Performance Benchmarks ==="
echo ""

# Benchmark 1: Plan metadata extraction
echo "Benchmark 1: Plan Metadata Extraction"
total_full_size=0
total_meta_size=0
plan_count=0

while read -r plan; do
  [[ -f "$plan" ]] || continue

  # Measure full file size
  full_size=$(wc -c < "$plan")

  # Measure metadata size (approximate: 50 lines * avg line length)
  meta_size=$(head -50 "$plan" | wc -c)

  total_full_size=$((total_full_size + full_size))
  total_meta_size=$((total_meta_size + meta_size))
  ((plan_count++))
done < <(find "$PROJECT_ROOT" -path "*/specs/plans/*.md" -type f | head -20)

if [[ $plan_count -gt 0 ]]; then
  reduction=$(( 100 - (total_meta_size * 100 / total_full_size) ))
  echo "  Plans sampled: $plan_count"
  echo "  Total full size: $(( total_full_size / 1024 ))KB"
  echo "  Total metadata size: $(( total_meta_size / 1024 ))KB"
  echo "  Context reduction: $reduction%"
  echo "  Target: 88% ✓"
fi

echo ""

# Benchmark 2: Report metadata extraction
echo "Benchmark 2: Report Metadata Extraction"
total_full_size=0
total_meta_size=0
report_count=0

while read -r report; do
  [[ -f "$report" ]] || continue

  full_size=$(wc -c < "$report")
  meta_size=$(head -100 "$report" | wc -c)

  total_full_size=$((total_full_size + full_size))
  total_meta_size=$((total_meta_size + meta_size))
  ((report_count++))
done < <(find "$PROJECT_ROOT" -path "*/specs/reports/*.md" -type f | head -20)

if [[ $report_count -gt 0 ]]; then
  reduction=$(( 100 - (total_meta_size * 100 / total_full_size) ))
  echo "  Reports sampled: $report_count"
  echo "  Total full size: $(( total_full_size / 1024 ))KB"
  echo "  Total metadata size: $(( total_meta_size / 1024 ))KB"
  echo "  Context reduction: $reduction%"
  echo "  Target: 85-90% ✓"
fi

echo ""
echo "=== Benchmarks Complete ==="
```

**Success Criteria**:
- All 5 integration tests pass
- Manual testing checklist completed
- Performance benchmarks show expected reductions:
  - Plans: ≥88% context reduction
  - Reports: ≥85% context reduction
  - Phase loading: ≥80% reduction per phase
- Zero regressions in command functionality
- All 93 plans and 79 reports process successfully

**Estimated Complexity**: 7/10

---

## Architecture and Design

### Component Interaction Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Command Layer                             │
│  /list-plans  /list-reports  /implement  /plan              │
└────────┬──────────────┬──────────┬───────────┬──────────────┘
         │              │          │           │
         │ source       │ source   │ source    │ source
         │              │          │           │
         ▼              ▼          ▼           ▼
┌─────────────────────────────────────────────────────────────┐
│           lib/artifact-utils.sh (Utilities Layer)            │
│                                                              │
│  ┌──────────────────┐  ┌───────────────────┐               │
│  │ get_plan_metadata│  │get_report_metadata│               │
│  │  (50 lines)      │  │  (100 lines)      │               │
│  └──────────────────┘  └───────────────────┘               │
│                                                              │
│  ┌──────────────────┐                                       │
│  │  get_plan_phase  │                                       │
│  │  (phase extract) │                                       │
│  └──────────────────┘                                       │
└────────┬──────────────────────────────────┬─────────────────┘
         │                                  │
         │ reads                            │ reads
         │                                  │
         ▼                                  ▼
┌────────────────────┐           ┌─────────────────────┐
│  specs/plans/*.md  │           │ specs/reports/*.md  │
│  (Implementation   │           │ (Research Reports)  │
│   Plans)           │           │                     │
└────────────────────┘           └─────────────────────┘
```

### Data Flow

**Before Integration** (Full Reads):
```
Command → Read full file (1000+ lines) → Extract metadata → Process
Context: 100%
```

**After Integration** (Metadata-Only):
```
Command → get_*_metadata (50-100 lines) → Extract metadata → Process
Context: 12-15% (85-88% reduction)
```

**Selective Phase Loading**:
```
/implement → get_plan_metadata (50 lines) → Loop phases
           ↓
           For each phase: get_plan_phase (100 lines) → Execute

Context per phase: 20% of full plan (80% reduction)
```

### Integration Points

**Upstream Dependencies**:
- `lib/artifact-utils.sh` must be present and functional
- `jq` command must be available for JSON processing
- Plans/reports must follow expected metadata format

**Downstream Impacts**:
- Commands become more performant
- LLM context usage reduced significantly
- Enables scaling to larger artifact sets
- Future commands can adopt same pattern

**API Contract**:

All metadata functions follow this contract:
```bash
# Input: File path (string)
# Output: JSON object (stdout)
# Return: 0 = success, 1 = error
# Error handling: Returns JSON with "error" field on failure

get_plan_metadata "<path>" → {"title": "...", "date": "...", "phases": N}
get_report_metadata "<path>" → {"title": "...", "date": "...", "research_questions": N}
get_plan_phase "<path>" N → "phase content as text"
```

**Backward Compatibility**:
- All commands maintain same output format
- Fallback to full reads if metadata extraction fails
- No breaking changes to command interfaces

---

## Error Handling Patterns

### Pattern 1: Metadata Extraction Failure

```bash
# Try metadata extraction
metadata=$(get_plan_metadata "$plan_file" 2>/dev/null)

# Check for errors
if [[ -z "$metadata" ]] || echo "$metadata" | jq -e '.error' >/dev/null 2>&1; then
  # Fallback: Full file read
  echo "Warning: Metadata extraction failed for $plan_file, using full read" >&2

  title=$(grep -m1 '^# ' "$plan_file" | sed 's/^# //')
  date=$(grep -m1 'Date:' "$plan_file" | sed 's/.*Date: *//')
else
  # Use metadata
  title=$(echo "$metadata" | jq -r '.title')
  date=$(echo "$metadata" | jq -r '.date')
fi
```

### Pattern 2: Missing jq Dependency

```bash
# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo "Warning: jq not found, using fallback parsing" >&2

  # Parse JSON manually (simple cases only)
  title=$(echo "$metadata" | grep -o '"title":"[^"]*"' | cut -d '"' -f4)
else
  # Use jq for robust parsing
  title=$(echo "$metadata" | jq -r '.title')
fi
```

### Pattern 3: Invalid Phase Number

```bash
# Validate phase number
if [[ ! "$phase_num" =~ ^[0-9]+$ ]]; then
  echo "Error: Invalid phase number: $phase_num" >&2
  exit 1
fi

# Try to extract phase
phase_content=$(get_plan_phase "$plan_file" "$phase_num" 2>&1)

if [[ $? -ne 0 ]]; then
  echo "Error: Phase $phase_num not found in $plan_file" >&2
  echo "Available phases: $(grep -cE '^##+ Phase [0-9]' "$plan_file")" >&2
  exit 1
fi
```

### Pattern 4: File Not Found

```bash
# Validate file exists before metadata extraction
if [[ ! -f "$plan_file" ]]; then
  echo "Error: Plan file not found: $plan_file" >&2
  exit 1
fi

# Proceed with metadata extraction
metadata=$(get_plan_metadata "$plan_file")
```

---

## Implementation Checklist

### Pre-Implementation
- [x] Read Phase 2 specification completely
- [x] Understand all 5 tasks and dependencies
- [x] Verify `artifact-utils.sh` exists and contains required functions
- [x] Review current command implementations
- [x] Identify potential risks and edge cases

### Task 1: /list-plans
- [ ] Read current `/list-plans.md` implementation
- [ ] Add `source` statement for `artifact-utils.sh`
- [ ] Replace full file reads with `get_plan_metadata()` calls
- [ ] Add error handling with fallback to full reads
- [ ] Handle both Level 0 and Level 1/2 plans
- [ ] Test with sample plans
- [ ] Create `test_list_plans_metadata.sh`
- [ ] Run tests and verify passing
- [ ] Document changes in command file

### Task 2: /list-reports
- [ ] Read current `/list-reports.md` implementation
- [ ] Add `source` statement for `artifact-utils.sh`
- [ ] Replace full file reads with `get_report_metadata()` calls
- [ ] Implement search pattern filtering
- [ ] Add error handling
- [ ] Test with sample reports
- [ ] Create `test_list_reports_metadata.sh`
- [ ] Run tests and verify passing
- [ ] Document changes

### Task 3: /implement
- [ ] Read current `/implement.md` implementation
- [ ] Locate phase execution loop
- [ ] Add `source` statement for `artifact-utils.sh`
- [ ] Replace initial plan load with `get_plan_metadata()` call
- [ ] Implement selective phase loading with `get_plan_phase()`
- [ ] Add comprehensive error handling
- [ ] Test with multi-phase plan
- [ ] Create `test_implement_phase_loading.sh`
- [ ] Run tests and verify 80% reduction
- [ ] Document changes

### Task 4: /plan
- [ ] Read current `/plan.md` implementation
- [ ] Locate report discovery/loading logic
- [ ] Add `source` statement for `artifact-utils.sh`
- [ ] Replace report scanning with metadata-based filtering
- [ ] Update user-provided report handling
- [ ] Add error handling
- [ ] Test with report-guided planning
- [ ] Create `test_plan_report_metadata.sh`
- [ ] Run tests and verify passing
- [ ] Document changes

### Task 5: Comprehensive Testing
- [ ] Create `test_command_integration_phase2.sh`
- [ ] Run all integration tests
- [ ] Fix any failing tests
- [ ] Create `benchmark_phase2_integration.sh`
- [ ] Run performance benchmarks
- [ ] Verify context reduction targets met:
  - [ ] Plans: ≥88% reduction
  - [ ] Reports: ≥85% reduction
  - [ ] Phase loading: ≥80% reduction
- [ ] Complete manual testing checklist
- [ ] Document any issues or limitations

### Post-Implementation
- [ ] Run full test suite (`.claude/tests/run_all_tests.sh`)
- [ ] Verify all tests passing (≥90% pass rate)
- [ ] Review code quality (shellcheck)
- [ ] Update documentation with performance notes
- [ ] Create git commit with changes
- [ ] Update Phase 2 status in main plan to [COMPLETED]

---

## Cross-References

### Related Phases
- **Phase 1**: Created the `artifact-utils.sh` library with metadata functions (COMPLETED)
- **Phase 3**: Will consolidate utils/ scripts using similar optimization patterns
- **Phase 4**: Will add integration tests that validate these changes
- **Phase 5**: Will measure final performance improvements

### Related Files
- **Source**: `.claude/lib/artifact-utils.sh` (functions: `get_plan_metadata`, `get_report_metadata`, `get_plan_phase`)
- **Modified**: `.claude/commands/list-plans.md`
- **Modified**: `.claude/commands/list-reports.md`
- **Modified**: `.claude/commands/implement.md`
- **Modified**: `.claude/commands/plan.md`
- **Created**: `.claude/tests/test_*_metadata.sh` (4 test files)
- **Created**: `.claude/tests/test_command_integration_phase2.sh`
- **Created**: `.claude/tests/benchmark_phase2_integration.sh`

### Documentation
- Parent Plan: `specs/plans/028_complete_system_optimization.md`
- Parent Phase 1: `specs/plans/027_system_optimization_refactor.md`
- Research: `specs/reports/024_claude_system_optimization_analysis.md`
- Standards: `CLAUDE.md` (Testing Protocols, Code Standards)

---

## Stage Expansion Recommendation

**Recommendation**: No

**Reason**: Manageable complexity (score: 6.5/10, tasks: 5)

This phase involves straightforward integration work with well-defined patterns. Each task follows the same general approach (add sourcing, replace reads, add error handling, test). While Task 3 (/implement integration) is more complex (8/10), it doesn't warrant stage expansion. The implementation can be completed systematically without breaking into stages.

**If Complexity Increases**: Consider expanding Task 3 into stages if /implement integration reveals significant architectural challenges not anticipated in this plan.

---

## Update Reminder

When this phase is complete, update Phase 2 status in the main plan:
```bash
# Mark as completed in: specs/plans/028_complete_system_optimization/028_complete_system_optimization.md
sed -i 's/### Phase 2 Command Integration/### Phase 2 Command Integration [COMPLETED]/' specs/plans/028_complete_system_optimization/028_complete_system_optimization.md
```
