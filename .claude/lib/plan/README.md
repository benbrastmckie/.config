# Plan Libraries

Plan parsing, management, and complexity analysis libraries.

## Libraries

### auto-analysis-utils.sh
Automatic complexity analysis orchestration.

**Key Functions:**
- `run_auto_analysis()` - Run automatic complexity analysis
- `generate_expansion_recommendations()` - Recommend phase expansions
- `execute_auto_expansion()` - Execute automatic expansion

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/auto-analysis-utils.sh"
RECOMMENDATIONS=$(run_auto_analysis "$PLAN_FILE")
```

### checkbox-utils.sh
Plan checkbox manipulation for progress tracking.

**Key Functions:**
- `update_checkbox()` - Update checkbox state in file
- `mark_phase_complete()` - Mark phase checkbox as complete
- `add_in_progress_marker()` - Add [IN PROGRESS] marker
- `add_complete_marker()` - Add [COMPLETE] marker

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh"
mark_phase_complete "$PLAN_FILE" 3
add_in_progress_marker "$PLAN_FILE" 4
```

### complexity-utils.sh
Complexity analysis for phases and plans.

**Key Functions:**
- `calculate_phase_complexity()` - Calculate complexity score (0-10+)
- `analyze_task_structure()` - Analyze task metrics
- `detect_complexity_triggers()` - Check if thresholds exceeded
- `generate_complexity_report()` - Generate JSON report with all metrics

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/complexity-utils.sh"
SCORE=$(calculate_phase_complexity "Phase 3" "$TASK_LIST")
if detect_complexity_triggers "$SCORE" "12"; then
  echo "Expansion recommended"
fi
```

### parse-template.sh
Template file parsing for variable extraction.

**Key Functions:**
- `parse_template_file()` - Parse template YAML structure
- `extract_template_variables()` - Extract required variables
- `validate_template_structure()` - Validate template format

### plan-core-bundle.sh
Core plan parsing functions (consolidates parse-plan-core.sh, plan-structure-utils.sh, plan-metadata-utils.sh).

**Key Functions:**
- `extract_phase_name()` - Extract phase name from heading
- `extract_phase_content()` - Extract full phase content
- `parse_phase_list()` - Get list of all phases
- `detect_structure_level()` - Detect plan structure level (0/1/2)
- `is_phase_expanded()` - Check if phase is expanded
- `add_phase_metadata()` - Add expansion metadata
- `merge_phase_into_plan()` - Merge expanded phase back

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/plan-core-bundle.sh"
PHASE_CONTENT=$(extract_phase_content "$PLAN_FILE" 3)
LEVEL=$(detect_structure_level "$PLAN_PATH")
```

### topic-decomposition.sh
Topic breakdown utilities for research workflows.

**Key Functions:**
- `decompose_topic()` - Break topic into subtopics
- `prioritize_subtopics()` - Prioritize subtopics by importance

### topic-utils.sh
Topic directory management and naming.

**Key Functions:**
- `generate_topic_slug()` - Generate slug from description
- `create_topic_directory()` - Create topic directory structure
- `get_next_topic_number()` - Get next available topic number

## Dependencies

- `checkbox-utils.sh` depends on `core/base-utils.sh` and `plan-core-bundle.sh`
- `plan-core-bundle.sh` depends on `core/base-utils.sh`

## Navigation

- [Parent Directory (lib/)](../README.md)
