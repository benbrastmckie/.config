#!/usr/bin/env bash

# Phase Content Enhancement Library
# Transforms 30-50 line Level 0 phases into 80-150 line detailed Level 1 phases

# Main enhancement function
# Usage: enhance_phase_content <phase_content> <phase_num> <parent_plan>
enhance_phase_content() {
  local phase_content="$1"
  local phase_num="$2"
  local parent_plan="$3"

  # Parse phase structure
  local objective=$(echo "$phase_content" | grep "^\*\*Objective\*\*:" | sed 's/^\*\*Objective\*\*: //')
  local complexity=$(echo "$phase_content" | grep "^\*\*Complexity\*\*:" | sed 's/^\*\*Complexity\*\*: //')
  local tasks=$(echo "$phase_content" | awk '/^- \[ \]/ {print}')
  local task_count=$(echo "$tasks" | grep -c "^" || echo 0)

  # Calculate complexity score
  local complexity_score=$(calculate_enhancement_complexity "$task_count" "$complexity")

  # Build enhanced content
  cat <<EOF
$phase_content

---

## Implementation Guidance

$(expand_objective "$objective" "$tasks" "$parent_plan")

### Detailed Steps

$(generate_step_by_step_instructions "$tasks")

### Recommended Approach

1. **Planning**: Review all tasks and identify dependencies
2. **Implementation**: Work through tasks systematically, testing as you go
3. **Validation**: Verify each component works before moving to next
4. **Integration**: Ensure changes integrate cleanly with existing code

$(add_complexity_notes "$complexity" "$complexity_score")

## Edge Cases and Error Handling

$(generate_edge_case_scenarios "$tasks" "$complexity_score")

## Cross-References

$(generate_cross_references "$phase_num" "$parent_plan")

$(recommend_stage_expansion "$task_count" "$complexity_score")
EOF
}

# Calculate complexity score based on task count and complexity label
calculate_enhancement_complexity() {
  local task_count="$1"
  local complexity_label="$2"

  local base_score=0
  case "$complexity_label" in
    *Low*|*low*) base_score=3 ;;
    *Medium*|*medium*) base_score=6 ;;
    *High*|*high*) base_score=9 ;;
    *) base_score=5 ;;
  esac

  # Add task count factor (0.3 per task)
  local task_factor=$(echo "$task_count * 0.3" | bc 2>/dev/null || echo "1")
  local total=$(echo "$base_score + $task_factor" | bc 2>/dev/null || echo "$base_score")

  echo "$total"
}

# Expand objective with context
expand_objective() {
  local original_objective="$1"
  local task_list="$2"
  local parent_plan="$3"

  local themes=$(identify_task_themes "$task_list")
  local task_count=$(echo "$task_list" | grep -c "^" || echo 0)

  cat <<EOF
**Context**: $original_objective

This phase involves $task_count major tasks focusing on: $themes. The work builds on
previous phases and establishes foundation for subsequent integration.

**Success Criteria**:
- All tasks completed successfully
- Tests passing
- Code meets project standards
- Documentation updated as needed

**Critical Path**: $(generate_criticality_statement "$task_list")
EOF
}

# Identify themes from task list
identify_task_themes() {
  local tasks="$1"
  local themes=""

  echo "$tasks" | grep -qi "test" && themes="${themes}testing, "
  echo "$tasks" | grep -qi "implement\|create\|build" && themes="${themes}implementation, "
  echo "$tasks" | grep -qi "document" && themes="${themes}documentation, "
  echo "$tasks" | grep -qi "refactor\|clean\|consolidate" && themes="${themes}refactoring, "
  echo "$tasks" | grep -qi "fix\|bug" && themes="${themes}bug fixes, "

  # Remove trailing comma and space
  themes=$(echo "$themes" | sed 's/, $//')
  [[ -z "$themes" ]] && themes="general development"

  echo "$themes"
}

# Generate criticality statement
generate_criticality_statement() {
  local tasks="$1"

  if echo "$tasks" | grep -qi "test"; then
    echo "Testing ensures quality and prevents regressions"
  elif echo "$tasks" | grep -qi "implement\|create\|build"; then
    echo "Implementation forms core functionality for system"
  elif echo "$tasks" | grep -qi "refactor"; then
    echo "Refactoring improves maintainability and reduces technical debt"
  else
    echo "This work is essential for project progress"
  fi
}

