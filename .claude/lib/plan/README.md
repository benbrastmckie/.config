# Plan Libraries

## Purpose

Plan parsing, management, and complexity analysis libraries. This directory provides utilities for automatic complexity analysis and expansion recommendations, checkbox manipulation for progress tracking, complexity scoring and threshold detection, template parsing, core plan structure parsing and metadata management, topic decomposition for research workflows, and topic directory naming and creation.

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

### standards-extraction.sh
Project standards extraction from CLAUDE.md for plan creation.

**Key Functions:**
- `extract_claude_section(section_name)` - Extract single named section from CLAUDE.md
- `extract_planning_standards()` - Extract all 6 planning-relevant sections
- `format_standards_for_prompt()` - Format sections for agent prompt injection
- `validate_standards_extraction()` - Test standards extraction functionality

**Planning-Relevant Sections:**
- `code_standards` - Coding conventions and patterns
- `testing_protocols` - Test discovery and coverage requirements
- `documentation_policy` - Documentation standards and formats
- `error_logging` - Error handling integration
- `clean_break_development` - Refactoring approach
- `directory_organization` - File placement rules

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh"

# Extract single section
content=$(extract_claude_section "code_standards")

# Extract all planning standards
standards=$(extract_planning_standards)

# Format for agent prompt
formatted=$(format_standards_for_prompt)
echo "$formatted"  # Returns markdown with ### headers

# Validate extraction works
validate_standards_extraction
```

**Integration Pattern:**
Used by `/plan`, `/revise`, and other planning commands to inject project standards into agent prompts. Enables automatic standards validation and divergence detection (Phase 0 protocol). See [Standards Integration Pattern](../../docs/guides/patterns/standards-integration.md) for complete usage.

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

- [← Parent Directory](../README.md)