# Generate step-by-step instructions
generate_step_by_step_instructions() {
  local tasks="$1"
  local step_num=1

  while IFS= read -r task; do
    [[ -z "$task" ]] && continue
    local task_desc=$(echo "$task" | sed 's/^- \[ \] //')

    cat <<EOF

#### Step $step_num: $task_desc

**Approach**:
$(generate_approach_for_task "$task_desc")

**Verification**:
- Verify changes work as expected
- Run relevant tests
- Check for edge cases

EOF
    ((step_num++))
  done <<< "$tasks"
}

# Generate approach for specific task type
generate_approach_for_task() {
  local task="$1"

  if [[ "$task" =~ [Aa]udit|[Aa]nalyze ]]; then
    echo "1. Gather all relevant files and data"
    echo "2. Create structured analysis document"
    echo "3. Categorize findings systematically"
  elif [[ "$task" =~ [Cc]reate|[Bb]uild ]]; then
    echo "1. Design component structure"
    echo "2. Implement core functionality"
    echo "3. Add error handling and validation"
  elif [[ "$task" =~ [Tt]est ]]; then
    echo "1. Write test cases covering main scenarios"
    echo "2. Add edge case tests"
    echo "3. Verify expected outcomes"
  elif [[ "$task" =~ [Rr]efactor ]]; then
    echo "1. Identify code that needs improvement"
    echo "2. Make incremental changes with tests"
    echo "3. Verify functionality unchanged"
  else
    echo "1. Review requirements and context"
    echo "2. Execute task systematically"
    echo "3. Validate results meet criteria"
  fi
}

# Add complexity-specific notes
add_complexity_notes() {
  local complexity="$1"
  local score="$2"

  cat <<EOF

### Complexity Notes

**Rated**: $complexity (Score: $score)

EOF

  if [[ "$complexity" =~ High|high ]] || (( $(echo "$score > 8" | bc -l 2>/dev/null || echo 0) )); then
    cat <<EOF
This is a complex phase. Consider:
- Breaking work into smaller increments
- Testing after each major change
- Documenting decisions and rationale
- Seeking review before finalizing
EOF
  else
    cat <<EOF
This phase has moderate complexity. Focus on:
- Clear implementation of each task
- Testing as you go
- Clean, maintainable code
EOF
  fi
}

# Generate edge case scenarios
generate_edge_case_scenarios() {
  local tasks="$1"
  local complexity_score="$2"

  cat <<EOF
Consider these potential edge cases:

1. **Input Validation**: Ensure all inputs are validated and handle invalid data gracefully
2. **Error Conditions**: What happens if operations fail partway through?
3. **State Management**: Are there any race conditions or state inconsistencies?
4. **Boundary Conditions**: Test with empty inputs, maximum values, special characters
EOF

  if (( $(echo "$complexity_score > 7" | bc -l 2>/dev/null || echo 0) )); then
    cat <<EOF
5. **Performance**: Consider performance with large datasets or many operations
6. **Concurrency**: Handle multiple concurrent operations if applicable
EOF
  fi

  echo ""
}

# Generate cross-references
generate_cross_references() {
  local phase_num="$1"
  local parent_plan="$2"

  local prev_phase=$((phase_num - 1))
  local next_phase=$((phase_num + 1))

  cat <<EOF
**Related Phases**:
- Previous: Phase $prev_phase (if exists)
- Next: Phase $next_phase (likely depends on this)

**Related Files**: Review parent plan for dependencies: \`$parent_plan\`
EOF
}

# Recommend stage expansion for very complex phases
recommend_stage_expansion() {
  local task_count="$1"
  local complexity_score="$2"

  if [[ $task_count -gt 10 ]] || (( $(echo "$complexity_score > 8" | bc -l 2>/dev/null || echo 0) )); then
    cat <<EOF

---

**⚠️ STAGE EXPANSION CANDIDATE**

This phase has high complexity (score: $complexity_score, tasks: $task_count).
Consider using \`/expand-stage\` to break this into multiple stages if implementation
proves more complex than anticipated.
EOF
  fi
}
